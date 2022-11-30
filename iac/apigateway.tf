########################################
# IAM
########################################

# IAM role API Gateway will assume to integrate with DynamoDB
resource "aws_iam_role" "api_gateway_role" {
  assume_role_policy = <<POLICY1
{
  "Version" : "2012-10-17",
  "Statement" : [
    {
      "Effect" : "Allow",
      "Principal" : {
        "Service" : "apigateway.amazonaws.com"
      },
      "Action" : "sts:AssumeRole"
    }
  ]
}
POLICY1
}

# Attach the dynamodb_read_write_policy IAM policy to the above role
resource "aws_iam_role_policy_attachment" "api_gateway_policy_attachment" {
  role       = aws_iam_role.api_gateway_role.name
  policy_arn = aws_iam_policy.dynamodb_read_write_policy.arn
}

########################################
# API Gateway
########################################

resource "aws_api_gateway_rest_api" "pets_api" {
  name = "Pets Rest API"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

########################################
# POST Integration
########################################

resource "aws_api_gateway_resource" "pets" {
  rest_api_id = aws_api_gateway_rest_api.pets_api.id
  path_part   = "pets"
  parent_id   = aws_api_gateway_rest_api.pets_api.root_resource_id
}

resource "aws_api_gateway_method" "create_pets" {
  authorization    = "NONE"
  http_method      = "POST"
  resource_id      = aws_api_gateway_resource.pets.id
  rest_api_id      = aws_api_gateway_rest_api.pets_api.id
  api_key_required = true # Just to make sure we don't let anyone call our API $$$. See "API key" section below
  request_models = {      # API Gateway will type-check input
    "application/json" = aws_api_gateway_model.pets_post_request_model.name
  }
}

resource "aws_api_gateway_method_response" "create_pets_ok" {
  http_method = aws_api_gateway_method.create_pets.http_method
  resource_id = aws_api_gateway_resource.pets.id
  rest_api_id = aws_api_gateway_rest_api.pets_api.id
  status_code = "200"
  response_models = {
    "application/json" = aws_api_gateway_model.empty_model.name
  }
}

resource "aws_api_gateway_method_response" "create_pets_bad_request" {
  http_method = aws_api_gateway_method.create_pets.http_method
  resource_id = aws_api_gateway_resource.pets.id
  rest_api_id = aws_api_gateway_rest_api.pets_api.id
  status_code = "400"
  response_models = {
    "application/json" = aws_api_gateway_model.error_response_model.name
  }
}

resource "aws_api_gateway_method_response" "create_pets_internal_server_error" {
  http_method = aws_api_gateway_method.create_pets.http_method
  resource_id = aws_api_gateway_resource.pets.id
  rest_api_id = aws_api_gateway_rest_api.pets_api.id
  status_code = "500"
  response_models = {
    "application/json" = aws_api_gateway_model.error_response_model.name
  }
}

resource "aws_api_gateway_integration" "forward_create_pets_to_dynamodb" {
  http_method             = aws_api_gateway_method.create_pets.http_method
  resource_id             = aws_api_gateway_resource.pets.id
  rest_api_id             = aws_api_gateway_rest_api.pets_api.id
  type                    = "AWS"
  integration_http_method = "POST"
  uri                     = "arn:aws:apigateway:${var.aws_region}:dynamodb:action/BatchWriteItem"
  credentials             = aws_iam_role.api_gateway_role.arn
  request_templates = {
    "application/json" = local.post_request_mapping
  }
  passthrough_behavior = "NEVER"
}

resource "aws_api_gateway_integration_response" "map_dynamodb_response_ok_to_apiwgateway_response_ok" {
  depends_on        = [aws_api_gateway_integration.forward_create_pets_to_dynamodb]
  http_method       = aws_api_gateway_method.create_pets.http_method
  resource_id       = aws_api_gateway_resource.pets.id
  rest_api_id       = aws_api_gateway_rest_api.pets_api.id
  status_code       = aws_api_gateway_method_response.create_pets_ok.status_code
  selection_pattern = "2\\d{2}"
}

resource "aws_api_gateway_integration_response" "map_dynamodb_response_error_to_apiwgateway_response_error" {
  depends_on        = [aws_api_gateway_integration.forward_create_pets_to_dynamodb]
  http_method       = aws_api_gateway_method.create_pets.http_method
  resource_id       = aws_api_gateway_resource.pets.id
  rest_api_id       = aws_api_gateway_rest_api.pets_api.id
  status_code       = aws_api_gateway_method_response.create_pets_internal_server_error.status_code
  selection_pattern = "5\\d{2}"
  response_templates = {
    "application/json" = local.dynamodb_error_response_mapping
  }
}

resource "aws_api_gateway_integration_response" "map_dynamodb_response_badrequest_to_apiwgateway_response_badrequest" {
  depends_on        = [aws_api_gateway_integration.forward_create_pets_to_dynamodb]
  http_method       = aws_api_gateway_method.create_pets.http_method
  resource_id       = aws_api_gateway_resource.pets.id
  rest_api_id       = aws_api_gateway_rest_api.pets_api.id
  status_code       = aws_api_gateway_method_response.create_pets_bad_request.status_code
  selection_pattern = "4\\d{2}"
  response_templates = {
    "application/json" = local.dynamodb_error_response_mapping
  }
}

########################################
# GET by owner with optional parameters
########################################
resource "aws_api_gateway_resource" "get_pets_by_owner" {
  rest_api_id = aws_api_gateway_rest_api.pets_api.id
  path_part   = "{owner}"
  parent_id   = aws_api_gateway_resource.pets.id
}

resource "aws_api_gateway_method" "get_pets_by_id" {
  authorization    = "NONE"
  http_method      = "GET"
  resource_id      = aws_api_gateway_resource.get_pets_by_owner.id
  rest_api_id      = aws_api_gateway_rest_api.pets_api.id
  api_key_required = true
  request_models = {
    "application/json" = aws_api_gateway_model.empty_model.name
  }
  request_parameters = {
    "method.request.path.owner" = true
    "method.request.querystring.name" = true
    "method.request.querystring.race" = true
    "method.request.querystring.gender" = true
    "method.request.querystring.minAge" = true
    "method.request.querystring.maxAge" = true
  }
}

resource "aws_api_gateway_method_response" "get_pets_response_ok" {
  http_method = aws_api_gateway_method.get_pets_by_id.http_method
  resource_id = aws_api_gateway_resource.get_pets_by_owner.id
  rest_api_id = aws_api_gateway_rest_api.pets_api.id
  status_code = "200"
  response_models = {
    "application/json" = aws_api_gateway_model.empty_model.name
  }
}

resource "aws_api_gateway_method_response" "get_pets_response_bad_request" {
  http_method = aws_api_gateway_method.get_pets_by_id.http_method
  resource_id = aws_api_gateway_resource.get_pets_by_owner.id
  rest_api_id = aws_api_gateway_rest_api.pets_api.id
  status_code = "400"
  response_models = {
    "application/json" = aws_api_gateway_model.error_response_model.name
  }
}

resource "aws_api_gateway_method_response" "get_pets_response_internal_server_error" {
  http_method = aws_api_gateway_method.get_pets_by_id.http_method
  resource_id = aws_api_gateway_resource.get_pets_by_owner.id
  rest_api_id = aws_api_gateway_rest_api.pets_api.id
  status_code = "500"
  response_models = {
    "application/json" = aws_api_gateway_model.error_response_model.name
  }
}

resource "aws_api_gateway_integration" "forward_get_pets_to_dynamodb" {
  http_method             = aws_api_gateway_method.get_pets_by_id.http_method
  resource_id             = aws_api_gateway_resource.get_pets_by_owner.id
  rest_api_id             = aws_api_gateway_rest_api.pets_api.id
  type                    = "AWS"
  integration_http_method = "POST"
  uri                     = "arn:aws:apigateway:${var.aws_region}:dynamodb:action/Query"
  credentials             = aws_iam_role.api_gateway_role.arn
  request_templates = {
    "application/json" = local.get_request_mapping
  }
  passthrough_behavior = "NEVER"
}

resource "aws_api_gateway_integration_response" "get_pets_response_ok" {
  depends_on        = [aws_api_gateway_integration.forward_get_pets_to_dynamodb]
  http_method       = aws_api_gateway_method.get_pets_by_id.http_method
  resource_id       = aws_api_gateway_resource.get_pets_by_owner.id
  rest_api_id       = aws_api_gateway_rest_api.pets_api.id
  status_code       = aws_api_gateway_method_response.get_pets_response_ok.status_code
  selection_pattern = "2\\d{2}"
  response_templates = {
    "application/json" = local.get_response_mapping
  }
}

resource "aws_api_gateway_integration_response" "get_pets_response_error" {
  depends_on        = [aws_api_gateway_integration.forward_get_pets_to_dynamodb]
  http_method       = aws_api_gateway_method.get_pets_by_id.http_method
  resource_id       = aws_api_gateway_resource.get_pets_by_owner.id
  rest_api_id       = aws_api_gateway_rest_api.pets_api.id
  status_code       = aws_api_gateway_method_response.get_pets_response_internal_server_error.status_code
  selection_pattern = "5\\d{2}"
  response_templates = {
    "application/json" = local.dynamodb_error_response_mapping
  }
}

resource "aws_api_gateway_integration_response" "get_pets_response_bad_request" {
  depends_on        = [aws_api_gateway_integration.forward_get_pets_to_dynamodb]
  http_method       = aws_api_gateway_method.get_pets_by_id.http_method
  resource_id       = aws_api_gateway_resource.get_pets_by_owner.id
  rest_api_id       = aws_api_gateway_rest_api.pets_api.id
  status_code       = aws_api_gateway_method_response.get_pets_response_bad_request.status_code
  selection_pattern = "4\\d{2}"
  response_templates = {
    "application/json" = local.dynamodb_error_response_mapping
  }
}

# Create a new API Gateway deployment for the created rest api
resource "aws_api_gateway_deployment" "pets_api_deployment" {
  rest_api_id = aws_api_gateway_rest_api.pets_api.id

  triggers = { #Redeploy every time any integration component has changed
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.pets.id,
      aws_api_gateway_resource.get_pets_by_owner.id,
      aws_api_gateway_method.create_pets.id,
      aws_api_gateway_method.get_pets_by_id.id,
      aws_api_gateway_integration.forward_get_pets_to_dynamodb.id,
      aws_api_gateway_integration.forward_create_pets_to_dynamodb.id,
      aws_api_gateway_method_response.get_pets_response_ok.id,
      aws_api_gateway_method_response.get_pets_response_bad_request.id,
      aws_api_gateway_method_response.get_pets_response_internal_server_error.id,
      aws_api_gateway_integration_response.get_pets_response_bad_request.id,
      aws_api_gateway_integration_response.get_pets_response_error.id,
      aws_api_gateway_integration_response.get_pets_response_ok.id,
      aws_api_gateway_integration_response.map_dynamodb_response_badrequest_to_apiwgateway_response_badrequest.id,
      aws_api_gateway_integration_response.map_dynamodb_response_error_to_apiwgateway_response_error.id,
      aws_api_gateway_integration_response.map_dynamodb_response_ok_to_apiwgateway_response_ok.id,
      local.get_request_mapping,
      local.get_response_mapping,
      local.post_request_mapping
    ]))
  }
  lifecycle {
    create_before_destroy = true
  }
}

# Create a new API Gateway stage with logs enabled
resource "aws_api_gateway_stage" "pets_rest_api_stage" {
  deployment_id = aws_api_gateway_deployment.pets_api_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.pets_api.id
  stage_name    = "v1"

  depends_on = [aws_api_gateway_account.api_gateway_account]

  dynamic "access_log_settings" {
    for_each = var.enable_logging ? toset(["log_group"]) : toset([])
    content {
      destination_arn = aws_cloudwatch_log_group.api_gateway_log_group.arn
      format          = "{ \"requestId\":\"$context.requestId\", \"ip\": \"$context.identity.sourceIp\", \"requestTime\":\"$context.requestTime\", \"httpMethod\":\"$context.httpMethod\",\"routeKey\":\"$context.routeKey\", \"status\":\"$context.status\",\"protocol\":\"$context.protocol\", \"responseLength\":\"$context.responseLength\" }"
    }
  }
}

########################################
# API Key
########################################

# Create an API Gateway Key for API consumer
resource "aws_api_gateway_api_key" "api_key" {
  name = "pets-api-key"
}

resource "aws_api_gateway_usage_plan" "usage_plan" {
  name = "Client access to API"
  api_stages {
    api_id = aws_api_gateway_rest_api.pets_api.id
    stage  = aws_api_gateway_stage.pets_rest_api_stage.stage_name
  }
}

resource "aws_api_gateway_usage_plan_key" "usage_plan_key" {
  key_type = "API_KEY"
  key_id = aws_api_gateway_api_key.api_key.id
  usage_plan_id = aws_api_gateway_usage_plan.usage_plan.id
}