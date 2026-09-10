"""
Cloud Function: FinOps Anomaly & Budget Alert Bot
Monitora anomalias de faturamento no BigQuery e envia alertas formatados para o Discord/Slack.
"""

import os
import json
import logging
from datetime import datetime
import requests
from google.cloud import bigquery

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("finops_alert")

PROJECT_ID = os.environ.get("PROJECT_ID", "finops-platform-rafael")
DATASET_ID = os.environ.get("DATASET_ID", "billing_finops")
DISCORD_WEBHOOK_URL = os.environ.get("DISCORD_WEBHOOK_URL", "")


def send_discord_alert(anomalies: list):
    """Formata e envia uma notificação rica via Discord Webhook Embed."""
    if not DISCORD_WEBHOOK_URL:
        logger.warning("DISCORD_WEBHOOK_URL não configurada. Alerta exibido apenas nos logs.")
        return

    for item in anomalies:
        color = 15158332 if item["percentage_increase"] > 200 else 15844367  # Vermelho se > 200%, senão Amarelo

        embed = {
            "title": "🚨 Alerta FinOps: Anomalia de Custo Detectada no GCP!",
            "description": f"Foi identificado um desvio financeiro significativo no ambiente do Google Cloud.",
            "color": color,
            "fields": [
                {"name": "📅 Data do Evento", "value": str(item["usage_date"]), "inline": True},
                {"name": "🏢 Projeto Impactado", "value": f"`{item['project_id']}`", "inline": True},
                {"name": "⚙️ Serviço GCP", "value": item["service_description"], "inline": True},
                {"name": "💰 Custo Real do Dia", "value": f"**${item['net_cost']:.2f} USD**", "inline": True},
                {"name": "📊 Média dos Últimos 7 Dias", "value": f"${item['avg_cost_past_7_days']:.2f} USD", "inline": True},
                {"name": "📈 Variação Percentual", "value": f"**+{item['percentage_increase']:.1f}%**", "inline": True},
            ],
            "footer": {
                "text": "GCP FinOps Automated Watchdog | BigQuery Analytics"
            },
            "timestamp": datetime.utcnow().isoformat()
        }

        payload = {
            "username": "GCP FinOps Bot",
            "avatar_url": "https://raw.githubusercontent.com/github/explore/main/topics/google-cloud/google-cloud.png",
            "embeds": [embed]
        }

        response = requests.post(
            DISCORD_WEBHOOK_URL,
            data=json.dumps(payload),
            headers={"Content-Type": "application/json"},
            timeout=10
        )

        if response.status_code in [200, 204]:
            logger.info(f"Alerta enviado ao Discord com sucesso para {item['service_description']}!")
        else:
            logger.error(f"Falha ao enviar webhook ao Discord: {response.status_code} - {response.text}")


def check_budget_anomalies(request=None):
    """Ponto de entrada (Entrypoint) da Cloud Function chamada pelo Cloud Scheduler."""
    logger.info("Iniciando varredura de anomalias de faturamento no BigQuery...")
    client = bigquery.Client(project=PROJECT_ID)

    query = f"""
    SELECT
        usage_date,
        project_id,
        project_name,
        service_description,
        net_cost,
        avg_cost_past_7_days,
        percentage_increase
    FROM
        `{PROJECT_ID}.{DATASET_ID}.v_cost_anomalies_detection`
    WHERE
        is_anomaly = TRUE
    ORDER BY
        usage_date DESC
    LIMIT 5;
    """

    try:
        query_job = client.query(query)
        results = list(query_job.result())

        if not results:
            logger.info("Nenhuma anomalia detectada no período recente. Custos sob controle.")
            return {"status": "ok", "anomalies_found": 0}, 200

        anomalies = []
        for row in results:
            anomalies.append({
                "usage_date": row.usage_date,
                "project_id": row.project_id,
                "project_name": row.project_name,
                "service_description": row.service_description,
                "net_cost": row.net_cost,
                "avg_cost_past_7_days": row.avg_cost_past_7_days,
                "percentage_increase": row.percentage_increase
            })

        logger.info(f"{len(anomalies)} anomalia(s) encontrada(s). Disparando notificações...")
        send_discord_alert(anomalies)

        return {
            "status": "alert_triggered",
            "anomalies_count": len(anomalies),
            "details": anomalies
        }, 200

    except Exception as e:
        logger.error(f"Erro ao consultar anomalias no BigQuery: {str(e)}")
        return {"status": "error", "message": str(e)}, 500


if __name__ == "__main__":
    # Teste de execução local
    check_budget_anomalies()
