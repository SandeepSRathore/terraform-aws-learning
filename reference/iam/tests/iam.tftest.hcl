mock_provider "aws" {
  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "123456789012"
    }
  }

  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }

  mock_resource "aws_iam_policy" {
    defaults = {
      arn = "arn:aws:iam::123456789012:policy/mock"
    }
  }

  mock_resource "aws_iam_user" {
    defaults = {
      arn = "arn:aws:iam::123456789012:user/alice"
    }
  }
}

run "user_group_role" {
  command = apply

  assert {
    condition     = contains(aws_iam_user_group_membership.alice.groups, "analysts")
    error_message = "alice should be in the analysts group"
  }

  assert {
    condition     = jsondecode(aws_iam_role_policy.deployer.policy).Statement[0].Resource == "arn:aws:lambda:*:123456789012:function:*"
    error_message = "Deployer permissions should be scoped to this account's functions"
  }
}
