output "instance_id" {
  value = aws_instance.web.id
}

output "ami_used" {
  description = "Which Amazon Linux image the data source found"
  value       = "${data.aws_ami.amazon_linux.name} (${data.aws_ami.amazon_linux.id})"
}

output "availability_zone" {
  value = aws_instance.web.availability_zone
}

output "public_ip" {
  value = local.public_ip
}

output "website_url" {
  description = "Open this in a browser (allow 1-2 minutes after apply for nginx to install)"
  value       = "http://${local.public_ip}"
}

output "ssh_command" {
  value = "ssh -i ${local_sensitive_file.private_key.filename} ec2-user@${local.public_ip}"
}

output "extra_volume_id" {
  description = "null unless enable_extra_volume = true"
  value       = one(aws_ebs_volume.data[*].id)
}
