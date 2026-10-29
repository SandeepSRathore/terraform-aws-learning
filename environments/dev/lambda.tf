# Event-driven Lambda: upload a file to uploads/ in the assets bucket and S3
# runs the function, which writes a report to processed/.
#
#   S3 upload --(bucket notification)--> Lambda --(boto3)--> processed/*.json
#
# Three pieces connect them: the function (module), permission for S3 to
# invoke it, and the bucket notification that says WHEN to invoke it.

locals {
  upload_prefix = "uploads/"
  report_prefix = "processed/"
}

module "upload_processor" {
  source = "../../modules/lambda-function"
  count  = var.enable_lambda && var.enable_s3 ? 1 : 0

  name       = "${var.project}-upload-processor"
  source_dir = "${path.module}/functions/upload_processor"

  environment = {
    INPUT_PREFIX  = local.upload_prefix
    OUTPUT_PREFIX = local.report_prefix
  }

  # Least privilege: read only uploads/, write only processed/.
  policy_statements = [
    {
      actions   = ["s3:GetObject"]
      resources = ["${module.assets_bucket[0].bucket_arn}/${local.upload_prefix}*"]
    },
    {
      actions   = ["s3:PutObject"]
      resources = ["${module.assets_bucket[0].bucket_arn}/${local.report_prefix}*"]
    },
  ]
}

# The function's IAM role says what the CODE may do. This is the reverse:
# who may INVOKE the function. Here, only S3, and only for this bucket.
resource "aws_lambda_permission" "s3_invoke" {
  count = length(module.upload_processor)

  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = module.upload_processor[0].function_name
  principal     = "s3.amazonaws.com"
  source_arn    = module.assets_bucket[0].bucket_arn
}

# A bucket has exactly ONE notification config, so it lives here next to the
# function instead of inside the reusable s3-bucket module.
resource "aws_s3_bucket_notification" "uploads" {
  count = length(module.upload_processor)

  bucket = module.assets_bucket[0].bucket_name

  lambda_function {
    lambda_function_arn = module.upload_processor[0].function_arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = local.upload_prefix
  }

  # S3 checks it is allowed to invoke the function when the notification is saved.
  depends_on = [aws_lambda_permission.s3_invoke]
}
