# Scenario 5: an extra EBS data volume, created only when enabled.
#
# `count` decides how many copies of a resource to create.
# count = 0 means "don't create it", which makes it an on/off switch.
# Resources with count are referenced by index: aws_ebs_volume.data[0]

resource "aws_ebs_volume" "data" {
  count = var.enable_extra_volume ? 1 : 0

  # A volume can only attach to an instance in the SAME availability zone.
  availability_zone = aws_instance.web.availability_zone
  size              = 1 # GB, the smallest allowed
  type              = "gp3"
  encrypted         = true

  tags = {
    Name = "${var.name}-data"
  }
}

resource "aws_volume_attachment" "data" {
  count = var.enable_extra_volume ? 1 : 0

  device_name = "/dev/sdf" # shows up inside Linux as /dev/nvme1n1
  volume_id   = aws_ebs_volume.data[0].id
  instance_id = aws_instance.web.id
}
