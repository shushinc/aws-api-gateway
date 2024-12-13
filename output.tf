#Output the deployed API URL
output "api_url" {
  value = "${aws_api_gateway_deployment.sherlock.invoke_url}"
}

# Output the location of the generated file
# output "api_export_file" {
#   value = local_file.sherlock_api_export.filename
# }


output "aws_cognito_user_pool_details" {
  description = "Details of the created Cognito User Pool"
  value = {
    id        = aws_cognito_user_pool.sherlock_userpool.id
    arn       = aws_cognito_user_pool.sherlock_userpool.arn
    name      = aws_cognito_user_pool.sherlock_userpool.name
    endpoint  = aws_cognito_user_pool.sherlock_userpool.endpoint
  }
}

output "cognito_oauth_domain" {
  value = aws_cognito_user_pool_domain.sherlock_domain.domain
  description = "OAuth domain endpoint for the Cognito User Pool"
}

output "cognito_oauth_token_url" {
  value       = "https://${aws_cognito_user_pool_domain.sherlock_domain.domain}.auth.${var.region}.amazoncognito.com/oauth2/token"
  description = "Full URL for the OAuth2 token endpoint"
}


output "cognito_client_id" {
  value       = aws_cognito_user_pool_client.sherlock_client.id
  description = "Client ID for the Cognito User Pool App Client"
}

output "cognito_client_secret" {
  value       = aws_cognito_user_pool_client.sherlock_client.client_secret
  description = "Client Secret for the Cognito User Pool App Client"
  sensitive   = true
}


