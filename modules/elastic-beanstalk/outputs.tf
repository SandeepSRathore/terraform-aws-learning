output "application_name" {
  value = aws_elastic_beanstalk_application.this.name
}

output "environment_name" {
  value = aws_elastic_beanstalk_environment.this.name
}

output "platform" {
  description = "The solution stack the regex resolved to"
  value       = data.aws_elastic_beanstalk_solution_stack.this.name
}

output "url" {
  value = "http://${aws_elastic_beanstalk_environment.this.cname}"
}
