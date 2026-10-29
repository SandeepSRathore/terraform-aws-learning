output "repository_url" {
  value = aws_ecr_repository.app.repository_url # what `docker push` targets
}

output "repository_name" {
  value = aws_ecr_repository.app.name
}
