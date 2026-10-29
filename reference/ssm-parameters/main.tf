# SSM Parameter Store = a key-value store for configuration and secrets,
# organised as a path hierarchy (/app/dev/...). Apps read a whole path at
# startup. Standard parameters are free (up to 4 KB each).
#
# Types:
#   String       -> plain config
#   StringList   -> comma-separated values
#   SecureString -> encrypted with KMS; read with --with-decryption

locals {
  prefix = "/app/dev"
}

resource "aws_ssm_parameter" "log_level" {
  name  = "${local.prefix}/log_level"
  type  = "String"
  value = "info"
}

resource "aws_ssm_parameter" "allowed_origins" {
  name  = "${local.prefix}/allowed_origins"
  type  = "StringList"
  value = "https://example.com,https://admin.example.com"
}

resource "aws_ssm_parameter" "api_key" {
  name  = "${local.prefix}/api_key"
  type  = "SecureString" # uses the AWS-managed key alias/aws/ssm unless key_id is set
  value = "sk-demo-not-a-real-key"

  # Typical pattern: Terraform creates the parameter with a placeholder and a
  # human or pipeline sets the real value; this stops Terraform reverting it.
  lifecycle {
    ignore_changes = [value]
  }
}
