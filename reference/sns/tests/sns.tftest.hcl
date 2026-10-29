mock_provider "aws" {
  mock_resource "aws_sqs_queue" {
    defaults = {
      arn = "arn:aws:sqs:us-east-1:123456789012:mock-queue"
    }
  }

  mock_resource "aws_sns_topic" {
    defaults = {
      arn = "arn:aws:sns:us-east-1:123456789012:mock-topic"
    }
  }

  # Mocked data sources return random strings; give the policy valid JSON.
  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }
}

run "fan_out_with_filter" {
  command = apply

  assert {
    condition     = aws_sns_topic_subscription.all_orders.protocol == "sqs" && aws_sns_topic_subscription.big_orders.protocol == "sqs"
    error_message = "Both queues should subscribe to the topic"
  }

  assert {
    condition     = jsondecode(aws_sns_topic_subscription.big_orders.filter_policy).amount[0].numeric == [">=", 100]
    error_message = "big-orders should only receive amount >= 100"
  }
}
