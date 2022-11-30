output "api_gateway_url" {
  value       = aws_api_gateway_stage.pets_rest_api_stage.invoke_url
  description = "API Gateway Invocation URL"
}

output "api_gateway_key" {
  value       = aws_api_gateway_usage_plan_key.usage_plan_key.value
  description = "API Key"
  sensitive   = false
}