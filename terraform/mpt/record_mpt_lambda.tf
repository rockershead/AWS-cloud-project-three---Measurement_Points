resource "aws_lambda_function" "record_lambda" {
  filename         = "${abspath(path.module)}/../../lambdas/record_mpt/${var.record_lambda_zip_filename}"
  source_code_hash = filebase64sha256("${abspath(path.module)}/../../lambdas/record_mpt/${var.record_lambda_zip_filename}")
  role             = aws_iam_role.record_mpt_lambda_role.arn
  function_name    = var.record_lambda_function_name
  handler          = "record_mpt.lambda_handler" ##change sample_project_lambda according to the python file name
  runtime          = "python3.10"
  timeout          = 30

  description = "Lambda to record measurement points"

  vpc_config {
    security_group_ids = [aws_security_group.security_group.id]
    subnet_ids         = tolist(aws_subnet.private_subnets[*].id)
  }

  environment {
    variables = {
      TABLE_NAME = var.mpt_table_name


    }
  }




  depends_on = [
    aws_iam_role.record_mpt_lambda_role,
    aws_vpc.main,
    aws_subnet.private_subnets,
    aws_security_group.security_group
  ]
}

resource "aws_iam_role" "record_mpt_lambda_role" {
  name               = "${var.record_lambda_function_name}_role"
  description        = "Lambda execution role for ${var.record_lambda_function_name}"
  assume_role_policy = data.aws_iam_policy_document.assume_record_mpt_lambda_role.json

  inline_policy {
    name   = "record_mpt_lambda_role_policy"
    policy = data.aws_iam_policy_document.record_mpt_lambda_role_permissions.json
  }
}

data "aws_iam_policy_document" "assume_record_mpt_lambda_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "record_mpt_lambda_role_permissions" {

  ##dynamodb

  statement {
    actions = [
      "dynamodb:PutItem",

    ]
    resources = ["arn:aws:dynamodb:ap-southeast-1:${data.aws_caller_identity.current_caller_for_record_mpt_lambda.account_id}:table/${var.mpt_table_name}"]
    effect    = "Allow"
  }





  # Permissions required for lambda to execute in VPC
  statement {
    actions = [
      "ec2:CreateNetworkInterface",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DeleteNetworkInterface"
    ]
    resources = ["*"]
    effect    = "Allow"
  }

  #Cloudwatch Logs permission required for Lambda
  statement {
    actions = [
      "logs:CreateLogGroup"
    ]
    resources = [
      "arn:aws:logs:ap-southeast-1:${data.aws_caller_identity.current_caller_for_record_mpt_lambda.account_id}:*"
    ]
    effect = "Allow"
  }

  statement {
    actions = [
      "logs:CreateLogStream"
    ]
    resources = [
      "arn:aws:logs:ap-southeast-1:${data.aws_caller_identity.current_caller_for_record_mpt_lambda.account_id}:log-group:/aws/lambda/${var.record_lambda_function_name}:*"
    ]
    effect = "Allow"
  }
  statement {
    actions = [
      "logs:PutLogEvents"
    ]
    resources = [
      "arn:aws:logs:ap-southeast-1:${data.aws_caller_identity.current_caller_for_record_mpt_lambda.account_id}:log-group:/aws/lambda/${var.record_lambda_function_name}:log-stream:*"
    ]
    effect = "Allow"
  }


}
