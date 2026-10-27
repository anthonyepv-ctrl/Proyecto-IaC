locals {
  name = "${var.project}-${var.environment}"

  common_tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  }

  # Zonas de disponibilidad
  az_a = var.availability_zones[0]
  az_b = var.availability_zones[1]

  # Nombres estandarizados de subredes
  subnet_name_app_a = "${local.name}-subnet-app-a"
  subnet_name_app_b = "${local.name}-subnet-app-b"
  subnet_name_db_a  = "${local.name}-subnet-db-a"
  subnet_name_db_b  = "${local.name}-subnet-db-b"
}
