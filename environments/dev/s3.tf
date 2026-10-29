# `count` works on modules too: 0 = skip the whole module.
module "assets_bucket" {
  source = "../../modules/s3-bucket"
  count  = var.enable_s3 ? 1 : 0

  bucket_prefix   = "${var.project}-assets-"
  expiration_days = 30
  force_destroy   = true # dev only: lets `destroy` remove a non-empty bucket
}
