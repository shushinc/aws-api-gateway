output "cognito_app_client_id" {
  value = aws_cognito_user_pool_client.sherlock_app_client.id
  description = "The ID of the Cognito App Client"
}

output "cognito_app_client_secret" {
  value       = aws_cognito_user_pool_client.sherlock_app_client.client_secret
  description = "The Client Secret of the Cognito App Client"
  sensitive   = true
}

output "cognito_user_pool_logout_endpoint" {
  value       = "https://${aws_cognito_user_pool_domain.sherlock_userpool_domain.domain}.auth.${var.region}.amazoncognito.com/logout"
  description = "Cognito User Pool Logout Endpoint"
}
output "api_endpoint" {
  description = "The base URL for the deployed API Gateway"
  value       = "https://${aws_api_gateway_rest_api.sherlock.id}.execute-api.${var.region}.amazonaws.com/${aws_api_gateway_stage.sherlock.stage_name}"
}
