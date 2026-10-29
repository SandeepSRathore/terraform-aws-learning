mock_provider "aws" {}

variables {
  name            = "hello"
  jar_path        = "./tests/fixtures/app-v1.jar"
  artifact_bucket = "my-artifacts"
  vpc_id          = "vpc-12345678"
  subnet_id       = "subnet-12345678"
  ami_id          = "ami-0abcdef1234567890" # skip the AMI lookup in tests
}

run "uploads_jar_and_opens_app_port" {
  command = plan

  assert {
    condition     = aws_s3_object.jar.key == "artifacts/hello/app-v1.jar" && aws_s3_object.jar.bucket == "my-artifacts"
    error_message = "The JAR should be uploaded to artifacts/<name>/ in the bucket"
  }

  assert {
    condition     = aws_s3_object.jar.source_hash == filesha256("./tests/fixtures/app-v1.jar")
    error_message = "The upload should track the JAR's checksum"
  }

  assert {
    condition     = module.security_group.rule_names == ["app 0.0.0.0/0"]
    error_message = "Only the app port should be open by default (no SSH)"
  }

  # Least privilege: the role may read this one object and nothing else.
  assert {
    condition     = jsondecode(module.instance_profile.policy_json).Statement[0].Resource == ["arn:aws:s3:::my-artifacts/artifacts/hello/app-v1.jar"]
    error_message = "The instance may only read its own JAR"
  }
}

run "bootstrap_script_has_every_step_in_order" {
  command = plan

  assert {
    condition     = startswith(output.bootstrap_script, "#!/bin/bash")
    error_message = "user_data must start with a shebang, or it won't run"
  }

  # strcontains + regexall find each step's banner; their positions must increase.
  assert {
    condition = (
      length(regexall("(?s)Bootstrapping.*Install Java 21.*Create user.*Download s3://my-artifacts/artifacts/hello/app-v1.jar.*Verify SHA-256.*app.env.*Start \\$APP_NAME.*Wait up to 180s", output.bootstrap_script)) == 1
    )
    error_message = "Steps 00-60 should all be present, in file-name order"
  }

  assert {
    condition     = strcontains(output.bootstrap_script, filesha256("./tests/fixtures/app-v1.jar"))
    error_message = "The script must verify the exact checksum of the uploaded JAR"
  }

  assert {
    condition     = !strcontains(output.bootstrap_script, "AWS_ENDPOINT_URL")
    error_message = "Against real AWS, the script must not redirect the AWS CLI"
  }
}

run "app_settings_reach_the_env_file" {
  command = plan

  variables {
    java_version     = 25
    app_port         = 9090
    app_env          = { APP_MESSAGE = "Hello from EC2", SPRING_PROFILES_ACTIVE = "dev" }
    aws_endpoint_url = "http://localhost.localstack.cloud:4566"
  }

  assert {
    condition     = strcontains(output.bootstrap_script, "java-25-amazon-corretto-headless")
    error_message = "java_version should pick the Corretto package"
  }

  assert {
    condition = alltrue([
      strcontains(output.bootstrap_script, "SERVER_PORT=\"9090\""),
      strcontains(output.bootstrap_script, "APP_MESSAGE=\"Hello from EC2\""),
      strcontains(output.bootstrap_script, "SPRING_PROFILES_ACTIVE=\"dev\""),
    ])
    error_message = "Port and app_env should be written to app.env"
  }

  assert {
    condition     = strcontains(output.bootstrap_script, "export AWS_ENDPOINT_URL=\"http://localhost.localstack.cloud:4566\"")
    error_message = "aws_endpoint_url should redirect the instance's AWS CLI (LocalStack)"
  }
}

run "ssh_only_when_asked" {
  command = plan

  variables {
    ssh_cidr = "203.0.113.10/32"
  }

  assert {
    condition     = contains(module.security_group.rule_names, "ssh")
    error_message = "ssh_cidr should open port 22 to that address"
  }
}

# The heart of the deploy model: a new JAR changes user_data, and changed
# user_data replaces the instance. run.<name>.<output> reads an earlier run.
run "new_jar_changes_user_data" {
  command = plan

  variables {
    jar_path = "./tests/fixtures/app-v2.jar"
  }

  assert {
    condition     = output.bootstrap_script != run.bootstrap_script_has_every_step_in_order.bootstrap_script
    error_message = "A different JAR must produce different user_data (that's what triggers the redeploy)"
  }

  assert {
    condition     = output.artifact_sha256 == filesha256("./tests/fixtures/app-v2.jar")
    error_message = "The new checksum should be used"
  }
}

run "rejects_secrets_looking_values" {
  command = plan

  variables {
    app_env = { DB_URL = "jdbc:postgresql://db/$PASSWORD" }
  }

  expect_failures = [var.app_env]
}

run "rejects_privileged_port" {
  command = plan

  variables {
    app_port = 80
  }

  expect_failures = [var.app_port]
}

run "rejects_old_java" {
  command = plan

  variables {
    java_version = 11
  }

  expect_failures = [var.java_version]
}
