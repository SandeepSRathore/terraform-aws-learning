module "beanstalk" {
  source = "../../modules/elastic-beanstalk"
  count  = var.enable_beanstalk ? 1 : 0

  name       = "${var.project}-eb"
  vpc_id     = module.network.vpc_id
  subnet_ids = module.network.public_subnet_ids
  env_vars   = { APP_ENV = "dev" }
}
