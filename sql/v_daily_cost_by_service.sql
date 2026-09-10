-- ==============================================================================
-- View: v_daily_cost_by_service
-- Descrição: Agrega os custos diários por serviço do GCP, calculando o custo bruto,
--            o total de descontos/créditos aplicados e o custo líquido final (Net Cost).
-- ==============================================================================

CREATE OR REPLACE VIEW `{{project_id}}.{{dataset_id}}.v_daily_cost_by_service` AS
WITH raw_data AS (
  SELECT
    DATE(usage_start_time) AS usage_date,
    service.id AS service_id,
    service.description AS service_description,
    sku.id AS sku_id,
    sku.description AS sku_description,
    project.id AS project_id,
    project.name AS project_name,
    currency,
    cost AS gross_cost,
    -- Calcula a soma de créditos/descontos (SUDs, CUDs, promoções)
    COALESCE(
      (SELECT SUM(c.amount) FROM UNNEST(credits) AS c), 
      0.0
    ) AS total_credits
  FROM
    `{{project_id}}.{{dataset_id}}.gcp_billing_export_resource_v1_*`
)
SELECT
  usage_date,
  service_description,
  project_id,
  project_name,
  currency,
  ROUND(SUM(gross_cost), 4) AS total_gross_cost,
  ROUND(SUM(total_credits), 4) AS total_credits,
  ROUND(SUM(gross_cost) + SUM(total_credits), 4) AS net_cost
FROM
  raw_data
GROUP BY
  usage_date,
  service_description,
  project_id,
  project_name,
  currency
ORDER BY
  usage_date DESC,
  net_cost DESC;
