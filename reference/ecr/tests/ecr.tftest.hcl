mock_provider "aws" {}

run "immutable_scanned_with_lifecycle" {
  command = plan

  assert {
    condition     = aws_ecr_repository.app.image_tag_mutability == "IMMUTABLE"
    error_message = "Tags should be immutable"
  }

  assert {
    condition     = aws_ecr_repository.app.image_scanning_configuration[0].scan_on_push
    error_message = "Images should be scanned on push"
  }

  assert {
    condition     = length(jsondecode(aws_ecr_lifecycle_policy.app.policy).rules) == 2
    error_message = "Expected 2 lifecycle rules"
  }
}
