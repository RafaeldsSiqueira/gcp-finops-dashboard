# ==============================================================================
# Dataset e Tabelas do BigQuery para o pipeline de FinOps
# ==============================================================================

# 1. Dataset dedicado para faturamento e FinOps
resource "google_bigquery_dataset" "billing_finops" {
  dataset_id                  = var.dataset_id
  friendly_name               = "FinOps & Billing Analytics"
  description                 = "Dataset analítico central para faturamento e governança de custos no GCP"
  location                    = var.dataset_location
  delete_contents_on_destroy  = true

  labels = {
    env         = "sandbox"
    cost_center = "finops-core"
    managed_by  = "terraform"
  }

  depends_on = [google_project_service.enabled_services]
}

# 2. Tabela de exportação de faturamento (schema oficial do GCP) particionada por dia
resource "google_bigquery_table" "raw_billing" {
  dataset_id          = google_bigquery_dataset.billing_finops.dataset_id
  table_id            = "gcp_billing_export_resource_v1_01ABCD_2345EF_6789GH"
  description         = "Tabela particionada de dados detalhados de faturamento do GCP a nível de recurso"
  deletion_protection = false

  time_partitioning {
    type  = "DAY"
    field = "usage_start_time"
  }

  schema = jsonencode([
    { name = "billing_account_id", type = "STRING", mode = "NULLABLE" },
    {
      name = "service",
      type = "RECORD",
      mode = "NULLABLE",
      fields = [
        { name = "id", type = "STRING", mode = "NULLABLE" },
        { name = "description", type = "STRING", mode = "NULLABLE" }
      ]
    },
    {
      name = "sku",
      type = "RECORD",
      mode = "NULLABLE",
      fields = [
        { name = "id", type = "STRING", mode = "NULLABLE" },
        { name = "description", type = "STRING", mode = "NULLABLE" }
      ]
    },
    { name = "usage_start_time", type = "TIMESTAMP", mode = "NULLABLE" },
    { name = "usage_end_time", type = "TIMESTAMP", mode = "NULLABLE" },
    {
      name = "project",
      type = "RECORD",
      mode = "NULLABLE",
      fields = [
        { name = "id", type = "STRING", mode = "NULLABLE" },
        { name = "name", type = "STRING", mode = "NULLABLE" },
        {
          name = "labels",
          type = "RECORD",
          mode = "REPEATED",
          fields = [
            { name = "key", type = "STRING", mode = "NULLABLE" },
            { name = "value", type = "STRING", mode = "NULLABLE" }
          ]
        }
      ]
    },
    {
      name = "labels",
      type = "RECORD",
      mode = "REPEATED",
      fields = [
        { name = "key", type = "STRING", mode = "NULLABLE" },
        { name = "value", type = "STRING", mode = "NULLABLE" }
      ]
    },
    { name = "cost", type = "FLOAT", mode = "NULLABLE" },
    { name = "currency", type = "STRING", mode = "NULLABLE" },
    {
      name = "usage",
      type = "RECORD",
      mode = "NULLABLE",
      fields = [
        { name = "amount", type = "FLOAT", mode = "NULLABLE" },
        { name = "unit", type = "STRING", mode = "NULLABLE" },
        { name = "pricing_unit", type = "STRING", mode = "NULLABLE" }
      ]
    },
    {
      name = "credits",
      type = "RECORD",
      mode = "REPEATED",
      fields = [
        { name = "name", type = "STRING", mode = "NULLABLE" },
        { name = "type", type = "STRING", mode = "NULLABLE" },
        { name = "amount", type = "FLOAT", mode = "NULLABLE" },
        { name = "full_name", type = "STRING", mode = "NULLABLE" }
      ]
    },
    { name = "export_time", type = "TIMESTAMP", mode = "NULLABLE" },
    { name = "cost_type", type = "STRING", mode = "NULLABLE" }
  ])
}

# 3. View Analítica 1: Custo Diário por Serviço (Net Cost)
resource "google_bigquery_table" "v_daily_cost_by_service" {
  dataset_id          = google_bigquery_dataset.billing_finops.dataset_id
  table_id            = "v_daily_cost_by_service"
  description         = "View analítica agregando custo líquido diário por serviço"
  deletion_protection = false

  view {
    query = replace(
      replace(
        replace(
          file("${path.module}/../sql/v_daily_cost_by_service.sql"),
          "CREATE OR REPLACE VIEW `{{project_id}}.{{dataset_id}}.v_daily_cost_by_service` AS",
          ""
        ),
        "{{project_id}}",
        var.project_id
      ),
      "{{dataset_id}}",
      var.dataset_id
    )
    use_legacy_sql = false
  }

  depends_on = [google_bigquery_table.raw_billing]
}

# 4. View Analítica 2: Custos por Projeto e Ambiente (Governança FinOps)
resource "google_bigquery_table" "v_cost_by_project_and_env" {
  dataset_id          = google_bigquery_dataset.billing_finops.dataset_id
  table_id            = "v_cost_by_project_and_env"
  description         = "View analítica de distribuição de custo por ambiente e centro de custo"
  deletion_protection = false

  view {
    query = replace(
      replace(
        replace(
          file("${path.module}/../sql/v_cost_by_project_and_env.sql"),
          "CREATE OR REPLACE VIEW `{{project_id}}.{{dataset_id}}.v_cost_by_project_and_env` AS",
          ""
        ),
        "{{project_id}}",
        var.project_id
      ),
      "{{dataset_id}}",
      var.dataset_id
    )
    use_legacy_sql = false
  }

  depends_on = [google_bigquery_table.raw_billing]
}

# 5. View Analítica 3: Detecção de Anomalias de Custo (Média Móvel 7 dias)
resource "google_bigquery_table" "v_cost_anomalies_detection" {
  dataset_id          = google_bigquery_dataset.billing_finops.dataset_id
  table_id            = "v_cost_anomalies_detection"
  description         = "View estatística com detecção de desvios anômalos de custos"
  deletion_protection = false

  view {
    query = replace(
      replace(
        replace(
          file("${path.module}/../sql/v_cost_anomalies_detection.sql"),
          "CREATE OR REPLACE VIEW `{{project_id}}.{{dataset_id}}.v_cost_anomalies_detection` AS",
          ""
        ),
        "{{project_id}}",
        var.project_id
      ),
      "{{dataset_id}}",
      var.dataset_id
    )
    use_legacy_sql = false
  }

  depends_on = [google_bigquery_table.v_daily_cost_by_service]
}
