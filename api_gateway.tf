resource "aws_api_gateway_rest_api" "api_linpe" {
  name               = "api-linpe-${terraform.workspace}"
  tags               = merge(var.tags, { enviroment = terraform.workspace })
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

#enable cors
resource "aws_api_gateway_method" "cors" {
  rest_api_id   = aws_api_gateway_rest_api.api_linpe.id
  resource_id   = aws_api_gateway_resource.proxy.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "cors" {
  rest_api_id = aws_api_gateway_rest_api.api_linpe.id
  resource_id = aws_api_gateway_resource.proxy.id
  http_method = aws_api_gateway_method.cors.http_method
  type        = "MOCK"
}

resource "aws_api_gateway_method_response" "cors" {
  depends_on  = [aws_api_gateway_method.cors]
  rest_api_id = aws_api_gateway_rest_api.api_linpe.id
  resource_id = aws_api_gateway_resource.proxy.id
  http_method = aws_api_gateway_method.cors.http_method
  status_code = 200
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"  = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Headers" = true
  }
  response_models = {
    "application/json"    = "Empty",
    "multipart/form-data" = "Empty"
  }
}

resource "aws_api_gateway_integration_response" "cors" {
  depends_on  = [aws_api_gateway_integration.cors, aws_api_gateway_method_response.cors]
  rest_api_id = aws_api_gateway_rest_api.api_linpe.id
  resource_id = aws_api_gateway_resource.proxy.id
  http_method = aws_api_gateway_method.cors.http_method
  status_code = 200
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"  = "'*'",
    "method.response.header.Access-Control-Allow-Headers" = "'*'",
    "method.response.header.Access-Control-Allow-Methods" = "'DELETE,GET,HEAD,OPTIONS,PATCH,POST,PUT'"
  }
}
