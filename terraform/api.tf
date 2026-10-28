resource "aws_api_gateway_rest_api" "this" {
  name        = "${local.name}-api"
  description = "API REST del MVP TuCochera"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_resource" "api" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_rest_api.this.root_resource_id
  path_part   = "api"
}

resource "aws_api_gateway_resource" "sedes" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_resource.api.id
  path_part   = "sedes"
}

resource "aws_api_gateway_resource" "disponibilidad" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_resource.api.id
  path_part   = "disponibilidad"
}

resource "aws_api_gateway_resource" "reservas" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_resource.api.id
  path_part   = "reservas"
}

resource "aws_api_gateway_method" "sedes_get" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = aws_api_gateway_resource.sedes.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "disponibilidad_get" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = aws_api_gateway_resource.disponibilidad.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "reservas_post" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = aws_api_gateway_resource.reservas.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "sedes_get" {
  rest_api_id             = aws_api_gateway_rest_api.this.id
  resource_id             = aws_api_gateway_resource.sedes.id
  http_method             = aws_api_gateway_method.sedes_get.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.disponibilidad.invoke_arn
}

resource "aws_api_gateway_integration" "disponibilidad_get" {
  rest_api_id             = aws_api_gateway_rest_api.this.id
  resource_id             = aws_api_gateway_resource.disponibilidad.id
  http_method             = aws_api_gateway_method.disponibilidad_get.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.disponibilidad.invoke_arn
}

resource "aws_api_gateway_integration" "reservas_post" {
  rest_api_id             = aws_api_gateway_rest_api.this.id
  resource_id             = aws_api_gateway_resource.reservas.id
  http_method             = aws_api_gateway_method.reservas_post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.registrar.invoke_arn
}

resource "aws_lambda_permission" "api_disponibilidad" {
  statement_id  = "AllowAPIGatewayInvokeDisponibilidad"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.disponibilidad.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.this.execution_arn}/*/*"
}

resource "aws_lambda_permission" "api_registrar" {
  statement_id  = "AllowAPIGatewayInvokeRegistrar"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.registrar.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.this.execution_arn}/*/*"
}

resource "aws_api_gateway_deployment" "this" {
  rest_api_id = aws_api_gateway_rest_api.this.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.api.id,
      aws_api_gateway_resource.sedes.id,
      aws_api_gateway_resource.disponibilidad.id,
      aws_api_gateway_resource.reservas.id,
      aws_api_gateway_method.sedes_get.id,
      aws_api_gateway_method.disponibilidad_get.id,
      aws_api_gateway_method.reservas_post.id,
      aws_api_gateway_integration.sedes_get.id,
      aws_api_gateway_integration.disponibilidad_get.id,
      aws_api_gateway_integration.reservas_post.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "this" {
  deployment_id = aws_api_gateway_deployment.this.id
  rest_api_id   = aws_api_gateway_rest_api.this.id
  stage_name    = var.environment
}

resource "aws_api_gateway_method_settings" "this" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  stage_name  = aws_api_gateway_stage.this.stage_name
  method_path = "*/*"

  settings {
    throttling_rate_limit  = var.api_throttle_rate_limit
    throttling_burst_limit = var.api_throttle_burst_limit
  }

  depends_on = [
    aws_api_gateway_method.sedes_get,
    aws_api_gateway_method.disponibilidad_get,
    aws_api_gateway_method.reservas_post,
  ]
}

output "api_invoke_url" {
  description = "URL base del stage de API Gateway"
  value       = aws_api_gateway_stage.this.invoke_url
}
