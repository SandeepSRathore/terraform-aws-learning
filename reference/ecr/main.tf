# ECR = a private Docker registry in your account. ECS, EKS, Lambda (container
# images) and App Runner pull images from here using IAM, with no extra passwords.
#
# Shown here: immutable tags, scan on push, and a lifecycle policy that keeps
# storage (and cost) under control by deleting old images automatically.

resource "aws_ecr_repository" "app" {
  name = "demo-app"

  # IMMUTABLE: a tag like v1.2.0 can never be overwritten, so a deploy of
  # "v1.2.0" always means the same image. (Then don't rely on "latest".)
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true # basic vulnerability scan for every pushed image
  }

  force_delete = true # dev only: lets destroy remove a repo that still has images
}

resource "aws_ecr_lifecycle_policy" "app" {
  repository = aws_ecr_repository.app.name

  # Rules are evaluated by priority (lowest first).
  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Delete untagged images after 1 day"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 1
        }
        action = { type = "expire" }
      },
      {
        rulePriority = 2
        description  = "Keep only the 10 newest release images"
        selection = {
          tagStatus      = "tagged"
          tagPatternList = ["v*"]
          countType      = "imageCountMoreThan"
          countNumber    = 10
        }
        action = { type = "expire" }
      },
    ]
  })
}
