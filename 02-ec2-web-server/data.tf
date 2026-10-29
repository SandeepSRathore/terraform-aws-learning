# DATA SOURCES read information that already exists. They create nothing.
# Syntax: data "<TYPE>" "<LOCAL_NAME>" { ... }, referenced as data.<TYPE>.<LOCAL_NAME>

# Latest Amazon Linux 2023 image, so we never hard-code an AMI ID
# (AMI IDs differ per region and change every few weeks).
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Every AWS account starts with a "default VPC" in each region.
# Using it keeps this lesson focused on EC2; we'll build our own VPC later.
data "aws_vpc" "default" {
  default = true
}

# Your current public IP, so the security group only allows SSH from you.
data "http" "my_ip" {
  url = "https://checkip.amazonaws.com"
}

# LOCALS are named values computed inside the config (like local variables).
locals {
  my_ip_cidr = "${chomp(data.http.my_ip.response_body)}/32"
}
