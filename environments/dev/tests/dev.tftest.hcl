# Tests the whole environment: are the right modules switched on or off,
# and are they wired together correctly? Still 100% mocked.
mock_provider "aws" {
  # Mocks fill computed values with random strings, but some arguments are
  # validated (ECS insists execution_role_arn looks like a real ARN).
  # mock_resource sets realistic defaults for every resource of that type.
  mock_resource "aws_iam_role" {
    defaults = {
      arn = "arn:aws:iam::123456789012:role/mock-role"
    }
  }

  # Same idea: the Lambda permission and S3 notification validate these ARNs.
  mock_resource "aws_s3_bucket" {
    defaults = {
      arn = "arn:aws:s3:::mock-bucket"
    }
  }

  mock_resource "aws_lambda_function" {
    defaults = {
      arn = "arn:aws:lambda:us-east-1:123456789012:function:mock-fn"
    }
  }
}

# Overrides can target data sources INSIDE child modules too.
override_data {
  target = module.network.data.aws_availability_zones.available
  values = {
    names = ["us-east-1a", "us-east-1b", "us-east-1c"]
  }
}

run "defaults_create_only_s3_and_ec2" {
  command = plan

  assert {
    condition     = length(module.assets_bucket) == 1 && length(module.web) == 1
    error_message = "S3 and EC2 should be on by default"
  }

  assert {
    condition     = length(module.web_eip) == 0 && length(module.web_data_volume) == 0
    error_message = "Elastic IP and EBS should be off by default"
  }

  assert {
    condition     = length(module.app) == 0 && length(module.beanstalk) == 0
    error_message = "ECS and Beanstalk should be off by default"
  }

  assert {
    condition     = length(module.upload_processor) == 0 && length(aws_s3_bucket_notification.uploads) == 0
    error_message = "Lambda should be off by default"
  }

  assert {
    condition     = module.web_sg[0].rule_names == ["http"]
    error_message = "Without ssh_cidr, only HTTP should be open"
  }
}

run "ssh_rule_added_when_cidr_given" {
  command = plan

  variables {
    ssh_cidr = "203.0.113.10/32"
  }

  assert {
    condition     = contains(module.web_sg[0].rule_names, "ssh")
    error_message = "Setting ssh_cidr should add an ssh rule"
  }
}

run "everything_on" {
  command = apply # mocked apply: fake IDs/IPs flow between modules

  variables {
    enable_elastic_ip = true
    enable_ebs        = true
    enable_ecs        = true
    enable_beanstalk  = true
    enable_lambda     = true
  }

  assert {
    condition     = output.web_url == "http://${module.web_eip[0].public_ip}"
    error_message = "web_url should use the Elastic IP when it is enabled"
  }

  assert {
    condition     = output.web_data_volume_id != null && output.ecs_cluster == "tf-learning-app"
    error_message = "EBS volume and ECS cluster should exist"
  }

  assert {
    condition     = startswith(output.beanstalk_url, "http://")
    error_message = "Beanstalk should expose a URL"
  }

  assert {
    condition     = output.upload_processor_function == "tf-learning-upload-processor"
    error_message = "The upload processor Lambda should exist"
  }
}

run "lambda_triggered_only_by_uploads_folder" {
  command = apply # the bucket ARN in the policy is only known after (mocked) apply

  variables {
    enable_lambda = true
  }

  assert {
    condition     = aws_s3_bucket_notification.uploads[0].lambda_function[0].filter_prefix == "uploads/"
    error_message = "Only files in uploads/ should trigger the Lambda"
  }

  # Least privilege also prevents an endless loop: the function cannot
  # write into uploads/, so it can never trigger itself.
  assert {
    condition = (
      endswith(jsondecode(module.upload_processor[0].policy_json).Statement[0].Resource[0], "/uploads/*") &&
      endswith(jsondecode(module.upload_processor[0].policy_json).Statement[1].Resource[0], "/processed/*")
    )
    error_message = "The Lambda may only read uploads/ and write processed/"
  }
}

run "lambda_needs_s3" {
  command = plan

  variables {
    enable_lambda = true
    enable_s3     = false
  }

  assert {
    condition     = length(module.upload_processor) == 0
    error_message = "Without the bucket there is nothing to trigger the Lambda"
  }
}

run "everything_off" {
  command = plan

  variables {
    enable_s3  = false
    enable_ec2 = false
  }

  assert {
    condition     = output.web_url == null && output.assets_bucket == null
    error_message = "Disabled modules should produce null outputs"
  }
}
