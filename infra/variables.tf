variable "aws_region" {
  description = "Região da AWS"
  default     = "us-east-1"
}

variable "bucket_name" {
  description = "Nome do bucket S3"
  default     = "fitce-bucket-deploy"
}

variable "developer_role_name" {
  description = "Nome da Role IAM para Desenvolvedores"
  default     = "DeveloperRole"
}

variable "devops_role_name" {
  description = "Nome da Role IAM para DevOps"
  default     = "DevOpsRole"
}

variable "automation_role_name" {
  description = "Nome da Role IAM para Automação"
  default     = "AutomationRole"
}
