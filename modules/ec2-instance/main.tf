# Only look up an AMI when the caller didn't supply one.
data "aws_ami" "al2023" {
  count = var.ami_id == null ? 1 : 0

  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

locals {
  ami_id = var.ami_id != null ? var.ami_id : data.aws_ami.al2023[0].id
}

resource "aws_instance" "this" {
  ami                         = local.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = var.security_group_ids
  key_name                    = var.key_name
  associate_public_ip_address = var.associate_public_ip

  user_data = var.user_data
  # user_data only runs on first boot, so rebuild the instance when it changes.
  user_data_replace_on_change = true

  root_block_device {
    volume_type = "gp3"
    volume_size = var.root_volume_size
    encrypted   = true
  }

  # Require IMDSv2 for the instance metadata service (security best practice).
  metadata_options {
    http_tokens = "required"
  }

  tags = merge(var.tags, { Name = var.name })

  lifecycle {
    # A new AMI is published every few weeks; don't replace the instance for it.
    ignore_changes = [ami]
  }
}
