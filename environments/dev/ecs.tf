# ECS Fargate: the SAME security-group module, reused with different inputs.
# That reuse is the whole point of modules.

module "app_sg" {
  source = "../../modules/security-group"
  count  = var.enable_ecs ? 1 : 0

  name        = "${var.project}-app"
  description = "ECS tasks: HTTP from anywhere"
  vpc_id      = module.network.vpc_id

  ingress_rules = {
    http = { description = "HTTP", port = 80, cidr_ipv4 = "0.0.0.0/0" }
  }
}

module "app" {
  source = "../../modules/ecs-fargate"
  count  = var.enable_ecs ? 1 : 0

  name               = "${var.project}-app"
  subnet_ids         = module.network.public_subnet_ids
  security_group_ids = [module.app_sg[0].id]
  environment        = { APP_ENV = "dev" }
}
