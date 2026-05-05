# Olist DW Analytics — DWBI Assignment 2 (Option C: Hybrid)

A unified **Streamlit** dashboard combining **BI visualisations** and an **ML late-delivery risk predictor**, built on top of the Olist Gold data warehouse layer in SQL Server.

## Quick Start

```bash
# 1. Install dependencies
pip install -r requirements.txt

# 2. Update config.py with your SSMS server name
#    Edit the SERVER variable in config.py

# 3. Train the ML model (run ONCE)
python -m ml.train

# 4. Launch the dashboard
streamlit run app.py
```

## Project Structure

```
DWBI_Project/
├── app.py                  ← Streamlit entry point
├── config.py               ← DB connection string
├── data_loader.py          ← Cached Gold view queries
├── requirements.txt
├── .gitignore
├── .streamlit/config.toml  ← Dark theme
│
├── pages/                  ← Dashboard pages
│   ├── page_executive.py   ← Revenue & order trends
│   ├── page_logistics.py   ← Delivery health by state
│   ├── page_satisfaction.py← Delivery ↔ review correlation
│   ├── page_products.py    ← Category & freight analysis
│   ├── page_sellers.py     ← Seller scorecard
│   ├── page_funnel.py      ← Order status funnel
│   └── page_ml.py          ← ML risk insights + live predictor
│
├── ml/                     ← ML pipeline
│   ├── train.py            ← Run once to train model
│   └── predict.py          ← Load model & score orders
│
├── models/                 ← Generated after training
│   ├── random_forest.pkl
│   ├── model_metrics.pkl
│   └── ...
│
└── sql/                    ← SQL reference
    ├── gold_views.sql
    └── ml_feature_query.sql
```

## Dashboard Pages

| # | Page | Gold View(s) | Key Visuals |
|---|------|-------------|-------------|
| 1 | Executive Overview | `vw_kpi_monthly_sales_trend` | KPI cards, revenue trend, AOV, donut |
| 2 | Logistics & Delivery | `vw_kpi_logistics_health` | Brazil choropleth, top problem states |
| 3 | Delivery ↔ Satisfaction | `vw_kpi_delivery_review_correlation` | Bucket scores, 1★ vs 5★ rates |
| 4 | Product & Category | `vw_kpi_product_performance` + `freight_ratio` | Treemap, freight danger scatter |
| 5 | Seller Performance | `vw_kpi_seller_scorecard` | Top 20 sellers, efficiency scatter |
| 6 | Order Funnel | `vw_kpi_order_status_funnel` | Funnel chart, lost revenue |
| 7 | ML Risk Predictor | Trained RF model | Confusion matrix, feature importance, live predictor |

## ML Model

- **Task:** Binary classification — predict `is_late_delivery`
- **Model:** Random Forest (200 trees, balanced class weights)
- **Features:** 16 features from Gold (state, category, freight ratio, etc.)
- **Output:** Per-order risk tier (High / Medium / Low)
