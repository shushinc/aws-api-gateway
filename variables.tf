variable "region" {
  description = "The AWS region where the API Gateway will be deployed."
  type        = string
  default     = "us-east-1"
}

variable "api_name" {
  description = "The name of the API Gateway."
  type        = string
  default     = "Sherlock API"
}

variable "exported_api_file" {
  description = "Path to the OpenAPI/Swagger file to import into API Gateway."
  type        = string
}

variable "stage_name" {
  description = "The name of the stage to deploy the API Gateway."
  type        = string
  default     = "prod"
}
variable "sherlock_base_url" {
  description = "The base URL to be used in the OpenAPI spec file"
  type        = string
}

variable "sherlock_api_oauth_domain" {
  description = "Sherlock API Oauth Token Domain"
  type        = string
}


variable "sherlock_api_client" {
  description = "Sherlock API Test Client"
  type        = string
}



