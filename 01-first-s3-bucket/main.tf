# A resource block = one piece of infrastructure Terraform will manage.
# Syntax: resource "<TYPE>" "<LOCAL_NAME>" { ... }
#   TYPE       -> what to create (aws_s3_bucket)
#   LOCAL_NAME -> how YOU refer to it inside Terraform (aws_s3_bucket.learning)

resource "aws_s3_bucket" "learning" {
  # S3 bucket names must be globally unique across all AWS accounts,
  # so we give a prefix and let AWS add a random suffix.
  bucket_prefix = var.bucket_prefix

  # Lets `terraform destroy` delete the bucket even if it still has files.
  # Handy while learning; usually false in real projects.
  force_destroy = true

  tags = {
    Name   = "My first Terraform bucket"
    Lesson = "01"
  }
}
