variable "aws_region" {
  description = "AWS región donde se despliegua la infraestructura"
  type        = string
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "AWS profile IAM Identity Center para desplegar la infraestructura"
  type        = string
  default     = "admin"
}