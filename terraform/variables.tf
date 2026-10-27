variable "project" {
  description = "Nombre del proyecto"
  type        = string
  default     = "tucochera"
}

variable "environment" {
  description = "Entorno de despliegue (dev, qa, prod)"
  type        = string
  default     = "dev"
}

variable "aws_region" {
  description = "Región de AWS donde se despliega la infraestructura"
  type        = string
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "Perfil de AWS CLI configurado para autenticación"
  type        = string
  default     = "default"
}


variable "vpc_cidr" {
  description = "Bloque CIDR principal de la VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Zonas de disponibilidad para distribuir las subredes"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "subnet_cidr_app_a" {
  description = "Bloque CIDR para la subred privada de aplicación en AZ a"
  type        = string
  default     = "10.0.1.0/24"
}

variable "subnet_cidr_app_b" {
  description = "Bloque CIDR para la subred privada de aplicación en AZ b"
  type        = string
  default     = "10.0.2.0/24"
}

variable "subnet_cidr_db_a" {
  description = "Bloque CIDR para la subred privada de base de datos en AZ a"
  type        = string
  default     = "10.0.3.0/24"
}

variable "subnet_cidr_db_b" {
  description = "Bloque CIDR para la subred privada de base de datos en AZ b"
  type        = string
  default     = "10.0.4.0/24"
}

variable "db_name" {
  description = "Nombre de la base de datos inicial en PostgreSQL"
  type        = string
  default     = "tucochera"
}

variable "db_username" {
  description = "Nombre del usuario administrador de la base de datos"
  type        = string
  default     = "tucochera_admin"
}

variable "db_instance_class" {
  description = "Tipo de instancia para la base de datos RDS"
  type        = string
  default     = "db.t4g.micro"
}

variable "db_allocated_storage" {
  description = "Almacenamiento asignado en GB para la base de datos RDS"
  type        = number
  default     = 20
}

variable "lambda_runtime" {
  description = "Runtime utilizado para las funciones Lambda"
  type        = string
  default     = "python3.12"
}

variable "lambda_memory_size" {
  description = "Memoria asignada a las funciones Lambda en MB"
  type        = number
  default     = 256
}

variable "lambda_timeout" {
  description = "Tiempo máximo de ejecución para las funciones Lambda en segundos"
  type        = number
  default     = 15
}

variable "log_retention_days" {
  description = "Días de retención para los grupos de logs en CloudWatch"
  type        = number
  default     = 7
}

variable "api_throttle_rate_limit" {
  description = "Límite de solicitudes por segundo (rate limit) en API Gateway"
  type        = number
  default     = 100
}

variable "api_throttle_burst_limit" {
  description = "Límite de ráfaga (burst limit) en API Gateway"
  type        = number
  default     = 200
}
