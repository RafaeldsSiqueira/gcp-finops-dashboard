#!/usr/bin/env python3
"""
Gerador de Dados Sintéticos de Faturamento do Google Cloud Platform (GCP).
Simula a exportação detalhada de faturamento do GCP no BigQuery (schema gcp_billing_export_resource_v1_*).
Inclui cenários normais, falhas de governança (tags faltantes) e anomalias de custo.
"""

import json
import random
from datetime import datetime, timedelta, timezone

# Configurações do Mock
BILLING_ACCOUNT_ID = "01ABCD-2345EF-6789GH"
CURRENCY = "USD"
DIAS_HISTORICO = 90  # 3 meses de histórico
ANOMALIA_DIAS_ATRAS = 5  # Ocorrência de anomalia recente (5 dias atrás)

PROJECTS = [
    {"id": "finops-prod-ecommerce", "name": "E-Commerce Production", "env": "production", "cc": "checkout-team"},
    {"id": "finops-prod-data-platform", "name": "Data Platform Prod", "env": "production", "cc": "data-team"},
    {"id": "finops-stage-api", "name": "API Gateway Staging", "env": "staging", "cc": "backend-team"},
    {"id": "finops-dev-sandbox", "name": "Engineering Sandbox Dev", "env": "development", "cc": "dev-general"},
]

SERVICES = {
    "Compute Engine": {
        "id": "6F81-5844-456A",
        "skus": [
            {"id": "C23D-8891-1122", "desc": "N2 Instance Core running in Americas", "unit": "seconds", "base_cost": 45.0},
            {"id": "E44F-1122-3344", "desc": "SSD backed Standard Storage", "unit": "byte-seconds", "base_cost": 15.0},
        ],
    },
    "BigQuery": {
        "id": "A1B2-C3D4-E5F6",
        "skus": [
            {"id": "B99A-3344-5566", "desc": "Analysis (Query TB processed)", "unit": "bytes", "base_cost": 25.0},
            {"id": "B88C-7788-9900", "desc": "Active Storage", "unit": "byte-seconds", "base_cost": 8.0},
        ],
    },
    "Cloud Storage": {
        "id": "95FF-2EF5-5EA1",
        "skus": [
            {"id": "D11E-2233-4455", "desc": "Standard Storage US Regional", "unit": "byte-seconds", "base_cost": 12.0},
            {"id": "D22E-6677-8899", "desc": "Network Egress via Carrier Peering", "unit": "bytes", "base_cost": 5.0},
        ],
    },
    "Cloud Run": {
        "id": "7B1B-659F-3B9B",
        "skus": [
            {"id": "F55A-7788-9900", "desc": "CPU Allocation Time", "unit": "seconds", "base_cost": 18.0},
            {"id": "F66B-1122-3344", "desc": "Memory Allocation Time", "unit": "byte-seconds", "base_cost": 7.0},
        ],
    },
    "Cloud Networking": {
        "id": "C092-215E-63A5",
        "skus": [
            {"id": "N11A-4455-6677", "desc": "Inter-region Data Transfer Out", "unit": "bytes", "base_cost": 9.0},
        ],
    },
}


def gerar_dados(arquivo_saida="scripts/dados_billing_simulados.jsonl"):
    registros = []
    data_hoje = datetime.now(timezone.utc).replace(hour=0, minute=0, second=0, microsecond=0)
    data_inicio = data_hoje - timedelta(days=DIAS_HISTORICO)

    print(f"Gerando histórico de faturamento de {data_inicio.strftime('%Y-%m-%d')} até {data_hoje.strftime('%Y-%m-%d')}...")

    dia_atual = data_inicio
    while dia_atual <= data_hoje:
        dias_para_hoje = (data_hoje - dia_atual).days
        eh_dia_de_anomalia = (dias_para_hoje == ANOMALIA_DIAS_ATRAS)

        for proj in PROJECTS:
            # Multiplicador por ambiente
            multiplicador_env = 1.0 if proj["env"] == "production" else (0.4 if proj["env"] == "staging" else 0.2)

            for service_name, service_data in SERVICES.items():
                for sku in service_data["skus"]:
                    # Variação estocástica diária (-15% a +15%)
                    fator_ruido = random.uniform(0.85, 1.15)
                    custo_base = sku["base_cost"] * multiplicador_env * fator_ruido

                    # Fim de semana tem menos gasto em Dev/Staging (-50%)
                    if dia_atual.weekday() >= 5 and proj["env"] != "production":
                        custo_base *= 0.5

                    # INJEÇÃO DO CENÁRIO DE ANOMALIA:
                    # No dia de anomalia, no ambiente Dev, simula VM enorme esquecida no Compute Engine
                    if eh_dia_de_anomalia and proj["id"] == "finops-dev-sandbox" and service_name == "Compute Engine":
                        custo_base *= 12.0  # Spike de 1200%!

                    cost = round(custo_base, 4)

                    # Simulação de Créditos de Uso Sustentado (SUD) em produção (desconto de ~10%)
                    credits = []
                    if proj["env"] == "production" and cost > 20:
                        desconto = round(cost * random.uniform(0.05, 0.12), 4)
                        credits.append({
                            "name": "Sustained Usage Discount",
                            "type": "SUSTAINED_USAGE_DISCOUNT",
                            "amount": -desconto,
                            "full_name": "Sustained Usage Discount"
                        })

                    # Cenário de Governança: 15% dos recursos de dev/staging sem tags de cost-center
                    labels = [{"key": "env", "value": proj["env"]}]
                    if not (proj["env"] in ["development", "staging"] and random.random() < 0.15):
                        labels.append({"key": "cost_center", "value": proj["cc"]})
                        labels.append({"key": "managed_by", "value": "terraform"})

                    start_time = dia_atual.isoformat()
                    end_time = (dia_atual + timedelta(hours=23, minutes=59, seconds=59)).isoformat()

                    registro = {
                        "billing_account_id": BILLING_ACCOUNT_ID,
                        "service": {
                            "id": service_data["id"],
                            "description": service_name
                        },
                        "sku": {
                            "id": sku["id"],
                            "description": sku["desc"]
                        },
                        "usage_start_time": start_time,
                        "usage_end_time": end_time,
                        "project": {
                            "id": proj["id"],
                            "name": proj["name"],
                            "labels": [{"key": "environment", "value": proj["env"]}]
                        },
                        "labels": labels,
                        "cost": cost,
                        "currency": CURRENCY,
                        "usage": {
                            "amount": round(cost * 12.5, 2),
                            "unit": sku["unit"],
                            "pricing_unit": sku["unit"]
                        },
                        "credits": credits,
                        "export_time": end_time,
                        "cost_type": "regular"
                    }
                    registros.append(registro)

        dia_atual += timedelta(days=1)

    # Escreve formato JSONL (JSON Lines), padrão ideal para carga no BigQuery
    with open(arquivo_saida, "w", encoding="utf-8") as f:
        for r in registros:
            f.write(json.dumps(r) + "\n")

    print(f"Sucesso! {len(registros)} registros de faturamento gerados em '{arquivo_saida}'.")


if __name__ == "__main__":
    gerar_dados()
