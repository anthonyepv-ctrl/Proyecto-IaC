resource "aws_security_group" "lambda" {
  name        = "${local.name}-lambda-sg"
  description = "Security group para funciones Lambda (acceso interno a RDS)"
  vpc_id      = aws_vpc.this.id

  tags = {
    Name = "${local.name}-lambda-sg"
  }
}

resource "aws_security_group" "rds" {
  name        = "${local.name}-rds-sg"
  description = "Security group para RDS PostgreSQL (solo trafico desde Lambda)"
  vpc_id      = aws_vpc.this.id

  tags = {
    Name = "${local.name}-rds-sg"
  }
}

resource "aws_vpc_security_group_egress_rule" "lambda_to_rds" {
  security_group_id            = aws_security_group.lambda.id
  referenced_security_group_id = aws_security_group.rds.id
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
  description                  = "Salida permitida hacia RDS PostgreSQL en puerto 5432"
}

resource "aws_vpc_security_group_ingress_rule" "rds_from_lambda" {
  security_group_id            = aws_security_group.rds.id
  referenced_security_group_id = aws_security_group.lambda.id
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
  description                  = "Entrada permitida desde funciones Lambda en puerto 5432"
}

output "security_group_lambda_id" {
  description = "ID del Security Group asignado a las funciones Lambda"
  value       = aws_security_group.lambda.id
}

output "security_group_rds_id" {
  description = "ID del Security Group asignado a la base de datos RDS"
  value       = aws_security_group.rds.id
}
