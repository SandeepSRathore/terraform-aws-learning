mock_provider "aws" {
  mock_data "aws_subnets" {
    defaults = {
      ids = ["subnet-aaaa1111", "subnet-bbbb2222"]
    }
  }

  mock_data "aws_vpc" {
    defaults = {
      cidr_block = "172.31.0.0/16"
    }
  }
}

run "secure_private_postgres" {
  command = plan

  assert {
    condition     = aws_db_instance.main.engine == "postgres" && aws_db_instance.main.storage_encrypted
    error_message = "Expected encrypted Postgres"
  }

  assert {
    condition     = aws_db_instance.main.publicly_accessible == false
    error_message = "The database must not be public"
  }

  assert {
    condition     = aws_db_instance.main.manage_master_user_password
    error_message = "RDS should manage the master password in Secrets Manager"
  }
}
