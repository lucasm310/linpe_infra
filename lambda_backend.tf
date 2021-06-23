resource "aws_iam_role" "lambda_backend_exec_role" {
  name               = "linpe_lambda_backend_exec_role-${terraform.workspace}"
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

data "aws_iam_policy_document" "lambda_backend_policy_doc" {
  statement {
    sid    = "AllowDynamoDB"
    effect = "Allow"
    resources = [
      aws_dynamodb_table.table_documentos.arn,
      aws_dynamodb_table.table_eventos.arn,
      aws_dynamodb_table.table_noticias.arn
    ]
    actions = [
      "dynamodb:BatchGet*",
      "dynamodb:DescribeStream",
      "dynamodb:DescribeTable",
      "dynamodb:Get*",
      "dynamodb:Query",
      "dynamodb:Scan",
      "dynamodb:BatchWrite*",
      "dynamodb:CreateTable",
      "dynamodb:Delete*",
      "dynamodb:Update*",
      "dynamodb:PutItem"
    ]
  }

  statement {
    sid    = "AllowS3"
    effect = "Allow"
    resources = [
      "${aws_s3_bucket.bucket_linpe_documentos.arn}/*"
    ]
    actions = [
      "s3:*"
    ]
  }

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

resource "aws_iam_policy" "lambda_backend_iam_policy" {
  tags   = merge(var.tags, { enviroment = terraform.workspace })
  name   = "linpe_backend_lambda-${terraform.workspace}"
  policy = data.aws_iam_policy_document.lambda_backend_policy_doc.json
}

resource "aws_iam_role_policy_attachment" "lambda_backend_policy_attachment" {
  policy_arn = aws_iam_policy.lambda_backend_iam_policy.arn
  role       = aws_iam_role.lambda_backend_exec_role.name
}

resource "aws_lambda_function" "lambda_backend" {
  function_name = "linpe_api_backend-${terraform.workspace}"
  description   = "API LINPE BACKEND"
  role          = aws_iam_role.lambda_backend_exec_role.arn
  memory_size   = 128
  timeout       = 300
  tags          = merge(var.tags, { enviroment = terraform.workspace })
  package_type  = "Image"
  image_uri     = "${aws_ecr_repository.linpe_ecr.repository_url}:latest"
  environment {
    variables = {
      USERPOOL_ID       = aws_cognito_user_pool.linpe.id
      CLIENT_ID         = aws_cognito_user_pool_client.linpe_client_web.id
      DOCUMENTOS_TABLE  = aws_dynamodb_table.table_documentos.name
      EVENTOS_TABLE     = aws_dynamodb_table.table_eventos.name
      NOTICIAS_TABLE    = aws_dynamodb_table.table_noticias.name
      DOCUMENTOS_BUCKET = aws_s3_bucket.bucket_linpe_documentos.id
    }
  }
}

resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_backend.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api_linpe.execution_arn}/*/*"
}
