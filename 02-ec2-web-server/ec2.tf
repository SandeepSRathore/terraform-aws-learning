# The virtual machine. Notice how it REFERENCES other resources
# (AMI, key pair, security group). Terraform reads those references to
# work out the order: it creates them first, then the instance.

resource "aws_instance" "web" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.ssh.key_name
  vpc_security_group_ids = [aws_security_group.web.id]

  # user_data is a script that runs once, on first boot.
  # templatefile() fills in the ${...} placeholders in the template.
  user_data = templatefile("${path.module}/templates/user_data.sh.tftpl", {
    name    = var.name
    message = var.web_message
  })

  # Changing user_data only matters on first boot, so rebuild the
  # instance when it changes instead of silently doing nothing.
  user_data_replace_on_change = true

  root_block_device {
    volume_type = "gp3"
    volume_size = 8 # GB
    encrypted   = true
  }

  # Require IMDSv2 for the instance metadata service (a security best practice).
  metadata_options {
    http_tokens = "required"
  }

  tags = {
    Name = var.name
  }

  lifecycle {
    # A newer AMI is released every few weeks. Without this, the next
    # `terraform plan` after a release would want to REPLACE the instance.
    ignore_changes = [ami]
  }
}
