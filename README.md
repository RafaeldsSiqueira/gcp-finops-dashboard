# ☁️ GCP FinOps — Dashboard & Automação de Alertas de Orçamento

[![GCP](https://img.shields.io/badge/Google_Cloud-4285F4?style=flat&logo=google-cloud&logoColor=white)](https://cloud.google.com/)
[![Terraform](https://img.shields.io/badge/Terraform-844FBA?style=flat&logo=terraform&logoColor=white)](https://www.terraform.io/)
[![BigQuery](https://img.shields.io/badge/BigQuery-669DF6?style=flat&logo=google-cloud&logoColor=white)](https://cloud.google.com/bigquery)
[![Python](https://img.shields.io/badge/Python-3.11+-3776AB?style=flat&logo=python&logoColor=white)](https://www.python.org/)
[![Looker Studio](https://img.shields.io/badge/Looker_Studio-4285F4?style=flat&logo=google-analytics&logoColor=white)](https://lookerstudio.google.com/)

> Projeto prático de **FinOps (Financial Operations)** para visualização centralizada de custos em nuvem, modelagem analítica no BigQuery, detecção de anomalias financeiras e provisionamento 100% automatizado com Terraform.

---

## 🎯 O Problema Real de Negócio

Empresas que migram ou operam no **Google Cloud Platform (GCP)** frequentemente enfrentam dificuldades para responder perguntas básicas como:
- *“Qual serviço ou equipe teve o maior aumento de custo neste mês?”*
- *“Existem recursos ociosos ou ambientes de desenvolvimento gerando custos desnecessários?”*
- *“Como saber se vamos estourar o orçamento antes que a fatura do fim do mês chegue?”*

A falta de governança financeira em nuvem leva a desperdícios recorrentes. Este projeto resolve esse gargalo entregando **visibilidade em tempo real**, **modelagem dimensional de custos** e **alarmes preventivos proativos**.

---

## 🏗️ Arquitetura da Solução

```mermaid
flowchart LR
    subgraph GCP["Google Cloud Platform"]
        Billing[Billing Account Export] -->|Export Automático| BQ_Raw[(BigQuery: Dados Brutos de Billing)]
        BQ_Raw -->|Transformações SQL| BQ_Views[(Views Analíticas FinOps)]
        
        BQ_Views -->|Leitura Direta| Looker[Looker Studio Dashboard]
        
        Scheduler[Cloud Scheduler<br/>Diário] -->|Disparo HTTP| Function[Cloud Function<br/>Detector de Anomalias]
        Function -->|Consulta SQL| BQ_Views
    end

    Function -->|Notificação Webhook| Slack[Slack / Microsoft Teams / E-mail]
```

---

## 🛠️ Stack Tecnológica & Justificativas Técnicas

| Componente | Ferramenta | Decisão Arquitetural |
| :--- | :--- | :--- |
| **Data Warehouse** | **BigQuery** | Padrão nativo para faturamento do GCP, escalabilidade sob demanda e custo zero para bases pequenas com particionamento inteligente. |
| **Modelagem de Dados** | **SQL (BigQuery Views)** | Centralização da regra de negócio de custos em views lógicas (sem duplicação desnecessária de armazenamento). |
| **Visualização** | **Looker Studio** | Conector nativo de alta performance para BigQuery, sem custos adicionais de licença e compartilhamento simplificado para executivos. |
| **Automação & Alertas** | **Cloud Functions (Python)** | Arquitetura *Serverless event-driven* executada sob demanda, garantindo custo operacional praticamente nulo. |
| **Orquestração** | **Cloud Scheduler** | Cron job gerenciado para disparo periódico dos pipelines de verificação de anomalias. |
| **Infraestrutura como Código** | **Terraform** | Reprodutibilidade total do ambiente, controle de versão da infraestrutura e princípio do menor privilégio em IAM. |

---

## 📂 Estrutura do Repositório

```text
gcp-finops-dashboard/
├── docs/                       # Diagramas de arquitetura e documentação
├── functions/                  # Código serverless de monitoramento e alertas
│   └── check_budget/           # Cloud Function em Python
├── scripts/                    # Utilitários e gerador de dados sintéticos de billing
├── sql/                        # Views analíticas e queries de detecção de anomalias
└── terraform/                  # Manifestos de infraestrutura como código (IaC)
```

---

## 🚀 Próximos Passos do Desenvolvimento

- [x] Estruturação do repositório e baseline de arquitetura
- [ ] Construção do gerador de dados sintéticos compatível com GCP Billing Export
- [ ] Modelagem das views SQL de agregação e KPIs FinOps
- [ ] Provisionamento da infraestrutura com Terraform (BigQuery, IAM, Cloud Functions)
- [ ] Criação do dashboard executivo no Looker Studio
- [ ] Implementação do bot de alertas no Slack
