resource "aws_api_gateway_rest_api" "api_linpe" {
  name = "api-linpe-${terraform.workspace}"
  tags = merge(var.tags, { enviroment = terraform.workspace })
  binary_media_types = ["multipart/form-data"]
}

resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.api_linpe.id
  parent_id   = aws_api_gateway_rest_api.api_linpe.root_resource_id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "proxyMethod" {
  rest_api_id   = aws_api_gateway_rest_api.api_linpe.id
  resource_id   = aws_api_gateway_resource.proxy.id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda" {
  rest_api_id             = aws_api_gateway_rest_api.api_linpe.id
  resource_id             = aws_api_gateway_method.proxyMethod.resource_id
  http_method             = aws_api_gateway_method.proxyMethod.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.lambda_backend.invoke_arn
}

resource "aws_api_gateway_deployment" "apideploy" {
  depends_on = [
    aws_api_gateway_integration.lambda,
  ]
  rest_api_id = aws_api_gateway_rest_api.api_linpe.id
  stage_name  = terraform.workspace
}
