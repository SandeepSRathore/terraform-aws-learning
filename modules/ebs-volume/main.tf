# An EBS volume is a network disk. It lives in ONE availability zone and
# exists independently of any instance (it survives instance termination).

resource "aws_ebs_volume" "this" {
  availability_zone = var.availability_zone
  size              = var.size
  type              = var.type
  encrypted         = true

  tags = merge(var.tags, { Name = var.name })
}

resource "aws_volume_attachment" "this" {
  count = var.attach ? 1 : 0

  device_name = var.device_name
  volume_id   = aws_ebs_volume.this.id
  instance_id = var.instance_id

  lifecycle {
    precondition {
      condition     = var.instance_id != null
      error_message = "attach = true requires instance_id."
    }
  }
}
