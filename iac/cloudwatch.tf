### LOGGING

# Create a Log Group for API Gateway to push logs to
resource "aws_cloudwatch_log_group" "api_gateway_log_group" {
  name_prefix       = "/pets-api/"
  retention_in_days = 30
}

# Create a Log Policy to allow API Gateway service to create log streams and put logs
resource "aws_cloudwatch_log_resource_policy" "allow_api_gateway_service_to_create_log_streams" {
  policy_name     = "Allow API Gateway to deliver logs"
  policy_document = <<POLICY3
  {
  "Version": "2012-10-17",
  "Id": "CloudWatchLogsPolicy",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "apigateway.amazonaws.com",
          "delivery.logs.amazonaws.com"
          ]
      },
      "Action": [
        "logs:CreateLogStream",
        "logs:PutLogEvents"
        ],
      "Resource": "${aws_cloudwatch_log_group.api_gateway_log_group.arn}",
      "Condition": {
        "ArnEquals": {
          "aws:SourceArn": "${aws_api_gateway_rest_api.pets_api.arn}"
        }
      }
    }
  ]
}
POLICY3
}

resource "aws_iam_role" "allow_api_gateway_to_assume_role" {
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "apigateway.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_api_gateway_account" "api_gateway_account" {
  cloudwatch_role_arn = aws_iam_role.allow_api_gateway_to_assume_role.arn
}

## delete if you have this configured in your account
resource "aws_iam_role_policy" "allows_to_write_to_cloudwatch" {
  role = aws_iam_role.allow_api_gateway_to_assume_role.id

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:DescribeLogGroups",
                "logs:DescribeLogStreams",
                "logs:PutLogEvents",
                "logs:GetLogEvents",
                "logs:FilterLogEvents"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

# Configure API Gateway to push all logs to CloudWatch Logs
resource "aws_api_gateway_method_settings" "MyApiGatewaySetting" {
  rest_api_id = aws_api_gateway_rest_api.pets_api.id
  stage_name  = aws_api_gateway_stage.pets_rest_api_stage.stage_name
  method_path = "*/*"

  settings {
    # Enable CloudWatch logging and metrics
    metrics_enabled = var.enable_logging ? true : false
    logging_level   = var.enable_logging ? "INFO" : "OFF"
  }
}

