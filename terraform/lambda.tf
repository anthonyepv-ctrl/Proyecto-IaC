variable "lambda_reserved_concurrency" {
  description = "Concurrencia reservada por funcion. Usar -1 para no reservar (cuentas nuevas con cuota 10)."
  type        = number
  default     = 10
}

locals {
  lambda_env = {
    DB_HOST     = aws_db_instance.this.address
    DB_PORT     = tostring(aws_db_instance.this.port)
    DB_NAME     = var.db_name
    DB_USER     = var.db_username
    DB_PASSWORD = random_password.db.result
  }
}

resource "aws_cloudwatch_log_group" "disponibilidad" {
  name              = "/aws/lambda/${local.name}-disponibilidad"
  retention_in_days = var.log_retention_days
  tags              = local.common_tags
}

resource "aws_cloudwatch_log_group" "registrar" {
  name              = "/aws/lambda/${local.name}-registrar"
  retention_in_days = var.log_retention_days
  tags              = local.common_tags
}

resource "aws_cloudwatch_log_group" "expandir" {
  name              = "/aws/lambda/${local.name}-expandir"
  retention_in_days = var.log_retention_days
  tags              = local.common_tags
}

resource "aws_cloudwatch_log_group" "db_init" {
  name              = "/aws/lambda/${local.name}-db-init"
  retention_in_days = var.log_retention_days
  tags              = local.common_tags
}

resource "aws_lambda_function" "disponibilidad" {
  function_name = "${local.name}-disponibilidad"
  role          = aws_iam_role.lambda.arn
  runtime       = var.lambda_runtime
  handler       = "handler.lambda_handler"
  timeout       = var.lambda_timeout
  memory_size   = var.lambda_memory_size

  filename         = "${path.module}/../build/disponibilidad.zip"
  source_code_hash = filebase64sha256("${path.module}/../build/disponibilidad.zip")

  reserved_concurrent_executions = var.lambda_reserved_concurrency

  vpc_config {
    subnet_ids         = [aws_subnet.app_a.id]
    security_group_ids = [aws_security_group.lambda.id]
  }

  environment {
    variables = local.lambda_env
  }

  tags = local.common_tags

  depends_on = [
    aws_cloudwatch_log_group.disponibilidad,
    aws_iam_role_policy_attachment.lambda_vpc,
  ]
}

resource "aws_lambda_function" "registrar" {
  function_name = "${local.name}-registrar"
  role          = aws_iam_role.lambda.arn
  runtime       = var.lambda_runtime
  handler       = "handler.lambda_handler"
  timeout       = var.lambda_timeout
  memory_size   = var.lambda_memory_size

  filename         = "${path.module}/../build/registrar.zip"
  source_code_hash = filebase64sha256("${path.module}/../build/registrar.zip")

  reserved_concurrent_executions = var.lambda_reserved_concurrency

  vpc_config {
    subnet_ids         = [aws_subnet.app_a.id]
    security_group_ids = [aws_security_group.lambda.id]
  }

  environment {
    variables = local.lambda_env
  }

  tags = local.common_tags

  depends_on = [
    aws_cloudwatch_log_group.registrar,
    aws_iam_role_policy_attachment.lambda_vpc,
  ]
}

resource "aws_lambda_function" "expandir" {
  function_name = "${local.name}-expandir"
  role          = aws_iam_role.lambda.arn
  runtime       = var.lambda_runtime
  handler       = "handler.lambda_handler"
  timeout       = var.lambda_timeout
  memory_size   = var.lambda_memory_size

  filename         = "${path.module}/../build/expandir.zip"
  source_code_hash = filebase64sha256("${path.module}/../build/expandir.zip")

  reserved_concurrent_executions = var.lambda_reserved_concurrency

  vpc_config {
    subnet_ids         = [aws_subnet.app_a.id]
    security_group_ids = [aws_security_group.lambda.id]
  }

  environment {
    variables = local.lambda_env
  }

  tags = local.common_tags

  depends_on = [
    aws_cloudwatch_log_group.expandir,
    aws_iam_role_policy_attachment.lambda_vpc,
  ]
}

resource "aws_lambda_function" "db_init" {
  function_name = "${local.name}-db-init"
  role          = aws_iam_role.lambda.arn
  runtime       = var.lambda_runtime
  handler       = "handler.lambda_handler"
  timeout       = var.lambda_timeout
  memory_size   = var.lambda_memory_size

  filename         = "${path.module}/../build/db_init.zip"
  source_code_hash = filebase64sha256("${path.module}/../build/db_init.zip")

  reserved_concurrent_executions = var.lambda_reserved_concurrency

  vpc_config {
    subnet_ids         = [aws_subnet.app_a.id]
    security_group_ids = [aws_security_group.lambda.id]
  }

  environment {
    variables = local.lambda_env
  }

  tags = local.common_tags

  depends_on = [
    aws_cloudwatch_log_group.db_init,
    aws_iam_role_policy_attachment.lambda_vpc,
  ]
}

output "lambda_function_names" {
  value = {
    disponibilidad = aws_lambda_function.disponibilidad.function_name
    registrar      = aws_lambda_function.registrar.function_name
    expandir       = aws_lambda_function.expandir.function_name
    db_init        = aws_lambda_function.db_init.function_name
  }
}