resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${local.name}-vpc"
  }
}

resource "aws_subnet" "app_a" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.subnet_cidr_app_a
  availability_zone = local.az_a

  tags = {
    Name = local.subnet_name_app_a
    Tier = "application"
  }
}

resource "aws_subnet" "app_b" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.subnet_cidr_app_b
  availability_zone = local.az_b

  tags = {
    Name = local.subnet_name_app_b
    Tier = "application"
  }
}

resource "aws_subnet" "db_a" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.subnet_cidr_db_a
  availability_zone = local.az_a

  tags = {
    Name = local.subnet_name_db_a
    Tier = "database"
  }
}

resource "aws_subnet" "db_b" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.subnet_cidr_db_b
  availability_zone = local.az_b

  tags = {
    Name = local.subnet_name_db_b
    Tier = "database"
  }
}

resource "aws_route_table" "app" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${local.name}-rt-app"
    Tier = "application"
  }
}

resource "aws_route_table" "db" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${local.name}-rt-db"
    Tier = "database"
  }
}

resource "aws_route_table_association" "app_a" {
  subnet_id      = aws_subnet.app_a.id
  route_table_id = aws_route_table.app.id
}

resource "aws_route_table_association" "app_b" {
  subnet_id      = aws_subnet.app_b.id
  route_table_id = aws_route_table.app.id
}

resource "aws_route_table_association" "db_a" {
  subnet_id      = aws_subnet.db_a.id
  route_table_id = aws_route_table.db.id
}

resource "aws_route_table_association" "db_b" {
  subnet_id      = aws_subnet.db_b.id
  route_table_id = aws_route_table.db.id
}

output "vpc_id" {
  description = "ID de la VPC creada"
  value       = aws_vpc.this.id
}

output "subnet_app_a_id" {
  description = "ID de la subred privada de aplicación en AZ a"
  value       = aws_subnet.app_a.id
}

output "subnet_app_b_id" {
  description = "ID de la subred privada de aplicación en AZ b"
  value       = aws_subnet.app_b.id
}

output "subnet_db_a_id" {
  description = "ID de la subred privada de base de datos en AZ a"
  value       = aws_subnet.db_a.id
}

output "subnet_db_b_id" {
  description = "ID de la subred privada de base de datos en AZ b"
  value       = aws_subnet.db_b.id
}
