# Painel de FinOps — Otimização de Custos no GCP

## 1. Visão geral

**A dor real:** times de engenharia e startups frequentemente perdem dinheiro na nuvem por falta de visibilidade — recursos esquecidos ligados, sem alertas de orçamento, sem noção de qual serviço está consumindo mais. FinOps (gestão financeira de cloud) é hoje uma das áreas que mais crescem dentro de Cloud/DevOps, exatamente porque resolve um problema que dói no bolso de qualquer empresa.

**O que o projeto faz:** um painel que exibe o gasto no GCP por serviço, projeto e período, com alertas automáticos quando o orçamento é ultrapassado.

## 2. O que este projeto precisa provar

- Você sabe modelar dados no BigQuery (SQL intermediário)
- Você entende automação serverless (Cloud Functions + Scheduler)
- Você sabe construir infraestrutura como código (Terraform)
- Você entende IAM básico (permissões mínimas para cada recurso)
- Você comunica dados de forma visual (dashboard)

## 3. Arquitetura

```
Billing Account (GCP)
        │  (export automático)
        ▼
BigQuery ── dataset "billing_export"
        │
        ├──► Views agregadas (custo por serviço / projeto / dia)
        │           │
        │           ▼
        │     Looker Studio (dashboard)
        │
        └──► Cloud Scheduler (roda 1x/dia)
                    │
                    ▼
            Cloud Function "check_budget"
                    │
                    ▼
        Alerta (Slack webhook / e-mail)
```

## 4. Stack tecnológica

| Componente | Serviço GCP | Por que usar |
|---|---|---|
| Armazenamento/consulta dos dados de billing | BigQuery | padrão de mercado para análise de custo em escala |
| Visualização | Looker Studio | gratuito, conecta direto no BigQuery, fácil de embutir no README |
| Automação do alerta | Cloud Functions (Python) | serverless, barato, ótimo para lógica pequena e event-driven |
| Agendamento | Cloud Scheduler | dispara a função diariamente sem precisar de servidor rodando |
| Infraestrutura | Terraform | mostra maturidade de engenharia, não só "cliquei no console" |
| Notificação | Slack Incoming Webhook (ou SMTP) | simples de configurar e visualmente bom para demo |

## 5. Passo a passo

### Fase 0 — Preparação (1–2 dias)
- Criar um projeto GCP isolado (sandbox), aproveitando o free tier / crédito inicial
- Ativar a exportação de faturamento detalhado para o BigQuery (Faturamento → Exportações de faturamento)
- Configurar um orçamento (Budgets & Alerts) básico como rede de segurança desde o primeiro dia

### Fase 1 — Modelagem de dados (2–3 dias)
- Explorar a tabela gerada automaticamente (`gcp_billing_export_v1_XXXX`)
- Criar views SQL: custo diário por serviço, custo por projeto/label, top 10 recursos mais caros do mês
- Guardar as queries versionadas na pasta `/sql` do repositório

### Fase 2 — Dashboard (2–3 dias)
- Conectar o Looker Studio às views do BigQuery
- Montar 3–4 visualizações: tendência de custo diário, distribuição por serviço, comparação mês a mês, destaque de outliers

### Fase 3 — Sistema de alertas (3–4 dias)
- Escrever uma Cloud Function em Python que roda diariamente via Cloud Scheduler
- Comparar o gasto acumulado com o orçamento definido
- Disparar mensagem via webhook do Slack (ou e-mail) quando ultrapassar um limiar (ex: 80% do orçamento)

### Fase 4 — Diferencial: recomendações automáticas (opcional, 2–3 dias)
- Usar a Recommender API ou o Cloud Asset Inventory para detectar recursos ociosos (discos não anexados, VMs paradas, IPs reservados sem uso)
- Adicionar essas recomendações como uma seção extra do relatório/dashboard

### Fase 5 — Infraestrutura como código (2 dias)
- Escrever em Terraform os recursos criados manualmente até aqui (dataset, Cloud Function, Scheduler, permissões IAM)
- Esse passo sozinho já separa o projeto do "básico" — é o que recrutador de Cloud/DevOps mais procura

### Fase 6 — Documentação e publicação (1–2 dias)
- Escrever o README completo (ver seção 8)
- Gravar um vídeo curto (2–3 min) mostrando o dashboard e explicando as decisões técnicas
- Publicar no GitHub com histórico de commits organizado

## 6. Estrutura de repositório sugerida

```
gcp-finops-dashboard/
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
├── functions/
│   └── check_budget/
│       ├── main.py
│       └── requirements.txt
├── sql/
│   ├── daily_cost_by_service.sql
│   └── top_10_resources.sql
├── docs/
│   └── architecture.png
├── README.md
└── LICENSE
```

## 7. Cronograma estimado (~3 semanas, poucas horas por dia)

| Semana | Foco |
|---|---|
| 1 | Fases 0, 1 e 2 — dados e dashboard funcionando |
| 2 | Fases 3 e 5 — alertas automatizados + Terraform |
| 3 | Fase 4 (opcional), Fase 6 — documentação, vídeo e publicação |

## 8. O que colocar no README para impressionar

- Resumo do problema real que o projeto resolve (1 parágrafo)
- Print ou GIF do dashboard
- Diagrama de arquitetura (pode reaproveitar o desta seção 3)
- Decisões técnicas e trade-offs (ex: "por que Cloud Function e não Cloud Run aqui")
- Alguma métrica, mesmo estimada em cenário simulado (ex: "identifica automaticamente recursos ociosos que representam X% do gasto mensal simulado")
- Link para o vídeo de demonstração

## 9. Diferenciais para se destacar ainda mais

- Testes automatizados das queries SQL
- Pipeline de CI (GitHub Actions) rodando `terraform plan` antes de qualquer merge
- Simular 2–3 projetos GCP diferentes para o dashboard mostrar comparação entre "times" ou "produtos"

## 10. Cuidados

- Trabalhe sempre em um projeto sandbox isolado, nunca em conta de produção
- Configure o alerta de orçamento real desde o primeiro dia — evita susto na fatura
- Pause ou remova recursos ativos (Scheduler, Functions) ao final dos testes
