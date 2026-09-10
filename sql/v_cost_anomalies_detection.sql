-- ==============================================================================
-- View: v_cost_anomalies_detection
-- Descrição: Detecta anomalias financeiras de FinOps utilizando funções de janela
--            (Window Functions) para comparar o custo diário atual com a média
--            móvel dos últimos 7 dias por serviço e projeto.
-- ==============================================================================

CREATE OR REPLACE VIEW `{{project_id}}.{{dataset_id}}.v_cost_anomalies_detection` AS
WITH daily_costs AS (
  SELECT
    usage_date,
    project_id,
    project_name,
    service_description,
    net_cost
  FROM
    `{{project_id}}.{{dataset_id}}.v_daily_cost_by_service`
),
moving_averages AS (
  SELECT
    usage_date,
    project_id,
    project_name,
    service_description,
    net_cost,
    -- Calcula a média móvel dos 7 dias anteriores (excluindo o dia atual)
    ROUND(
      AVG(net_cost) OVER (
        PARTITION BY project_id, service_description
        ORDER BY usage_date
        ROWS BETWEEN 7 PRECEDING AND 1 PRECEDING
      ), 
      4
    ) AS avg_cost_past_7_days,
    -- Desvio absoluto em relação à média
    ROUND(
      net_cost - AVG(net_cost) OVER (
        PARTITION BY project_id, service_description
        ORDER BY usage_date
        ROWS BETWEEN 7 PRECEDING AND 1 PRECEDING
      ), 
      4
    ) AS cost_difference
  FROM
    daily_costs
)
SELECT
  usage_date,
  project_id,
  project_name,
  service_description,
  net_cost,
  avg_cost_past_7_days,
  cost_difference,
  -- Percentual de aumento em relação à média dos últimos 7 dias
  ROUND(
    SAFE_DIVIDE(cost_difference, avg_cost_past_7_days) * 100, 
    2
  ) AS percentage_increase,
  -- Flag de anomalia: Se o custo subiu mais de 100% (2x) e a diferença foi superior a $20
  CASE
    WHEN avg_cost_past_7_days IS NOT NULL 
         AND SAFE_DIVIDE(cost_difference, avg_cost_past_7_days) >= 1.0 
         AND cost_difference >= 20.0 
    THEN TRUE
    ELSE FALSE
  END AS is_anomaly
FROM
  moving_averages
ORDER BY
  usage_date DESC,
  cost_difference DESC;
