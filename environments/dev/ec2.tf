# EC2 web server = security-group + ec2-instance, plus optional
# elastic-ip and ebs-volume modules. Notice how outputs of one module
# become inputs of the next. That wiring IS the dependency graph.

module "web_sg" {
  source = "../../modules/security-group"
  count  = var.enable_ec2 ? 1 : 0

  name        = "${var.project}-web"
  description = "Web server: HTTP from anywhere, SSH from my IP"
  vpc_id      = module.network.vpc_id

  # merge() adds the ssh rule only when ssh_cidr is set.
  ingress_rules = merge(
    {
      http = { description = "HTTP", port = 80, cidr_ipv4 = "0.0.0.0/0" }
    },
    var.ssh_cidr == null ? {} : {
      ssh = { description = "SSH from my IP", port = 22, cidr_ipv4 = var.ssh_cidr }
    }
  )
}

module "web" {
  source = "../../modules/ec2-instance"
  count  = var.enable_ec2 ? 1 : 0

  name               = "${var.project}-web"
  subnet_id          = module.network.public_subnet_ids[0]
  security_group_ids = [module.web_sg[0].id]
  key_name           = var.key_name

  user_data = templatefile("${path.module}/templates/web_user_data.sh.tftpl", {
    message = var.web_message
  })
}

module "web_eip" {
  source = "../../modules/elastic-ip"
  count  = var.enable_ec2 && var.enable_elastic_ip ? 1 : 0

  name        = "${var.project}-web"
  instance_id = module.web[0].id
}

module "web_data_volume" {
  source = "../../modules/ebs-volume"
  count  = var.enable_ec2 && var.enable_ebs ? 1 : 0

  name              = "${var.project}-web-data"
  availability_zone = module.web[0].availability_zone
  attach            = true
  instance_id       = module.web[0].id
}
