# Step Functions = workflows as a diagram of states (written in JSON, the
# "Amazon States Language"). AWS runs each step, retries failures, waits,
# branches, and keeps a visual history of every execution. Use it to glue
# services together instead of writing orchestration code.
#
# This workflow approves an order with NO Lambda at all:
#   Validate (Pass) -> IsBig? (Choice) -> big: Wait 1s for "review" -> Save
#                                       -> small: Save
#   Save = a direct DynamoDB PutItem call (an "SDK integration"), then Succeed.
# A negative amount goes to a Fail state.

resource "aws_dynamodb_table" "orders" {
  name         = "sfn-orders"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "order_id"

  attribute {
    name = "order_id"
    type = "S"
  }
}

# The state machine's role: what the WORKFLOW may call.
resource "aws_iam_role" "sfn" {
  name = "order-workflow"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "states.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "sfn" {
  name = "write-orders"
  role = aws_iam_role.sfn.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "dynamodb:PutItem"
      Resource = aws_dynamodb_table.orders.arn
    }]
  })
}

resource "aws_sfn_state_machine" "orders" {
  name     = "order-approval"
  role_arn = aws_iam_role.sfn.arn
  type     = "STANDARD" # STANDARD: up to 1 year, exactly-once. EXPRESS: <5 min, high volume, cheaper.

  definition = jsonencode({
    Comment = "Approve and store an order"
    StartAt = "Validate"
    States = {
      Validate = {
        Type       = "Pass"
        Parameters = { "order_id.$" = "$.order_id", "amount.$" = "$.amount", "checked" = true }
        Next       = "IsValid"
      }
      IsValid = {
        Type    = "Choice"
        Choices = [{ Variable = "$.amount", NumericLessThan = 0, Next = "Rejected" }]
        Default = "IsBig"
      }
      IsBig = {
        Type    = "Choice"
        Choices = [{ Variable = "$.amount", NumericGreaterThanEquals = 100, Next = "ManualReview" }]
        Default = "Save"
      }
      ManualReview = {
        Type    = "Wait"
        Seconds = 1 # stand-in for a human approval step (see "callback pattern")
        Next    = "Save"
      }
      Save = {
        Type     = "Task"
        Resource = "arn:aws:states:::dynamodb:putItem" # call DynamoDB directly, no Lambda
        Parameters = {
          TableName = aws_dynamodb_table.orders.name
          Item = {
            order_id = { "S.$" = "$.order_id" }
            amount   = { "N.$" = "States.Format('{}', $.amount)" }
          }
        }
        ResultPath = null # keep the input as the output, discard DynamoDB's response
        Retry      = [{ ErrorEquals = ["States.ALL"], MaxAttempts = 2, IntervalSeconds = 1, BackoffRate = 2 }]
        Next       = "Approved"
      }
      Approved = { Type = "Succeed" }
      Rejected = { Type = "Fail", Error = "InvalidAmount", Cause = "amount must not be negative" }
    }
  })
}
