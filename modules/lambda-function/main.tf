# Lambda building blocks:
#   zip of the code  -> what actually gets uploaded
#   IAM role         -> what the code is ALLOWED to do while it runs
#   log group        -> where print() output ends up (CloudWatch Logs)
#   function         -> code + runtime + limits; runs only when invoked
# There is no server: AWS starts the code on demand and bills per run.

# Runs at plan time and writes the zip under .build/ (git-ignored).
data "archive_file" "this" {
  type        = "zip"
  source_dir  = var.source_dir
  output_path = "${path.root}/.build/${var.name}.zip"
}

# Same pattern as the ECS execution role: the trust policy says WHO may use
# the role (the Lambda service); attached policies say WHAT it may do.
resource "aws_iam_role" "this" {
  name = "${var.name}-lambda"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = var.tags
}

# AWS-managed policy: permission to write logs, nothing else.
resource "aws_iam_role_policy_attachment" "logs" {
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Only created when the caller asks for extra permissions.
resource "aws_iam_role_policy" "extra" {
  count = length(var.policy_statements) > 0 ? 1 : 0

  name = "extra"
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

# Lambda would create this on first run anyway, but then it never expires
# and Terraform wouldn't delete it on destroy.
resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/lambda/${var.name}"
  retention_in_days = var.log_retention_days

  tags = var.tags
}

resource "aws_lambda_function" "this" {
  function_name = var.name
  role          = aws_iam_role.this.arn
  handler       = var.handler
  runtime       = var.runtime
  timeout       = var.timeout
  memory_size   = var.memory_size

  filename = data.archive_file.this.output_path
  # Changes whenever a file in source_dir changes, which triggers a redeploy.
  source_code_hash = data.archive_file.this.output_base64sha256

  # dynamic: an environment block with no variables is an API error.
  dynamic "environment" {
    for_each = length(var.environment) > 0 ? [var.environment] : []
    content {
      variables = environment.value
    }
  }

  tags = var.tags

  # Create the log group first (so Lambda doesn't), and on destroy keep the
  # log permission until the function is gone.
  depends_on = [aws_cloudwatch_log_group.this, aws_iam_role_policy_attachment.logs]
}
