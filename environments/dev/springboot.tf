# Spring Boot JAR on EC2. Build the JAR first:
#   ./scripts/springboot/build.sh        (or: cd apps/hello-springboot && mvn package)
# then deploy everything in one go:
#   ./scripts/springboot/deploy.sh       (build + apply + smoke test)

locals {
  springboot_jar = coalesce(
    var.springboot_jar_path,
    "${path.module}/../../apps/hello-springboot/target/hello-springboot.jar"
  )
}

# Its own bucket: the assets bucket expires objects after 30 days, and a
# replacement instance must always be able to download its JAR.
module "artifacts_bucket" {
  source = "../../modules/s3-bucket"
  count  = var.enable_springboot ? 1 : 0

  bucket_prefix     = "${var.project}-artifacts-"
  enable_versioning = true # earlier builds stay recoverable
  force_destroy     = true # dev only
}

module "springboot_app" {
  source = "../../modules/springboot-ec2"
  count  = var.enable_springboot ? 1 : 0

  name            = "hello-springboot"
  jar_path        = local.springboot_jar
  artifact_bucket = module.artifacts_bucket[0].bucket_name

  vpc_id    = module.network.vpc_id
  subnet_id = module.network.public_subnet_ids[0]
  ssh_cidr  = var.ssh_cidr
  key_name  = var.key_name

  app_env = {
    APP_MESSAGE = var.springboot_message
  }

  # LocalStack runs "instances" as Docker containers built from its own
  # Amazon Linux 2023 image, and the instance must send its S3 calls back
  # to LocalStack. Against real AWS both are null: latest AL2023, real S3.
  ami_id           = var.use_localstack ? "ami-024f768332f0" : null
  aws_endpoint_url = var.use_localstack ? "http://localhost.localstack.cloud:4566" : null
}
