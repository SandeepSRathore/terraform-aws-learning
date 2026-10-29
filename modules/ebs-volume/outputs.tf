output "volume_id" {
  value = aws_ebs_volume.this.id
}

output "attached" {
  value = var.attach
}
