variable "aws_region" {
  description = "Região da AWS"
  default     = "sa-east-1"
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

variable "dev_instance_id" {
  description = "ID da instância EC2 existente para o ambiente de desenvolvimento"
  type        = string
  default     = "i-0d68192179734aa89"
}

variable "hom_instance_id" {
  description = "ID da instância EC2 existente para o ambiente de homologação"
  type        = string
  default     = "i-0d68192179734aa89"
}

variable "prod_instance_id" {
  description = "ID da instância EC2 existente para o ambiente de produção"
  type        = string
  default     = "i-0d68192179734aa89"
}