# Deploys a Spring Boot fat JAR to one EC2 instance.
#
#   your Mac                     S3                          EC2 (Amazon Linux 2023)
#   target/app.jar ──upload──▶  artifacts/<name>/app.jar ◀── user_data: install Java,
#                                                           download + verify JAR,
#                                                           run it as a systemd service
#
# This module is built from OTHER modules (ec2-instance-profile, security-group,
# ec2-instance). It only adds what is specific to running a JAR: the upload
# and the bootstrap script.
#
# Deploying a new version = build a new JAR, then `terraform apply`. The JAR's
# checksum is baked into user_data, so a new JAR means new user_data, and the
# ec2-instance module REPLACES the instance (user_data_replace_on_change).
# That is an "immutable" deploy: servers are never patched in place.

data "aws_region" "current" {}

locals {
  jar_sha256      = filesha256(var.jar_path)
  artifact_key    = "${var.artifact_prefix}/${var.name}/${basename(var.jar_path)}"
  artifact_s3_uri = "s3://${var.artifact_bucket}/${local.artifact_key}"
}

# ---- 1. Upload the JAR ----

resource "aws_s3_object" "jar" {
  bucket = var.artifact_bucket
  key    = local.artifact_key
  source = var.jar_path
  # Re-upload whenever the file's contents change.
  source_hash = local.jar_sha256

  tags = var.tags
}

# ---- 2. Permission to download it (and nothing else) ----

module "instance_profile" {
  source = "../ec2-instance-profile"

  name = var.name
  policy_statements = [{
    actions   = ["s3:GetObject"]
    resources = ["arn:aws:s3:::${var.artifact_bucket}/${local.artifact_key}"]
  }]
  tags = var.tags
}

# ---- 3. Firewall: the app port, plus SSH only if asked ----

module "security_group" {
  source = "../security-group"

  name        = "${var.name}-app"
  description = "${var.name}: app port ${var.app_port}"
  vpc_id      = var.vpc_id

  # Keyed by CIDR, not list position: see demos/count-vs-for-each.
  ingress_rules = merge(
    {
      for cidr in var.allowed_cidrs : "app ${cidr}" => {
        description = "App port from ${cidr}"
        port        = var.app_port
        cidr_ipv4   = cidr
      }
    },
    var.ssh_cidr == null ? {} : {
      ssh = { description = "SSH from my IP", port = 22, cidr_ipv4 = var.ssh_cidr }
    }
  )
  tags = var.tags
}

# ---- 4. The bootstrap script, assembled from scripts/*.sh.tftpl ----

locals {
  # Every part is rendered with the same variables, then joined in file-name
  # order (00-, 10-, 20-...). To add a step, drop a new numbered file in scripts/.
  script_parts = sort(fileset("${path.module}/scripts", "*.sh.tftpl"))

  script_vars = {
    app_name     = var.name
    app_port     = var.app_port
    java_version = var.java_version
    jvm_opts     = var.jvm_opts
    app_env      = var.app_env
    # Built from the S3 object's attributes, not the local: that reference makes
    # Terraform upload the JAR BEFORE creating the instance that downloads it.
    artifact_s3_uri      = "s3://${aws_s3_object.jar.bucket}/${aws_s3_object.jar.key}"
    artifact_sha256      = local.jar_sha256
    aws_region           = data.aws_region.current.region
    aws_endpoint_url     = var.aws_endpoint_url == null ? "" : var.aws_endpoint_url # templates can't test for null
    health_check_path    = var.health_check_path
    health_check_timeout = var.health_check_timeout
  }

  bootstrap_script = join("\n", [
    for part in local.script_parts : templatefile("${path.module}/scripts/${part}", local.script_vars)
  ])
}

# ---- 5. The server ----

module "instance" {
  source = "../ec2-instance"

  name                 = var.name
  instance_type        = var.instance_type
  ami_id               = var.ami_id
  subnet_id            = var.subnet_id
  security_group_ids   = [module.security_group.id]
  key_name             = var.key_name
  iam_instance_profile = module.instance_profile.instance_profile_name
  user_data            = local.bootstrap_script
  tags                 = var.tags
}
