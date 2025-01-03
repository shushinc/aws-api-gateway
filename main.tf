provider "aws" {
  region = var.region
}

# Create a Cognito User Pool
resource "aws_cognito_user_pool" "sherlock_userpool" {
  name = "sherlock-userpool"

  password_policy {
    minimum_length                   = 8
    require_uppercase                = true
    require_lowercase                = true
    require_numbers                  = true
    require_symbols                  = true
    temporary_password_validity_days = 7
  }

  schema {
    name                     = "email"
    attribute_data_type      = "String"
    mutable                  = true
    required                 = true
    string_attribute_constraints {
      min_length = 5
      max_length = 128
    }
  }

  schema {
    name                = "phone_number"
    attribute_data_type = "String"
    mutable             = true
    required            = false
  }

  mfa_configuration = "OFF"

  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
    recovery_mechanism {
      name     = "verified_phone_number"
      priority = 2
    }
  }

  email_configuration {
    email_sending_account = "COGNITO_DEFAULT"
  }

  username_configuration {
    case_sensitive = false
  }

  admin_create_user_config {
    allow_admin_create_user_only = false
  }

  tags = {
    Environment = var.environment
  }
}


# Create a Cognito User Pool Domain
resource "aws_cognito_user_pool_domain" "sherlock_userpool_domain" {
  domain      = var.oauth_domain
  user_pool_id = aws_cognito_user_pool.sherlock_userpool.id
}

# Create a Cognito User Pool Resource Server with custom scopes
resource "aws_cognito_resource_server" "sherlockapiresource" {
  user_pool_id = aws_cognito_user_pool.sherlock_userpool.id
  identifier   = "sherlockapiresource"
  name         = "Sherlock API Resource"

  scope {
    scope_name  = "read"
    scope_description = "Read access to the Sherlock API"
  }

  scope {
    scope_name  = "write"
    scope_description = "Write access to the Sherlock API"
  }
}

# Prepare the OpenAPI Specification with Cognito User Pool ARN
# data "template_file" "openapi_with_authorizer" {
#   template = file(var.exported_api_file)
#   vars = {
#     cognito_user_pool_arn = aws_cognito_user_pool.sherlock_userpool.arn
#   }
# }

# Import the API Gateway
resource "aws_api_gateway_rest_api" "sherlock" {
    depends_on = [aws_cognito_user_pool.sherlock_userpool]
    name        = "sherlock-api"
     description = "API created from Swagger definition"
#   body = file(var.exported_api_file)
#   body        = data.template_file.openapi_with_authorizer.rendered
    body        = templatefile(var.exported_api_file, {
        cognito_user_pool_arn = aws_cognito_user_pool.sherlock_userpool.arn,
        base_url              = var.base_url

    })
}

# Deploy the API
resource "aws_api_gateway_deployment" "sherlock" {
    depends_on = [aws_cognito_user_pool.sherlock_userpool]
  rest_api_id = aws_api_gateway_rest_api.sherlock.id

  triggers = {
    redeployment = sha1(jsonencode(aws_api_gateway_rest_api.sherlock.body))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "sherlock" {
  depends_on = [aws_cognito_user_pool.sherlock_userpool]
  deployment_id = aws_api_gateway_deployment.sherlock.id
  rest_api_id   = aws_api_gateway_rest_api.sherlock.id
  stage_name    = var.stage_name

  variables = {
    log_level = "INFO"
  }
}

resource "aws_cognito_user_pool_client" "sherlock_app_client" {
  name                            = "sherlock-app-client"
  user_pool_id                    = aws_cognito_user_pool.sherlock_userpool.id
  generate_secret                 = true
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows             = ["client_credentials"]
  allowed_oauth_scopes            = [
    "sherlockapiresource/read",
    "sherlockapiresource/write"
  ]
  supported_identity_providers    = ["COGNITO"]
  depends_on = [aws_cognito_resource_server.sherlockapiresource]
}



