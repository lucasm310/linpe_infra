output "nameserver" {
  value = data.aws_route53_zone.primary.name_servers
}

output "cognito_user_pool_id" {
  value = aws_cognito_user_pool.linpe.id
}

output "cognito_user_pool_client_id" {
  value = aws_cognito_user_pool_client.linpe_client_web.id
}

output "cognito_identiy_id" {
  value = aws_cognito_identity_pool.linpe_identity_pool.id
}

output "cognito_domain" {
  value = aws_cognito_user_pool.linpe.domain
}

output "ecr" {
  value = aws_ecr_repository.linpe_ecr.repository_url
}

output "api_base_url" {
  value = aws_api_gateway_deployment.apideploy.invoke_url
}

output "cloudfront_site" {
  value = aws_cloudfront_distribution.site.domain_name
}

output "cloudfront_app" {
  value = aws_cloudfront_distribution.app.domain_name
}
