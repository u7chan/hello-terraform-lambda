terraform {
  required_version = ">= 0.12"
}

provider "aws" {
  region = var.aws_region
}

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
  name               = "terraform_iam_for_lambda"
  assume_role_policy = data.aws_iam_policy_document.policy.json
}

resource "aws_lambda_function" "lambda" {
  function_name = "hello_lambda"

  filename         = "dist/index.zip"
  source_code_hash = filemd5("dist/index.zip")

  role    = aws_iam_role.iam_for_lambda.arn
  handler = "index.handler"
  runtime = "nodejs16.x"

  environment {
    variables = {
      greeting = "Hello terraform !!"
    }
  }
}

