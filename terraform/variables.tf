variable "project_id" {
  description = "O ID do projeto GCP onde a infraestrutura será criada"
  type        = string
}

variable "region" {
  description = "Região padrão para os recursos do GCP"
  type        = string
  default     = "us-central1"
}

variable "dataset_id" {
  description = "Nome do dataset do BigQuery para armazenar os dados de FinOps"
  type        = string
  default     = "billing_finops"
}

variable "dataset_location" {
  description = "Localização geográfica do dataset do BigQuery"
  type        = string
  default     = "US"
}
