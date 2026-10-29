# IAM = who can do what in your AWS account.
#   user    -> a long-lived identity for a person or legacy app (has passwords/keys)
#   group   -> a set of users sharing permissions (attach policies to groups, not users)
#   role    -> an identity with NO long-lived credentials; someone/something
#              "assumes" it and gets temporary keys (EC2, Lambda, CI, other accounts)
#   policy  -> JSON listing allowed (or denied) actions on resources
# Everything is denied unless a policy allows it, and an explicit Deny always wins.
#
# Shown here: user -> group -> managed policy, and a role the user can assume.

data "aws_caller_identity" "current" {}

# ---- permissions as a reusable managed policy ----
data "aws_iam_policy_document" "read_reports" {
  statement {
    sid       = "ListBucket"
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::company-reports"]
  }

  statement {
    sid       = "ReadObjects"
    actions   = ["s3:GetObject"]
    resources = ["arn:aws:s3:::company-reports/*"] # objects need /*, the bucket doesn't
  }
}

resource "aws_iam_policy" "read_reports" {
  name        = "read-company-reports"
  description = "Read-only access to the company-reports bucket"
  policy      = data.aws_iam_policy_document.read_reports.json
}

# ---- user -> group -> policy ----
resource "aws_iam_group" "analysts" {
  name = "analysts"
}

resource "aws_iam_group_policy_attachment" "analysts_read_reports" {
  group      = aws_iam_group.analysts.name
  policy_arn = aws_iam_policy.read_reports.arn
}

resource "aws_iam_user" "alice" {
  name          = "alice"
  force_destroy = true # also delete her access keys on destroy
}

resource "aws_iam_user_group_membership" "alice" {
  user   = aws_iam_user.alice.name
  groups = [aws_iam_group.analysts.name]
}

# Access keys end up in terraform.tfstate. In real accounts prefer SSO /
# IAM Identity Center for people, and roles for machines. Created here so the
# exercise can act as alice.
resource "aws_iam_access_key" "alice" {
  user = aws_iam_user.alice.name
}

# ---- a role alice can assume for deployments ----
# The TRUST policy says who may assume the role.
data "aws_iam_policy_document" "deployer_trust" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = [aws_iam_user.alice.arn]
    }

    # Real accounts usually also require MFA:
    # condition {
    #   test     = "Bool"
    #   variable = "aws:MultiFactorAuthPresent"
    #   values   = ["true"]
    # }
  }
}

resource "aws_iam_role" "deployer" {
  name                 = "deployer"
  assume_role_policy   = data.aws_iam_policy_document.deployer_trust.json
  max_session_duration = 3600 # temporary keys last at most 1 hour
}

# A permissions policy written inline on the role (not reusable elsewhere).
resource "aws_iam_role_policy" "deployer" {
  name = "deploy-lambdas"
  role = aws_iam_role.deployer.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["lambda:UpdateFunctionCode", "lambda:GetFunction"]
      Resource = "arn:aws:lambda:*:${data.aws_caller_identity.current.account_id}:function:*"
    }]
  })
}
