# Lesson 02: EC2 web server

Builds an Amazon Linux 2023 instance running nginx, reachable over HTTP,
with SSH open only to your IP.

## What each file does

| File | Concept |
|------|---------|
| `versions.tf` | using several providers together (aws, tls, local, http) |
| `variables.tf` | variable **validation** and on/off **feature toggles** |
| `data.tf` | **data sources** (latest AMI, default VPC, your IP) and **locals** |
| `security_group.tf` | firewall rules as separate resources |
| `key_pair.tf` | generating an SSH key, and why state can hold secrets |
| `ec2.tf` | the instance, `templatefile()`, `user_data`, `lifecycle` |
| `templates/user_data.sh.tftpl` | the boot script that installs nginx |
| `ebs.tf` | `count` as an on/off switch, availability zone dependency |
| `eip.tf` | Elastic IP, conditional expressions |
| `outputs.tf` | URL, SSH command, `one()` for optional resources |

## Cost

About $0.01/hour total if Free Tier doesn't cover it: a t3.micro, an 8 GB disk
and a public IPv4 address. Always finish with `terraform destroy`.

## Scenarios to test (in order)

Run every command from inside `02-ec2-web-server/`.

### 1. First apply: build everything
```bash
terraform init
terraform plan     # read it: count the "+" lines, see the data sources being read
terraform apply
```
Wait 1–2 minutes, then open `website_url` in your browser.

### 2. Dependency graph
```bash
terraform graph | head -40
```
Find the arrows from `aws_instance.web` to the security group and key pair.
Nobody wrote "create these first"; Terraform worked it out from the references.

### 3. SSH in
```bash
$(terraform output -raw ssh_command)
# then, on the instance:
sudo tail -20 /var/log/cloud-init-output.log   # the user_data output
exit
```

### 4. In-place update vs. replacement
- **Update in place (`~`):** run `terraform apply -var="instance_type=t3.small"`.
  AWS stops the instance, resizes it and starts it again. The instance ID stays
  the same, **but the public IP changes**. Remember this for scenario 6.
- **Replace (`-/+`):** run `terraform plan -var='web_message=Version 2'`. The
  plan says `forces replacement` because user_data changed. Apply it if you
  like and watch the instance ID change.
- **Validation:** run `terraform plan -var="instance_type=m5.large"`. It fails
  before contacting AWS.

### 5. Add a data volume
```bash
terraform apply -var="enable_extra_volume=true"
```
SSH in and run `lsblk`. A new 1 GB disk (`nvme1n1`) is there.
Applying again *without* the flag shows the volume being destroyed, because
Terraform always makes AWS match the code exactly.

### 6. Fixed public IP
```bash
terraform apply -var="enable_elastic_ip=true"
```
The `public_ip` output changes to the Elastic IP. Now stop and start the
instance from the AWS console and refresh the page: the IP stays the same.

> Tip: instead of typing `-var` every time, copy `terraform.tfvars.example` to
> `terraform.tfvars` and set the values there.

### 7. Drift: changes made outside Terraform
In the AWS console, add a tag `Owner = me` to the instance. Then run:
```bash
terraform plan
```
Terraform finds the difference and plans to remove the tag. The code is the
source of truth.

### 8. Clean up
```bash
terraform destroy
```
This also deletes the local `.pem` key file.
