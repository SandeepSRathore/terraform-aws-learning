output "id" {
  value = aws_instance.this.id
}

output "ami_id" {
  value = local.ami_id
}

output "availability_zone" {
  value = aws_instance.this.availability_zone
}

output "public_ip" {
  description = "Changes on every stop/start. Use the elastic-ip module for a fixed one."
  value       = aws_instance.this.public_ip
}

output "private_ip" {
  value = aws_instance.this.private_ip
}
