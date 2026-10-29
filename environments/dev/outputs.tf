# one() turns a 0-or-1 element list into the element or null,
# so outputs of disabled modules simply show as null.

output "vpc_id" {
  value = module.network.vpc_id
}

output "assets_bucket" {
  value = one(module.assets_bucket[*].bucket_name)
}

output "web_url" {
  description = "Uses the Elastic IP when enabled, otherwise the instance's own IP"
  value = var.enable_ec2 ? "http://${
    var.enable_elastic_ip ? module.web_eip[0].public_ip : module.web[0].public_ip
  }" : null
}

output "web_data_volume_id" {
  value = one(module.web_data_volume[*].volume_id)
}

output "ecs_cluster" {
  value = one(module.app[*].cluster_name)
}

output "ecs_log_group" {
  value = one(module.app[*].log_group_name)
}

output "upload_processor_function" {
  value = one(module.upload_processor[*].function_name)
}

output "upload_processor_logs" {
  value = one(module.upload_processor[*].log_group_name)
}

output "beanstalk_url" {
  value = one(module.beanstalk[*].url)
}
