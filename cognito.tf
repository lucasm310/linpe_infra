resource "aws_cognito_user_pool" "linpe" {
  name                     = "linpe_pool-${terraform.workspace}"
  username_attributes      = ["email"]
  auto_verified_attributes = ["email"]
  mfa_configuration        = "OFF"
  tags                     = merge(var.tags, { enviroment = terraform.workspace })

  dynamic "schema" {
    for_each = var.cognito_custom_fields
    content {
      attribute_data_type = "String"
      name                = schema.value
      required            = false
      mutable             = true
      string_attribute_constraints {
        min_length = 3
        max_length = 256
      }
    }
  }

  password_policy {
    minimum_length                   = "8"
    require_lowercase                = false
    require_numbers                  = false
    require_symbols                  = false
    require_uppercase                = false
    temporary_password_validity_days = 7
  }

  verification_message_template {
    default_email_option = "CONFIRM_WITH_CODE"
    email_message        = "Use este código: {####} para verificar sua conta no site da Linpe."
    email_subject        = "Cadastro LINPE"
  }

  lambda_config {
    post_confirmation = aws_lambda_function.lambda_cognito.arn
  }
  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }
}

resource "aws_cognito_user_pool_domain" "linpe" {
  domain       = "linpe-auth-01-${terraform.workspace}"
  user_pool_id = aws_cognito_user_pool.linpe.id
}

resource "aws_cognito_user_group" "main" {
  count        = length(var.cognito_groups)
  name         = element(var.cognito_groups, count.index)
  user_pool_id = aws_cognito_user_pool.linpe.id
  description  = "Grupo ${element(var.cognito_groups, count.index)}"
}

resource "aws_cognito_identity_provider" "linpe_google" {
  user_pool_id  = aws_cognito_user_pool.linpe.id
  provider_name = "Google"
  provider_type = "Google"

  provider_details = {
    authorize_scopes = "openid email profile"
    client_id        = var.google_id
    client_secret    = var.google_secret
  }
  attribute_mapping = {
    email     = "email"
    name      = "name"
    username  = "sub"
    birthdays = "birthdate"
  }
}

resource "aws_cognito_user_pool_client" "linpe_client_web" {
  name = "linpe_app_clientweb-${terraform.workspace}"
  depends_on = [
    aws_cognito_identity_provider.linpe_google
  ]
  user_pool_id                         = aws_cognito_user_pool.linpe.id
  refresh_token_validity               = 7
  read_attributes                      = var.cognito_fields
  write_attributes                     = var.cognito_fields
  explicit_auth_flows                  = ["ALLOW_CUSTOM_AUTH", "ALLOW_USER_SRP_AUTH", "ALLOW_REFRESH_TOKEN_AUTH"]
  supported_identity_providers         = ["COGNITO", "Google"]
  callback_urls                        = lookup(var.cognito_urls, terraform.workspace)
  logout_urls                          = lookup(var.cognito_urls, terraform.workspace)
  allowed_oauth_flows                  = ["code"]
  allowed_oauth_scopes                 = ["phone", "email", "openid", "profile", "aws.cognito.signin.user.admin"]
  allowed_oauth_flows_user_pool_client = true
}

resource "aws_cognito_identity_pool" "linpe_identity_pool" {
  identity_pool_name               = "linpe_identiy_pool-${terraform.workspace}"
  allow_unauthenticated_identities = false
  allow_classic_flow               = false
  cognito_identity_providers {
    client_id               = aws_cognito_user_pool_client.linpe_client_web.id
    provider_name           = aws_cognito_user_pool.linpe.endpoint
    server_side_token_check = false
  }
}

resource "aws_iam_role" "authenticated" {
  name = "cognito_authenticated_linpe-${terraform.workspace}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "cognito-identity.amazonaws.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "cognito-identity.amazonaws.com:aud": "${aws_cognito_identity_pool.linpe_identity_pool.id}"
        },
        "ForAnyValue:StringLike": {
          "cognito-identity.amazonaws.com:amr": "authenticated"
        }
      }
    }
  ]
}
EOF
}

resource "aws_iam_role" "unauthenticated" {
  name = "cognito_unauthenticated_linpe-${terraform.workspace}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "cognito-identity.amazonaws.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "cognito-identity.amazonaws.com:aud": "${aws_cognito_identity_pool.linpe_identity_pool.id}"
        },
        "ForAnyValue:StringLike": {
          "cognito-identity.amazonaws.com:amr": "unauthenticated"
        }
      }
    }
  ]
}
EOF
}

resource "aws_cognito_identity_pool_roles_attachment" "main" {
  identity_pool_id = aws_cognito_identity_pool.linpe_identity_pool.id
  roles = {
    "authenticated"   = aws_iam_role.authenticated.arn
    "unauthenticated" = aws_iam_role.unauthenticated.arn
  }
}
