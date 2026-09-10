# ==============================================================================
# Gerenciamento de Identidade e Acessos (IAM) - Princípio do Menor Privilégio
# ==============================================================================

# 1. Service Account dedicada para a Cloud Function de monitoramento FinOps
resource "google_service_account" "finops_alert_sa" {
  account_id   = "sa-finops-budget-alert"
  display_name = "FinOps Budget Alert Service Account"
  description  = "Identidade de serviço restrita para leitura do BigQuery e disparo de alertas FinOps"
}

# 2. Papel de Leitura de Dados no BigQuery (roles/bigquery.dataViewer)
resource "google_project_iam_member" "bq_data_viewer" {
  project = var.project_id
  role    = "roles/bigquery.dataViewer"
  member  = "serviceAccount:${google_service_account.finops_alert_sa.email}"
}

# 3. Papel de Execução de Consultas no BigQuery (roles/bigquery.jobUser)
resource "google_project_iam_member" "bq_job_user" {
  project = var.project_id
  role    = "roles/bigquery.jobUser"
  member  = "serviceAccount:${google_service_account.finops_alert_sa.email}"
}
