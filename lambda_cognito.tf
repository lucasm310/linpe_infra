resource "aws_iam_role" "lambda_cognito_exec_role" {
  name               = "lambda_cognito_exec_role-${terraform.workspace}"
  tags               = merge(var.tags, { enviroment = terraform.workspace })
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      }
    }
  ]
}
EOF
}

data "aws_iam_policy_document" "lambda_cognito_policy_doc" {
  statement {
    sid    = "AllowCognito"
    effect = "Allow"
    resources = [
      aws_cognito_user_pool.linpe.arn
    ]
    actions = [
      "cognito-sync:*",
      "cognito-idp:*",
    ]
  }

  statement {
    sid    = "AllowCreatingLogGroups"
    effect = "Allow"
    resources = [
      "arn:aws:logs:*:*:*"
    ]
    actions = [
      "logs:CreateLogGroup"
    ]
  }

  statement {
    sid    = "AllowWritingLogs"
    effect = "Allow"
    resources = [
      "arn:aws:logs:*:*:log-group:/aws/lambda/*:*"
    ]
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
  }
}

resource "aws_iam_policy" "lambda_cognito_iam_policy" {
  tags   = merge(var.tags, { enviroment = terraform.workspace })
  name   = "aws_cognito_user_pool-${terraform.workspace}"
  policy = data.aws_iam_policy_document.lambda_cognito_policy_doc.json
}

resource "aws_iam_role_policy_attachment" "lambda_cognito_policy_attachment" {
  policy_arn = aws_iam_policy.lambda_cognito_iam_policy.arn
  role       = aws_iam_role.lambda_cognito_exec_role.name
}

data "archive_file" "lambda_cognito_pkg" {
  source_dir  = "${path.cwd}/cognito_lambda/"
  output_path = "${path.cwd}/cognito_lambda.zip"
  type        = "zip"
}

resource "aws_lambda_function" "lambda_cognito" {
  function_name    = "cognito_update_group-${terraform.workspace}"
  description      = "Update default group"
  handler          = "main.lambda_handler"
  runtime          = "python3.8"
  role             = aws_iam_role.lambda_cognito_exec_role.arn
  memory_size      = 128
  timeout          = 300
  source_code_hash = data.archive_file.lambda_cognito_pkg.output_base64sha256
  filename         = data.archive_file.lambda_cognito_pkg.output_path
  tags             = merge(var.tags, { enviroment = terraform.workspace })
}

resource "aws_lambda_permission" "allow_cognito" {
  function_name = aws_lambda_function.lambda_cognito.arn
  source_arn    = aws_cognito_user_pool.linpe.arn
  statement_id  = "AllowExecutionFromCognito"
  action        = "lambda:InvokeFunction"
  principal     = "cognito-idp.amazonaws.com"
}
