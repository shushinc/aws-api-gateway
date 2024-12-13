terraform {
  required_providers {
    null = {
      source  = "hashicorp/null"
      version = ">= 3.2.1"
    }
  }
}

provider "aws" {
  region = var.region
}

# Create the Cognito User Pool
resource "aws_cognito_user_pool" "sherlock_userpool" {
  name                       = "sherlock-userpool"
  deletion_protection        = "ACTIVE"
  mfa_configuration          = "OFF"
  email_configuration {
    email_sending_account  = "COGNITO_DEFAULT"
  }
  password_policy {
    minimum_length                   = 8
    require_lowercase                = true
    require_numbers                  = true
    require_symbols                  = true
    require_uppercase                = true
    temporary_password_validity_days = 7
  }
  username_configuration {
    case_sensitive = false
  }
}

# Add a Cognito User Pool Domain
resource "aws_cognito_user_pool_domain" "sherlock_domain" {
  domain          = var.sherlock_api_oauth_domain 
  user_pool_id    = aws_cognito_user_pool.sherlock_userpool.id
}

# Add a Cognito Resource Server
resource "aws_cognito_resource_server" "sherlocksource" {
  user_pool_id = aws_cognito_user_pool.sherlock_userpool.id
  name         = "testresource"
  identifier   = "test"

  scope {
    scope_name  = "read"
    scope_description = "Read access"
  }

  scope {
    scope_name  = "write"
    scope_description = "Write access"
  }
}

# Create a Cognito User Pool Client
resource "aws_cognito_user_pool_client" "sherlock_client" {
  name         = var.sherlock_api_client
  user_pool_id = aws_cognito_user_pool.sherlock_userpool.id

  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_scopes                 = [
    # "openid",
    # "profile",
    # "aws.cognito.signin.user.admin",
    "test/read",
    "test/write"
  ]
  allowed_oauth_flows = ["client_credentials"]
  generate_secret      = true

  explicit_auth_flows = [
    "ALLOW_ADMIN_USER_PASSWORD_AUTH",
    "ALLOW_CUSTOM_AUTH",
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH"
  ]

  prevent_user_existence_errors = "ENABLED" 

   # Add Cognito User Pool as an Identity Provider
  supported_identity_providers = ["COGNITO"]
}


# # Create the Cognito User Pool Authorizer
# resource "aws_api_gateway_authorizer" "authorizer" {
#   depends_on = [ aws_cognito_user_pool.sherlock_userpool ]
#   name             = "SherlockAuthorizer"
#   rest_api_id      = aws_api_gateway_rest_api.sherlock.id
#   type             = "COGNITO_USER_POOLS"
#   provider_arns    = [aws_cognito_user_pool.sherlock_userpool.arn] # Dynamically linked to the user pool
#   identity_source  = "method.request.header.Authorization"
# }


# resource "null_resource" "update_sherlock_api" {
#   provisioner "local-exec" {
#     command = <<EOT
# python3 ./update_json.py ${aws_cognito_user_pool.sherlock_userpool.arn}
# EOT
#   }
#   depends_on = [aws_cognito_user_pool.sherlock_userpool]
# }


# resource "aws_api_gateway_rest_api" "sherlock_doc_update" {
#   name = var.api_name
#   body = templatefile(var.exported_api_file, {
#     base_url = var.sherlock_base_url
#   })
# }


# Import the API Gateway
resource "aws_api_gateway_rest_api" "sherlock" {
  # Ensure Cognito User Pool and Authorizer are created first
  depends_on = [
    aws_cognito_user_pool.sherlock_userpool
    # null_resource.update_sherlock_api
    # local_file.sherlock_api_export
    # aws_api_gateway_authorizer.authorizer
  ]
  name = var.api_name
  #body = file(var.exported_api_file)
  body = templatefile(var.exported_api_file, {
    base_url = var.sherlock_base_url
    cognito_user_pool_arn = aws_cognito_user_pool.sherlock_userpool.arn

  })
}


# Deploy the API
resource "aws_api_gateway_deployment" "sherlock" {
  rest_api_id = aws_api_gateway_rest_api.sherlock.id
 
  triggers = {
    redeployment = sha1(jsonencode(aws_api_gateway_rest_api.sherlock.body))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "sherlock" {
  deployment_id = aws_api_gateway_deployment.sherlock.id
  rest_api_id   = aws_api_gateway_rest_api.sherlock.id
  stage_name    = var.stage_name

  variables = {
    log_level = "INFO"
  }
}