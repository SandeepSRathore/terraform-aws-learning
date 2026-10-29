# A security group is a virtual firewall around the instance.
# Everything inbound is blocked unless a rule allows it.

resource "aws_security_group" "web" {
  name        = "${var.name}-sg"
  description = "Allow HTTP from anywhere and SSH from my IP"
  vpc_id      = data.aws_vpc.default.id

  tags = {
    Name = "${var.name}-sg"
  }
}

# Each rule is its own resource, so adding or removing one rule
# never touches the others.

resource "aws_vpc_security_group_ingress_rule" "http" {
  security_group_id = aws_security_group.web.id
  description       = "HTTP from anywhere"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "ssh" {
  security_group_id = aws_security_group.web.id
  description       = "SSH from my IP only"
  cidr_ipv4         = local.my_ip_cidr
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
}

# Outbound: allow everything (needed so the instance can download packages).
resource "aws_vpc_security_group_egress_rule" "all" {
  security_group_id = aws_security_group.web.id
  description       = "All outbound traffic"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # -1 means all protocols
}
