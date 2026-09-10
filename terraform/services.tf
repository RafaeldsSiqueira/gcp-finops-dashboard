# ==============================================================================
# Habilitação das APIs do GCP necessárias para o ecossistema FinOps
# ==============================================================================

locals {
  services = [
    "bigquery.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "iam.googleapis.com",
    "cloudfunctions.googleapis.com",
    "cloudscheduler.googleapis.com",
    "cloudbuild.googleapis.com"
  ]
}

resource "google_project_service" "enabled_services" {
  for_each = toset(locals.services)

  project = var.project_id
  service = each.key

  disable_on_destroy         = false
  disable_dependent_services = false
}
