# Secrets Manager = store passwords, API keys and DB credentials outside your
# code. Apps fetch them at runtime with IAM permission; values are encrypted
# with KMS, versioned, and can be rotated automatically (with a Lambda).
#
# vs SSM Parameter Store (see ../ssm-parameters): Parameter Store is cheaper
# (standard tier free) and fine for config; Secrets Manager adds built-in
# rotation, cross-region replication and a per-secret price ($0.40/month).

# Generates a strong password. NOTE: anything Terraform creates is saved in
# terraform.tfstate, so protect your state (encrypted remote backend).
# Newer alternative that keeps it out of state: `ephemeral "random_password"`
# together with secret_string_wo (Terraform 1.11+).
resource "random_password" "db" {
  length  = 24
  special = false
}

resource "aws_secretsmanager_secret" "db" {
  name        = "app/dev/db-credentials" # slashes are just naming convention
  description = "Database login for the dev app"

  # Deleting a secret normally waits 7-30 days (and blocks its name meanwhile).
  # 0 = delete immediately: convenient in dev, risky in prod.
  recovery_window_in_days = 0
}

# The secret is the container; versions hold the actual values.
resource "aws_secretsmanager_secret_version" "db" {
  secret_id = aws_secretsmanager_secret.db.id
  secret_string = jsonencode({
    username = "app_user"
    password = random_password.db.result
    host     = "db.internal"
    port     = 5432
  })
}
