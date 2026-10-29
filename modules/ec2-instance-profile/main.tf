# Gives an EC2 instance an IAM role, so code on the instance can call AWS
# APIs WITHOUT access keys. The AWS CLI and SDKs fetch short-lived
# credentials for the role from the instance metadata service automatically.
#
#   role (trust: ec2.amazonaws.com) ─┬─ inline policy (your statements)
#                                    └─ AmazonSSMManagedInstanceCore (optional)
#   instance profile ── wraps the role; THIS is what the instance references

resource "aws_iam_role" "this" {
  name = "${var.name}-ec2"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "this" {
  count = length(var.policy_statements) > 0 ? 1 : 0

  name = "app"
  role = aws_iam_role.this.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [for s in var.policy_statements : {
      Effect   = "Allow"
      Action   = s.actions
      Resource = s.resources
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm" {
  count = var.enable_ssm ? 1 : 0

  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "this" {
  name = "${var.name}-ec2"
  role = aws_iam_role.this.name

  tags = var.tags
}
