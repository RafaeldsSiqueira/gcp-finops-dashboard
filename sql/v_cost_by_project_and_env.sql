-- ==============================================================================
-- View: v_cost_by_project_and_env
-- Descrição: Agrega os custos por Projeto, Ambiente (Production, Staging, Dev)
--            e Centro de Custo, identificando recursos sem etiquetagem (Governança FinOps).
-- ==============================================================================

CREATE OR REPLACE VIEW `{{project_id}}.{{dataset_id}}.v_cost_by_project_and_env` AS
WITH unnested_labels AS (
  SELECT
    DATE(usage_start_time) AS usage_date,
    project.id AS project_id,
    project.name AS project_name,
    service.description AS service_description,
    cost,
    COALESCE(
      (SELECT SUM(c.amount) FROM UNNEST(credits) AS c), 
      0.0
    ) AS credits,
    -- Extrai o valor da label 'env' ou 'environment'
    COALESCE(
      (SELECT value FROM UNNEST(labels) WHERE key IN ('env', 'environment') LIMIT 1),
      'unallocated'
    ) AS environment,
    -- Extrai o centro de custo
    COALESCE(
      (SELECT value FROM UNNEST(labels) WHERE key IN ('cost_center', 'cc') LIMIT 1),
      'unallocated'
    ) AS cost_center,
    -- Identifica se é gerenciado por IaC (Terraform)
    COALESCE(
      (SELECT value FROM UNNEST(labels) WHERE key = 'managed_by' LIMIT 1),
      'manual'
    ) AS managed_by
  FROM
    `{{project_id}}.{{dataset_id}}.gcp_billing_export_resource_v1_*`
)
SELECT
  usage_date,
  project_id,
  project_name,
  service_description,
  environment,
  cost_center,
  managed_by,
  ROUND(SUM(cost), 4) AS gross_cost,
  ROUND(SUM(credits), 4) AS total_credits,
  ROUND(SUM(cost) + SUM(credits), 4) AS net_cost
FROM
  unnested_labels
GROUP BY
  usage_date,
  project_id,
  project_name,
  service_description,
  environment,
  cost_center,
  managed_by
ORDER BY
  usage_date DESC,
  net_cost DESC;
