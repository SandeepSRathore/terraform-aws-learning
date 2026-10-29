output "instance_id" {
  value = module.instance.id
}

output "public_ip" {
  value = module.instance.public_ip
}

output "app_url" {
  value = "http://${module.instance.public_ip}:${var.app_port}"
}

output "health_url" {
  value = "http://${module.instance.public_ip}:${var.app_port}${var.health_check_path}"
}

output "artifact_s3_uri" {
  value = local.artifact_s3_uri
}

output "artifact_sha256" {
  description = "Checksum the instance verifies after downloading the JAR"
  value       = local.jar_sha256
}

output "security_group_id" {
  value = module.security_group.id
}

output "bootstrap_script" {
  description = "The rendered user_data, for reading: terraform output -raw bootstrap_script"
  value       = local.bootstrap_script
}
