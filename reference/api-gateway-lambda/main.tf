# API Gateway (HTTP API) + Lambda = a serverless REST API. API Gateway gives
# you an HTTPS URL, routing, throttling, CORS and auth; each request invokes
# a Lambda, and you pay per request with nothing running in between.
#
#   route        -> "METHOD /path" (GET /hello, POST /items, $default)
#   integration  -> what a route calls (here: the Lambda, "proxy" style:
#                   the whole HTTP request goes in, the Lambda returns the response)
#   stage        -> a deployed version of the API ($default = served at the root)
#
# HTTP API (apigatewayv2) is the newer, cheaper, simpler flavour. The older
# REST API (aws_api_gateway_*) adds API keys/usage plans and request validation.

# Code inline, so the example stays in one folder. Bigger functions use
# source_dir (see modules/lambda-function).
data "archive_file" "api" {
  type        = "zip"
  output_path = "${path.module}/.build/api.zip"

  source {
    filename = "handler.py"
    content  = <<-PY
      import json

      def handler(event, context):
          # HTTP API "payload format 2.0": method and path live in requestContext.http
          http = event["requestContext"]["http"]
          if http["method"] == "POST":
              item = json.loads(event.get("body") or "{}")
              return {"statusCode": 201, "body": json.dumps({"created": item})}
          name = (event.get("queryStringParameters") or {}).get("name", "world")
          return {
              "statusCode": 200,
              "headers": {"content-type": "application/json"},
              "body": json.dumps({"message": f"hello {name}", "path": http["path"]}),
          }
    PY
  }
}

resource "aws_iam_role" "api" {
  name = "api-handler"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "api_logs" {
  role       = aws_iam_role.api.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "api" {
  function_name    = "api-handler"
  role             = aws_iam_role.api.arn
  runtime          = "python3.13"
  handler          = "handler.handler"
  filename         = data.archive_file.api.output_path
  source_code_hash = data.archive_file.api.output_base64sha256
}

# ---- the API ----
resource "aws_apigatewayv2_api" "http" {
  name          = "items-api"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = ["https://example.com"]
    allow_methods = ["GET", "POST"]
  }
}

resource "aws_apigatewayv2_integration" "lambda" {
  api_id                 = aws_apigatewayv2_api.http.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.api.invoke_arn
  payload_format_version = "2.0"
}

# One route per endpoint; both go to the same Lambda here.
resource "aws_apigatewayv2_route" "routes" {
  for_each = toset(["GET /hello", "POST /items"])

  api_id    = aws_apigatewayv2_api.http.id
  route_key = each.value
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.http.id
  name        = "$default"
  auto_deploy = true # every route change goes live without a manual deployment

  default_route_settings {
    throttling_rate_limit  = 50  # requests per second
    throttling_burst_limit = 100 # short bursts above the rate
  }
}

# Lets API Gateway (only this API) invoke the function.
resource "aws_lambda_permission" "api" {
  statement_id  = "AllowAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.api.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http.execution_arn}/*/*"
}
