# KMS = managed encryption keys. The key material never leaves AWS: you send
# data (up to 4 KB) to KMS to encrypt/decrypt it, and every use is logged in
# CloudTrail. Most services (S3, EBS, RDS, Secrets Manager, ...) encrypt with
# KMS keys behind the scenes; you pick "AWS-managed" (free) or your own key.
#
# For data larger than 4 KB, use ENVELOPE ENCRYPTION: ask KMS for a data key,
# encrypt locally with it, and store the data key only in its encrypted form.
# The exercise shows both.

resource "aws_kms_key" "app" {
  description             = "Encrypts application data"
  enable_key_rotation     = true # new key material yearly; old data still decrypts
  deletion_window_in_days = 7    # 7-30: a key can't be deleted instantly (data loss!)

  # No `policy` given, so AWS applies the default key policy: the account
  # root (and therefore IAM policies in the account) controls the key.
}

# Aliases are friendly names; code can say alias/app-data instead of a key ID,
# and you can point the alias at a new key later.
resource "aws_kms_alias" "app" {
  name          = "alias/app-data"
  target_key_id = aws_kms_key.app.key_id
}
