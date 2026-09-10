output "project_id" {
  description = "ID do projeto GCP provisionado"
  value       = var.project_id
}

output "bigquery_dataset_id" {
  description = "ID do dataset do BigQuery criado"
  value       = google_bigquery_dataset.billing_finops.dataset_id
}

output "raw_billing_table" {
  description = "Tabela de dados brutos de faturamento"
  value       = google_bigquery_table.raw_billing.id
}

output "service_account_email" {
  description = "E-mail da Service Account criada para a automação de FinOps"
  value       = google_service_account.finops_alert_sa.email
}

output "view_daily_cost" {
  description = "ID da view de custo diário por serviço"
  value       = google_bigquery_table.v_daily_cost_by_service.id
}

output "view_cost_by_env" {
  description = "ID da view de custos por ambiente e governança"
  value       = google_bigquery_table.v_cost_by_project_and_env.id
}

output "view_anomalies" {
  description = "ID da view de detecção de anomalias de custo"
  value       = google_bigquery_table.v_cost_anomalies_detection.id
}
