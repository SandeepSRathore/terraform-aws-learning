mock_provider "aws" {
  mock_resource "aws_iam_role" {
    defaults = {
      arn = "arn:aws:iam::123456789012:role/mock-role"
    }
  }
}

run "workflow_shape" {
  command = plan

  assert {
    condition     = jsondecode(aws_sfn_state_machine.orders.definition).StartAt == "Validate"
    error_message = "Workflow should start at Validate"
  }

  assert {
    condition     = jsondecode(aws_sfn_state_machine.orders.definition).States.Save.Resource == "arn:aws:states:::dynamodb:putItem"
    error_message = "Save should call DynamoDB directly"
  }

  assert {
    condition     = jsondecode(aws_sfn_state_machine.orders.definition).States.Rejected.Type == "Fail"
    error_message = "Invalid orders should end in a Fail state"
  }
}
