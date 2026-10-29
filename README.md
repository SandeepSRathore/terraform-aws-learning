# Terraform IaC for AWS: learning path

```
terraform-iac/
├── 01-first-s3-bucket/      lesson: a single flat config (start here to read)
├── 02-ec2-web-server/       lesson: a bigger flat config, one file per topic
├── modules/                 REUSABLE building blocks, one per AWS service
│   ├── vpc/                 network: VPC, public subnets, internet gateway
│   ├── s3-bucket/           encrypted, private bucket, optional versioning/expiry
│   ├── security-group/      firewall with a map of rules (for_each)
│   ├── ec2-instance/        VM with latest Amazon Linux, IMDSv2, encrypted disk
│   ├── elastic-ip/          fixed public IP
│   ├── ebs-volume/          extra disk, optionally attached to an instance
│   ├── ecs-fargate/         container cluster, task definition, service, logs
│   ├── elastic-beanstalk/   app + environment + the two IAM roles it needs
│   └── lambda-function/     zipped Python code + IAM role + log group, runs on demand
├── environments/
│   └── dev/                 ROOT module: wires the modules together, with on/off toggles
│       └── functions/       Lambda source code (upload_processor/handler.py)
├── reference/               ONE EXAMPLE PER AWS SERVICE (20), verified on LocalStack
│                            -> see reference/README.md for the list and how to use them
└── scripts/test-all.sh      runs fmt, validate and tests everywhere
```

Every module has the same shape:

| File | Holds |
|------|-------|
| `versions.tf` | required Terraform/provider versions (no provider config!) |
| `variables.tf` | the module's inputs, with validation rules |
| `main.tf` | the resources |
| `outputs.tf` | the values callers can use |
| `tests/*.tftest.hcl` | tests that run against a **mock** AWS |

## No AWS account? You can still test everything

`terraform test` with `mock_provider "aws" {}` runs plans (and fake applies)
against a pretend AWS. It needs no account and no credentials, and it costs nothing.

```bash
brew tap hashicorp/tap
brew install hashicorp/tap/terraform

./scripts/test-all.sh              # every module + environments/dev
./scripts/test-all.sh ecs-fargate  # just one module
```

To test one module by hand:

```bash
cd modules/security-group
terraform init       # downloads the AWS provider (~150 MB, once)
terraform validate   # syntax and type check
terraform test       # runs tests/*.tftest.hcl
```

What mocks can and can't tell you:

- ✅ Syntax, types, variable validation, `count`/`for_each` logic, how modules
  are wired together, which resources would be created.
- ❌ Whether AWS would actually accept it (permissions, quotas, a name already
  in use, a real AMI existing). LocalStack (below) covers part of that; the rest
  needs a real account.

## Learning exercises (no account needed)

1. **Read a test, break the code.** Change `"AES256"` in
   `modules/s3-bucket/main.tf` to something else, add an assert for it, and watch it fail.
2. **Add a validation.** Make `modules/ec2-instance` reject instance types
   that don't start with `t3.`, then add an `expect_failures` test for it.
3. **See a plan for the whole environment.** Run `terraform test -verbose` in
   `environments/dev` to print the full plan for each run.
4. **Write a new module.** For example `modules/cloudwatch-alarm`, using the same four-file
   shape plus a test.

## Real plan/apply with no account: LocalStack

[LocalStack](https://docs.localstack.cloud/) runs a pretend AWS in a Docker
container on your laptop, at `http://localhost:4566`. Unlike mocks, `apply`
really creates things (inside LocalStack) and you can use them afterwards, for
example by uploading files to the S3 bucket.

| Level | Command | Proves |
|-------|---------|--------|
| Mock tests | `./scripts/test-all.sh` | Your Terraform logic: types, toggles, wiring |
| LocalStack | `terraform apply -var use_localstack=true` | The AWS API accepts the requests and resources connect |
| Real AWS | `terraform apply` | Permissions, quotas, real networking, cost |

### 1. Install (one time, macOS)

You need [Docker Desktop](https://www.docker.com/products/docker-desktop/) running.

```bash
brew tap hashicorp/tap
brew install hashicorp/tap/terraform    # HashiCorp's tap; homebrew-core's copy is outdated
brew install localstack/tap/lstk        # the current LocalStack CLI
lstk                                    # first run only: log in, choose "AWS"
```

- Use `lstk`, not the older `localstack` CLI (`localstack/tap/localstack-cli`).
  The old CLI still installs, but it prints a notice that it no longer receives updates.
- LocalStack needs a free account. The first `lstk` run opens a login; your token
  is kept in the macOS keychain. A **Trial** license includes every service in
  this repo, ECS and Beanstalk included.

**Docker Desktop file sharing.** `lstk` mounts its data and license file from
`~/Library/Caches/lstk`. If Docker Desktop's shared folders are limited (the default
is all of `/Users`), starting fails with `mounts denied: The path .../Library/Caches/lstk/... is not
shared from the host`. Fix: **Docker Desktop → Settings → Resources → File
sharing → +** `~/Library/Caches/lstk` → **Apply & restart**. Changing `lstk`'s
`volume` setting doesn't help, because the license file path is fixed.

### 2. Start and stop LocalStack

```bash
lstk start --non-interactive   # start in the background (no prompts)
lstk status                    # is it running? which resources exist?
lstk logs --follow             # watch what LocalStack is doing
lstk stop                      # stop it (this ERASES everything inside)
curl http://localhost:4566/_localstack/health   # which services are available
```

### 3. How `environments/dev` talks to LocalStack

One variable, `use_localstack` (default `false`), switches the provider in
`environments/dev/versions.tf`. When it is `true`:

| Provider setting | Why |
|------------------|-----|
| `access_key` / `secret_key` = `"test"` | LocalStack accepts any credentials. When the switch is off they are `null`, so your normal AWS credentials are used. |
| `skip_credentials_validation`, `skip_requesting_account_id` | These checks call real AWS, which would reject the fake credentials |
| `s3_use_path_style` | Bucket names go in the URL path (`localhost:4566/<bucket>`), because `<bucket>.localhost` addresses don't resolve |
| `dynamic "endpoints"` | Sends EC2, ECS, Beanstalk, IAM, CloudWatch Logs, S3 and STS to `var.localstack_endpoint`. `dynamic` makes the block appear 0 or 1 times, like `count` for resources. |

Mock tests ignore provider settings entirely, so the switch doesn't affect them.

### 4. Plan, apply, destroy

```bash
cd environments/dev
terraform init
terraform plan    -var use_localstack=true
terraform apply   -var use_localstack=true
terraform plan    -var use_localstack=true -detailed-exitcode   # "No changes" = state matches LocalStack
terraform destroy -var use_localstack=true
```

Or `cp terraform.tfvars.example terraform.tfvars` (which sets `use_localstack = true`)
and drop the `-var`. Turn on more services with `-var enable_ecs=true` and so on.

With the defaults (S3 + EC2 on), `apply` creates **16 resources** in `us-east-1`
(the default `aws_region`), under LocalStack's fake account `000000000000`:

- **Network:** a VPC, 2 public subnets, an internet gateway, a route table and 2 route table associations
- **S3:** the assets bucket, plus its encryption, versioning, public-access-block and lifecycle settings
- **EC2:** a security group, an HTTP ingress rule, an egress rule, and the instance

`lstk status` also lists a few VPCs, subnets and security groups that Terraform
didn't create. Those are LocalStack's built-in defaults, matching the default VPC that real AWS creates in every region.

> **LocalStack forgets everything when it stops**, but `terraform.tfstate` does
> not. After a restart, either `apply` again to recreate everything, or run `destroy`
> *before* stopping LocalStack.

### 5. Use the resources: upload a file to S3

LocalStack accepts plain HTTP, so `curl` works without the AWS CLI:

```bash
cd environments/dev
B=$(terraform output -raw assets_bucket)

curl -X PUT --data-binary @hello.txt http://localhost:4566/$B/hello.txt   # upload
curl http://localhost:4566/$B/hello.txt                                   # download
curl -I http://localhost:4566/$B/hello.txt                                # metadata
curl "http://localhost:4566/$B?list-type=2"                               # list (XML)
```

The metadata shows the module's settings at work:

- `x-amz-server-side-encryption: AES256`: the module's encryption setting
  encrypted the file without being asked.
- `x-amz-version-id`: versioning is on, so re-uploading keeps old copies.

`force_destroy = true` lets `terraform destroy` remove the bucket even with files in it.

### 6. Lambda: run code when a file is uploaded

**What Lambda is.** The EC2 web server is a computer that runs all day: you pay
every hour, even when nobody visits, and you have to look after it. A Lambda
function is just code (here, one Python function). AWS keeps it switched off and
runs it only when an **event** happens, then switches it off again. You pay per
run, by the millisecond, and there is no server to patch.

**The problem it solves:** "when X happens, do Y", without keeping a server
running just to wait for X. Typical events are a file uploaded, an HTTP
request, a message on a queue, or a schedule ("every night at 2am").

**What this repo builds** (`enable_lambda = true`, requires `enable_s3`):

```
upload to uploads/notes.txt
        │  S3 bucket notification (only for the uploads/ prefix)
        ▼
Lambda tf-learning-upload-processor   (environments/dev/functions/upload_processor/handler.py)
        │  counts lines/words/characters
        ▼
writes processed/notes.txt.json       print() output → CloudWatch log /aws/lambda/<name>
```

| Piece | File | Role |
|-------|------|------|
| `archive_file` | `modules/lambda-function/main.tf` | Zips the code at plan time into `.build/` (git-ignored). Lambda only accepts a zip. |
| `source_code_hash` | same | Changes whenever the code changes, so editing `handler.py` and running `apply` redeploys it |
| IAM role + `policy_statements` | same, plus `environments/dev/lambda.tf` | What the **code** may do: write logs, read `uploads/*`, write `processed/*`, nothing else |
| `aws_lambda_permission` | `environments/dev/lambda.tf` | Who may **invoke** the function: only S3, only for this bucket |
| `aws_s3_bucket_notification` | same | When to invoke it: `s3:ObjectCreated:*` under `uploads/` |
| `aws_cloudwatch_log_group` | `modules/lambda-function/main.tf` | Created by Terraform so it expires after 7 days and is deleted on `destroy` |

> **The classic Lambda trap: an endless loop.** If the function wrote its report
> back into `uploads/`, that upload would trigger it again, forever, and on real
> AWS the bill grows with every run. Two things prevent it here: reports go
> to a *different* prefix, and the IAM policy doesn't even allow writing to `uploads/`.

Try it on LocalStack:

```bash
cd environments/dev
terraform apply -var use_localstack=true -var enable_lambda=true

B=$(terraform output -raw assets_bucket)
curl -X PUT --data-binary @notes.txt http://localhost:4566/$B/uploads/notes.txt
sleep 3
curl http://localhost:4566/$B/processed/notes.txt.json

# The function's log (print() output plus a REPORT line with duration and memory)
curl -s http://localhost:4566/ -H 'Content-Type: application/x-amz-json-1.1' \
  -H 'X-Amz-Target: Logs_20140328.FilterLogEvents' \
  -H 'Authorization: AWS4-HMAC-SHA256 Credential=test/20261029/us-east-1/logs/aws4_request, SignedHeaders=host, Signature=x' \
  -d '{"logGroupName":"/aws/lambda/tf-learning-upload-processor"}'
```

Expected report:

```json
{ "source": "s3://<bucket>/uploads/notes.txt", "lines": 3, "words": 14, "characters": 82 }
```

and a log line like `REPORT ... Duration: 58.57 ms  Billed Duration: 59 ms ... Init Duration: 868.34 ms`.
**Init Duration** is the *cold start*: the first run sets up the runtime. Later
runs reuse the warm container and skip it. A file uploaded anywhere else,
such as `other/x.txt`, doesn't trigger the function.

On LocalStack, the first `apply` takes about a minute because it downloads the Python
runtime image (a few hundred MB). On real AWS, Lambda's free tier covers 1 million runs a month.

### Troubleshooting

| Symptom | Cause / fix |
|---------|-------------|
| `connect: connection refused` on `localhost:4566` | LocalStack isn't running: `lstk start --non-interactive` |
| `mounts denied ... Library/Caches/lstk` | Add the folder to Docker Desktop file sharing (step 1) |
| `Docker Desktop VM stopped unexpectedly: ... The storage device attachment is invalid` after changing Docker settings | Docker's automatic restart started the new VM before the old one released its disk file (`Docker.raw`). Quit Docker Desktop fully, then start it again (`open -a Docker`). |
| `Error: login requires an interactive terminal` | Run `lstk` once in your own terminal to log in |
| Each project folder's `.terraform/` is ~700 MB | No shared plugin cache. Add `plugin_cache_dir = "$HOME/.terraform.d/plugin-cache"` to `~/.terraformrc`, delete the `.terraform/` folders, and run `terraform init` again |
| `lstk` warns "AWS profile is incomplete" | Optional: `lstk setup aws` creates an AWS CLI profile for LocalStack |
| A service fails to create | Your LocalStack plan may not include it; switch that `enable_*` toggle off |
| Upload succeeds but no report appears in `processed/` | Check the function's log (section 6): a Python error shows up there. Also check the file went to `uploads/` exactly (prefixes are case-sensitive). |

### LocalStack vs real AWS

The Terraform code is identical; only `use_localstack` changes. But LocalStack
is more lenient:

| | LocalStack | Real AWS |
|---|---|---|
| Unsigned `curl` to S3 | Works | **403**: requests must be signed (AWS CLI/SDK), and the bucket blocks public access |
| Credentials and permissions | Anything works; permissions aren't checked | Real keys, and every action needs permission |
| EC2 instance | A record only; `web_url` doesn't respond | A real VM boots, runs `user_data` and serves the page |
| Speed | Seconds | EC2 takes about a minute, ECS a few minutes, Beanstalk 5–10 minutes |
| New IAM roles | Usable instantly | Can take seconds to become usable, so a first apply may fail; retry |
| Validation and quotas | Often lenient | Strict (instance types per AZ, quotas, unique bucket names) |
| Lifetime | Erased on stop | Runs, and **costs money**, until you `destroy` |

Things that work on LocalStack usually work on AWS. Permissions and IAM timing
are what most often break when you switch.

## If you later get an AWS account

```bash
cd environments/dev
cp terraform.tfvars.example terraform.tfvars   # set use_localstack = false, pick services
aws configure
terraform init && terraform plan && terraform apply
terraform destroy                               # always clean up
```

Rough cost when running: EC2/EIP are about $0.01/hr; ECS Fargate (0.25 vCPU) is about $0.012/hr;
Beanstalk is about the cost of its t3.micro instance.
