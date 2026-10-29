output "dns_name" {
  value = aws_lb.web.dns_name # point a Route 53 alias record at this
}

output "target_group_arn" {
  value = aws_lb_target_group.api.arn
}
