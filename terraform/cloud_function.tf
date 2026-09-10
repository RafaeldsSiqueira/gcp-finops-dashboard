# ==============================================================================
# Automação Serverless: Cloud Function Gen 2 + Cloud Scheduler
# ==============================================================================

# 1. Variável para o Webhook do Discord/Slack
variable "discord_webhook_url" {
  description = "URL do Webhook do Discord para envio de notificações de FinOps"
  type        = string
  default     = ""
  sensitive   = true
}

# 2. Compactação do código Python em arquivo ZIP
data "archive_file" "function_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../functions/check_budget"
  output_path = "${path.module}/files/check_budget.zip"
}

# 3. Bucket GCS para armazenar o artefato (.zip) da Cloud Function
resource "google_storage_bucket" "function_bucket" {
  name                        = "${var.project_id}-finops-functions-source"
  location                    = var.region
  uniform_bucket_level_access = true
  force_destroy               = true

  labels = {
    env         = "sandbox"
    cost_center = "finops-core"
    managed_by  = "terraform"
  }

  depends_on = [google_project_service.enabled_services]
}

# 4. Upload do arquivo ZIP para o Bucket
resource "google_storage_bucket_object" "function_archive" {
  name   = "check_budget_${data.archive_file.function_zip.output_md5}.zip"
  bucket = google_storage_bucket.function_bucket.name
  source = data.archive_file.function_zip.output_path
}

# 5. Cloud Function (Gen 2) para Monitoramento FinOps
resource "google_cloudfunctions2_function" "check_budget_function" {
  name        = "finops-budget-watchdog"
  location    = var.region
  description = "Cloud Function serverless que monitora anomalias de faturamento no BigQuery"

  build_config {
    runtime     = "python311"
    entry_point = "check_budget_anomalies"
    source {
      storage_source {
        bucket = google_storage_bucket.function_bucket.name
        object = google_storage_bucket_object.function_archive.name
      }
    }
  }

  service_config {
    max_instance_count               = 1
    min_instance_count               = 0
    available_memory                 = "256M"
    timeout_seconds                  = 60
    service_account_email            = google_service_account.finops_alert_sa.email
    ingress_settings                 = "ALLOW_ALL"
    all_traffic_on_latest_revision   = true

    environment_variables = {
      PROJECT_ID          = var.project_id
      DATASET_ID          = var.dataset_id
      DISCORD_WEBHOOK_URL = var.discord_webhook_url
    }
  }

  labels = {
    env         = "sandbox"
    cost_center = "finops-core"
    managed_by  = "terraform"
  }

  depends_on = [
    google_project_service.enabled_services,
    google_project_iam_member.bq_data_viewer,
    google_project_iam_member.bq_job_user
  ]
}

# 6. Permissão para a Service Account invocar a Cloud Function
resource "google_cloud_run_service_iam_member" "scheduler_invoker" {
  location = google_cloudfunctions2_function.check_budget_function.location
  service  = google_cloudfunctions2_function.check_budget_function.name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${google_service_account.finops_alert_sa.email}"
}

# 7. Cloud Scheduler: Disparo diário às 08:00 UTC
resource "google_cloud_scheduler_job" "daily_finops_check" {
  name        = "finops-daily-budget-trigger"
  description = "Dispara a verificação diária de anomalias de faturamento FinOps"
  schedule    = "0 8 * * *"
  time_zone   = "America/Sao_Paulo"
  region      = var.region

  http_target {
    http_method = "GET"
    uri         = google_cloudfunctions2_function.check_budget_function.service_config[0].uri

    oidc_token {
      service_account_email = google_service_account.finops_alert_sa.email
    }
  }

  depends_on = [
    google_project_service.enabled_services,
    google_cloudfunctions2_function.check_budget_function
  ]
}
