# Cognito user pools = sign-up / sign-in for YOUR app's users (not AWS users).
# It stores users, checks passwords, sends verification emails, does MFA, and
# issues JWT tokens your API can verify (API Gateway can check them for you).
#
#   user pool   -> the user directory + rules (password policy, MFA, attributes)
#   app client  -> one per app (web, mobile); decides which login flows it may use
#   tokens      -> id token (who the user is), access token (what they may call),
#                  refresh token (gets new ones without asking for the password)

resource "aws_cognito_user_pool" "app" {
  name = "app-users"

  username_attributes      = ["email"] # users sign in with their email address
  auto_verified_attributes = ["email"] # Cognito emails a verification code

  password_policy {
    minimum_length    = 12
    require_lowercase = true
    require_uppercase = true
    require_numbers   = true
    require_symbols   = false
  }

  mfa_configuration = "OFF" # "OPTIONAL" or "ON" with software_token_mfa_configuration

  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  # Custom attributes are added as "custom:<name>" and can't be removed later.
  schema {
    name                = "plan"
    attribute_data_type = "String"
    mutable             = true

    string_attribute_constraints {
      min_length = 1
      max_length = 20
    }
  }
}

resource "aws_cognito_user_pool_client" "web" {
  name         = "web"
  user_pool_id = aws_cognito_user_pool.app.id

  generate_secret = false # browsers/mobile apps can't keep a secret

  # USER_SRP_AUTH is the secure default for real apps (password never sent).
  # USER_PASSWORD_AUTH sends the password over TLS; simple for scripts/tests.
  explicit_auth_flows = [
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
  ]

  access_token_validity  = 60 # minutes
  id_token_validity      = 60
  refresh_token_validity = 30 # days
  token_validity_units {
    access_token  = "minutes"
    id_token      = "minutes"
    refresh_token = "days"
  }

  prevent_user_existence_errors = "ENABLED" # don't reveal which emails are registered
}
