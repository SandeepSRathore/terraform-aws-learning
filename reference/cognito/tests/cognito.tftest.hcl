mock_provider "aws" {}

run "email_login_and_public_client" {
  command = plan

  assert {
    condition     = aws_cognito_user_pool.app.username_attributes == toset(["email"])
    error_message = "Users should sign in with email"
  }

  assert {
    condition     = aws_cognito_user_pool.app.password_policy[0].minimum_length == 12
    error_message = "Passwords should be at least 12 characters"
  }

  assert {
    condition     = aws_cognito_user_pool_client.web.generate_secret == false
    error_message = "A browser client must not have a secret"
  }
}
