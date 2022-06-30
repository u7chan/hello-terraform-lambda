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
      identifiers = ["lambda.amazonaws.com"]
      type        = "Service"
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "iam_for_lambda" {
  name               = "terraform-iam-for-lambda"
  assume_role_policy = data.aws_iam_policy_document.policy.json
}

# ===============================================
# Policy
# ===============================================

resource "aws_iam_policy" "policy" {
  name   = "terraform-iam-for-allow-policy"
  policy = "${file("allow-policy.json")}"
}

resource "aws_iam_policy_attachment" "attach" {
  name       = "terraform-iam-policy-attachment"
  roles      = ["${aws_iam_role.iam_for_lambda.name}"]
  policy_arn = "${aws_iam_policy.policy.arn}"
}

# ===============================================
# Lambda
# ===============================================

resource "aws_lambda_function" "lambda-1" {
  function_name = "terrform-getUser"

  filename         = "dist/index.zip"
  source_code_hash = filemd5("dist/index.zip")

  role    = aws_iam_role.iam_for_lambda.arn
  handler = "index.getUser"
  runtime = "nodejs16.x"
}

resource "aws_lambda_function" "lambda-2" {
  function_name = "terrform-putUser"

  filename         = "dist/index.zip"
  source_code_hash = filemd5("dist/index.zip")

  role    = aws_iam_role.iam_for_lambda.arn
  handler = "index.putUser"
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
