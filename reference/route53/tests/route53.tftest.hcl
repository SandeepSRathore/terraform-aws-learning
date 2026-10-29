mock_provider "aws" {}

run "records_and_weights" {
  command = plan

  assert {
    condition     = aws_route53_record.api["v1"].weighted_routing_policy[0].weight + aws_route53_record.api["v2"].weighted_routing_policy[0].weight == 100
    error_message = "Weights should add up to 100 for easy percentages"
  }

  assert {
    condition     = aws_route53_record.blog.type == "CNAME" && aws_route53_record.www.type == "A"
    error_message = "Expected an A record and a CNAME"
  }
}
