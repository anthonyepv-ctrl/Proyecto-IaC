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

resource "aws_api_gateway_resource" "reserva_id" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_resource.reservas.id
  path_part   = "{id}"
}

resource "aws_api_gateway_resource" "expandir" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_resource.reserva_id.id
  path_part   = "expandir"
}

resource "aws_api_gateway_deployment" "this" {
  rest_api_id = aws_api_gateway_rest_api.this.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.api.id,
      aws_api_gateway_resource.sedes.id,
      aws_api_gateway_resource.disponibilidad.id,
      aws_api_gateway_resource.reservas.id,
      aws_api_gateway_resource.reserva_id.id,
      aws_api_gateway_resource.expandir.id,
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

output "api_invoke_url" {
  description = "URL base del stage de API Gateway"
  value       = aws_api_gateway_stage.this.invoke_url
}
