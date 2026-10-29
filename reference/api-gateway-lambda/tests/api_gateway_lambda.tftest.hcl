mock_provider "aws" {
  mock_resource "aws_iam_role" {
    defaults = {
      arn = "arn:aws:iam::123456789012:role/mock-role"
    }
  }
}

run "routes_and_proxy_integration" {
  command = plan

  assert {
    condition     = toset(keys(aws_apigatewayv2_route.routes)) == toset(["GET /hello", "POST /items"])
    error_message = "Expected GET /hello and POST /items routes"
  }

  assert {
    condition     = aws_apigatewayv2_integration.lambda.integration_type == "AWS_PROXY" && aws_apigatewayv2_integration.lambda.payload_format_version == "2.0"
    error_message = "Lambda should be a 2.0 proxy integration"
  }

  assert {
    condition     = aws_apigatewayv2_stage.default.auto_deploy
    error_message = "The default stage should auto-deploy"
  }
}
