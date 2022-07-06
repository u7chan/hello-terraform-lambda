terraform {
  required_version = ">= 0.12"
}

provider "aws" {
  region = var.aws_region
}

# ===============================================
# Role
# ===============================================

data "aws_iam_policy_document" "policy" {
  statement {
    sid    = ""
    effect = "Allow"

    principals {
      identifiers = ["lambda.amazonaws.com", "apigateway.amazonaws.com"]
      type        = "Service"
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "iam_for_lambda" {
  name               = "terraform-iam-for-lambda"
  assume_role_policy = data.aws_iam_policy_document.policy.json
}

resource "aws_iam_role" "iam_for_api_gateway" {
  name               = "terraform-iam-for-api-gateway"
  assume_role_policy = data.aws_iam_policy_document.policy.json
}

# ===============================================
# Policy
# ===============================================

# ======================
# Lambda
# ======================

resource "aws_iam_policy" "lambda_policy" {
  name   = aws_iam_role.iam_for_lambda.name
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "dynamodb:PutItem",
        "dynamodb:DeleteItem",
        "dynamodb:GetItem",
        "dynamodb:Query",
        "dynamodb:Scan",
        "dynamodb:UpdateItem",
        "dynamodb:BatchWriteItem"
      ],
      "Resource": "arn:aws:dynamodb:*:*:table/*"
    }
  ]
}
EOF
}

resource "aws_iam_policy_attachment" "lambda_policy_attach" {
  name       = "${aws_iam_role.iam_for_lambda.name}_attach"
  policy_arn = aws_iam_policy.lambda_policy.arn
  roles      = [
    aws_iam_role.iam_for_lambda.name
  ]
}

# ======================
# API Gateway
# ======================

resource "aws_iam_policy" "api_gateway_policy" {
  name   = aws_iam_role.iam_for_api_gateway.name
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
      {
          "Effect": "Allow",
          "Action": "lambda:InvokeFunction",
          "Resource": "*"
      }
  ]
}
EOF
}

resource "aws_iam_policy_attachment" "api_gateway_policy_attach" {
  name       = "${aws_iam_role.iam_for_api_gateway.name}_attach"
  roles      = ["${aws_iam_role.iam_for_api_gateway.name}"]
  policy_arn = "${aws_iam_policy.api_gateway_policy.arn}"
}

# ===============================================
# Lambda
# ===============================================

resource "aws_lambda_function" "get_user" {
  function_name = "terrform-getUser"

  filename         = var.file_name_get_user
  source_code_hash = filemd5(var.file_name_get_user)

  role    = aws_iam_role.iam_for_lambda.arn
  handler = "getUser.getUser"
  runtime = "nodejs16.x"
}

resource "aws_lambda_function" "put_user" {
  function_name = "terrform-putUser"

  filename         = var.file_name_put_user
  source_code_hash = filemd5(var.file_name_put_user)

  role    = aws_iam_role.iam_for_lambda.arn
  handler = "putUser.putUser"
  runtime = "nodejs16.x"
}

# ===============================================
# DynamoDB
# ===============================================

resource "aws_dynamodb_table" "basic-dynamodb-table" {
  name           = "terrform-table"
  billing_mode   = "PROVISIONED"
  read_capacity  = 1
  write_capacity = 1
  hash_key       = "email"

  attribute {
    name = "email"
    type = "S"
  }
}

# ===============================================
# API Gateway
# ===============================================

resource "aws_api_gateway_rest_api" "rest_api" {
  name        = "terraform_example"
  description = "'terraform_example' API Gateway"
}

# ======================
# API: get_user
# ======================

resource "aws_api_gateway_resource" "get_user" {
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  parent_id   = aws_api_gateway_rest_api.rest_api.root_resource_id
  path_part   = "get_user"
}

resource "aws_api_gateway_method" "get_user" {
  rest_api_id      = aws_api_gateway_rest_api.rest_api.id
  resource_id      = aws_api_gateway_resource.get_user.id
  http_method      = "GET"
  authorization    = "NONE"
  api_key_required = true  // Use API Key 
}

resource "aws_api_gateway_method_response" "get_user" {
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  resource_id = aws_api_gateway_resource.get_user.id
  http_method = aws_api_gateway_method.get_user.http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration" "get_user" {
  rest_api_id             = aws_api_gateway_rest_api.rest_api.id
  resource_id             = aws_api_gateway_resource.get_user.id
  http_method             = aws_api_gateway_method.get_user.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.get_user.invoke_arn  // Lambda ARN
  credentials             = aws_iam_role.iam_for_api_gateway.arn
}

resource "aws_api_gateway_integration_response" "get_user" {
  depends_on = [
    "aws_api_gateway_integration.get_user"
  ]

  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  resource_id = aws_api_gateway_resource.get_user.id
  http_method = aws_api_gateway_method.get_user.http_method
  status_code = aws_api_gateway_method_response.get_user.status_code

  response_parameters ={
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS,POST,PUT'",
    "method.response.header.Access-Control-Allow-Origin" = "'*'"
  }
}

# ======================
# API: put_user
# ======================

resource "aws_api_gateway_resource" "put_user" {
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  parent_id   = aws_api_gateway_rest_api.rest_api.root_resource_id
  path_part   = "put_user"
}

resource "aws_api_gateway_method" "put_user" {
  rest_api_id      = aws_api_gateway_rest_api.rest_api.id
  resource_id      = aws_api_gateway_resource.put_user.id
  http_method      = "POST"
  authorization    = "NONE"
  api_key_required = true  // Use API Key 
}

resource "aws_api_gateway_method_response" "put_user" {
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  resource_id = aws_api_gateway_resource.put_user.id
  http_method = aws_api_gateway_method.put_user.http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration" "put_user" {
  rest_api_id             = aws_api_gateway_rest_api.rest_api.id
  resource_id             = aws_api_gateway_resource.put_user.id
  http_method             = aws_api_gateway_method.put_user.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.put_user.invoke_arn  // Lambda ARN
  credentials             = aws_iam_role.iam_for_api_gateway.arn
}

resource "aws_api_gateway_integration_response" "put_user" {
  depends_on = [
    "aws_api_gateway_integration.put_user"
  ]

  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  resource_id = aws_api_gateway_resource.put_user.id
  http_method = aws_api_gateway_method.put_user.http_method
  status_code = aws_api_gateway_method_response.put_user.status_code

  response_parameters ={
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS,POST,PUT'",
    "method.response.header.Access-Control-Allow-Origin" = "'*'"
  }
}

# ======================
# Deployment
# ======================

resource "aws_api_gateway_deployment" "deployment" {
  rest_api_id = aws_api_gateway_rest_api.rest_api.id

  depends_on = [
    aws_api_gateway_integration.get_user
  ]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "stg" {
  stage_name    = "stg"
  rest_api_id   = aws_api_gateway_rest_api.rest_api.id
  deployment_id = aws_api_gateway_deployment.deployment.id
}

# ======================
# API Key
# ======================

resource "aws_api_gateway_usage_plan" "usage_plan" {
  name = "terraform_example_usage_plan"

  api_stages {
    api_id = aws_api_gateway_rest_api.rest_api.id
    stage  = aws_api_gateway_stage.stg.stage_name
  }
}

resource "aws_api_gateway_api_key" "api_key" {
  name = "terraform_example_api_key"
}

resource "aws_api_gateway_usage_plan_key" "main" {
  key_id        = aws_api_gateway_api_key.api_key.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.usage_plan.id
}
