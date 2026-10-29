# An Elastic IP is a public IPv4 address you keep until you release it.
# It survives instance stop/start and can be moved to a replacement instance.
# AWS bills every public IPv4 address hourly, attached or not.

resource "aws_eip" "this" {
  domain   = "vpc"
  instance = var.instance_id

  tags = merge(var.tags, { Name = var.name })
}
