# AWS service reference examples

One small, self-contained Terraform example per AWS service: copy the folder
(or the bits you need) when a task calls for that service. Each example was
**applied, exercised and destroyed on LocalStack 2026.10.4 on 2026-10-29**, and
the real output is saved next to it.

Every folder has the same shape:

| File | Holds |
|------|-------|
| `main.tf` | The resources. The header comment explains the service, when to use it, and the key concepts. |
| `outputs.tf` | Values the exercise script (or your app) needs |
| `providers.tf` | Identical in every folder (a copy of `_template/providers.tf`): AWS provider + the `use_localstack` switch |
| `exercise.sh` | AWS CLI commands that *use* the resources: the same commands work on real AWS |
| `exercise-output.txt` | What `exercise.sh` printed on LocalStack: proof that it works, and what to expect |
| `tests/*.tftest.hcl` | A mock-provider test: runs anywhere, no LocalStack or AWS needed |

## The examples

| Service | Folder | What it demonstrates |
|---------|--------|----------------------|
| **SQS** | [`sqs`](sqs/) | Queue, dead-letter queue after 3 failed receives, FIFO ordering |
| **SNS** | [`sns`](sns/) | Topic fan-out to 2 SQS queues, a filter policy on message attributes |
| **DynamoDB** | [`dynamodb`](dynamodb/) | pk/sk single-table design, GSI, TTL, conditional writes (optimistic locking) |
| **Kinesis** | [`kinesis`](kinesis/) | Stream with an ordered shard; two readers replay the same records |
| **EventBridge** | [`eventbridge`](eventbridge/) | Custom bus, content-based rule to SQS, `input_path`, cron schedule, `test-event-pattern` |
| **KMS** | [`kms`](kms/) | Rotating key + alias; direct encrypt/decrypt; envelope encryption with a data key |
| **Secrets Manager** | [`secrets-manager`](secrets-manager/) | JSON DB credentials, generated password, manual rotation, AWSCURRENT/AWSPREVIOUS |
| **SSM Parameter Store** | [`ssm-parameters`](ssm-parameters/) | `/app/dev/*` hierarchy, String/StringList/SecureString, read by path, history |
| **IAM** | [`iam`](iam/) | User → group → managed policy; assumable role; policy simulator; `sts assume-role` |
| **Cognito** | [`cognito`](cognito/) | User pool with email sign-in and a password policy, app client, login, JWT claims |
| **API Gateway + Lambda** | [`api-gateway-lambda`](api-gateway-lambda/) | HTTP API, GET/POST routes, Lambda proxy integration, throttling, CORS |
| **Step Functions** | [`step-functions`](step-functions/) | Pass/Choice/Wait/Fail states, retry, direct DynamoDB integration (no Lambda) |
| **ECR** | [`ecr`](ecr/) | Repository with immutable tags, scan on push, lifecycle rules; `docker push` |
| **ALB** | [`alb`](alb/) | Load balancer in the default VPC, listener rules, fixed responses, target group + health check |
| **CloudWatch** | [`cloudwatch`](cloudwatch/) | Log group, metric filter, alarm → SNS, dashboard, custom metrics |
| **Route 53** | [`route53`](route53/) | Hosted zone, A/CNAME/TXT records, weighted (canary) routing, alias example |
| **ACM** | [`acm`](acm/) | Certificate with DNS validation in Route 53, waiting until ISSUED |
| **CloudFront** | [`cloudfront`](cloudfront/) | Private S3 bucket behind a CDN with OAC, HTTPS redirect, SPA error page, invalidation |
| **RDS (Postgres)** | [`rds-postgres`](rds-postgres/) | Instance, subnet/parameter group, password managed in Secrets Manager, SQL via psql, snapshots |
| **ElastiCache (Redis)** | [`elasticache-redis`](elasticache-redis/) | Replication group; cache with TTL, counters, sorted-set leaderboard via redis-cli |

Related, elsewhere in this repo: S3, VPC, EC2, EBS, Elastic IP, ECS Fargate,
Elastic Beanstalk and Lambda live in [`../modules`](../modules/), wired together in
[`../environments/dev`](../environments/dev/).

## Using an example

```bash
# Against LocalStack: apply, exercise, destroy (and refresh exercise-output.txt)
./reference/verify.sh sqs
./reference/verify.sh sqs --keep     # leave the resources running to explore

# By hand: the same steps
source reference/localstack.env      # AWS CLI + Terraform -> LocalStack, for this shell
cd reference/sqs
terraform init && terraform apply
./exercise.sh
terraform destroy

# Without LocalStack or AWS: mock tests only
./scripts/test-all.sh sqs

# Against real AWS (costs money!): a fresh shell WITHOUT localstack.env
aws configure                        # or SSO / environment credentials
cd reference/sqs && terraform init && terraform apply && ./exercise.sh && terraform destroy
```

`rds-postgres` and `elasticache-redis` connect with `docker run postgres:17-alpine psql`
and `docker run redis:8-alpine redis-cli`, so Docker must be running. `ecr` pushes `alpine:3.20`.

## LocalStack vs real AWS: differences found while verifying

| Example | On LocalStack | On real AWS |
|---------|---------------|-------------|
| `ecr` | Accepted a second push to an **immutable** tag | Rejects it: `tag invalid: ... cannot be overwritten because the repository is immutable` |
| `route53` | `test-dns-answer` not implemented, and its DNS server isn't reachable from the Mac | Works; after delegating the domain, `dig` answers publicly |
| `ssm-parameters` | "Ciphertext" of a SecureString is `kms:<key>:<plaintext>` | Opaque base64 ciphertext |
| `rds-postgres` | The RDS-managed master secret (`rds-demo-postgres-...`) is left behind after destroy; delete it with `aws secretsmanager delete-secret --force-delete-without-recovery` | Deleted together with the instance |
| `kms` | After destroy the key sits in `PendingDeletion` for the 7-day window | Same, deliberately: a deleted key makes its data unreadable forever |
| `elasticache-redis`, `rds-postgres` | Endpoints are remapped to port 4510+ on `localhost.localstack.cloud` | The configured port (6379 / 5432), reachable only inside the VPC |
| `alb`, `cloudfront`, `api-gateway-lambda` | Served on `<name>.localhost.localstack.cloud:4566` over HTTP | Their own DNS names, port 80/443 |
| everything | IAM permissions aren't enforced; requests succeed whatever the policy says | Every call is checked against IAM, so the policies in these examples matter |

## Terraform gotchas found while writing these

- **DynamoDB** (provider 6.x): index keys use `key_schema { attribute_name, key_type = "HASH" | "RANGE" }`;
  `hash_key`/`range_key` *inside* a `global_secondary_index` are deprecated.
- **ElastiCache**: `at_rest_encryption_enabled` is a **string** in state (`"true"`), so
  `== true` in a test or condition is always false.
- **ACM**: key the validation records' `for_each` by `domain_name` (known at plan time),
  not by `resource_record_name` (only known after the certificate exists), and set
  `allow_overwrite = true` because the apex and the wildcard share one record.
- **Mock tests**: computed attributes are unknown during plan. Use `command = apply`,
  `mock_resource ... defaults`, or `override_during = plan` (Terraform 1.11+) when an
  assertion or a `for_each` needs them.
- **Disk space**: the AWS provider is ~700 MB *per folder* unless you configure a
  shared cache. `~/.terraformrc` on this Mac has `plugin_cache_dir = "$HOME/.terraform.d/plugin-cache"`.

## Not covered (yet)

EKS and OpenSearch were skipped: each starts a ~1 GB cluster container and the
disk was nearly full. Also good next candidates: SES, Athena + Glue, Auto Scaling
groups, WAF, EventBridge Scheduler, AppSync.
