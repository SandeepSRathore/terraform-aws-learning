output "public_ip" {
  value = aws_eip.this.public_ip
}

output "allocation_id" {
  value = aws_eip.this.allocation_id
}
