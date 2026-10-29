# Scenario 6: Elastic IP, a public IP that stays the same across
# stop/start and even if the instance is replaced.
# (A normal public IP changes every time the instance stops.)

resource "aws_eip" "web" {
  count = var.enable_elastic_ip ? 1 : 0

  domain   = "vpc"
  instance = aws_instance.web.id

  tags = {
    Name = "${var.name}-eip"
  }
}

locals {
  # Use the Elastic IP when it exists, otherwise the instance's own public IP.
  public_ip = var.enable_elastic_ip ? aws_eip.web[0].public_ip : aws_instance.web.public_ip
}
