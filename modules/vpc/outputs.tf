output "vpc_id" {
  value = aws_vpc.this.id
}

output "public_subnet_ids" {
  description = "List of public subnet IDs, in the same order as availability_zones"
  value       = aws_subnet.public[*].id
}

output "availability_zones" {
  value = local.azs
}
