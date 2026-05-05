# ──────────────────────────────────────────────────────────────
# data_loader.py  –  All Gold-view queries in one place
# ──────────────────────────────────────────────────────────────
# Every public function returns a pandas DataFrame.
# Results are cached for 1 hour via @st.cache_data so the DB
# is only hit once per session / per query.
# ──────────────────────────────────────────────────────────────

import pandas as pd
import streamlit as st
from sqlalchemy import create_engine
from config import SERVER, DATABASE, DRIVER

# Build SQLAlchemy engine URL (no raw pyodbc warnings)
_ENGINE_URL = (
    f"mssql+pyodbc://@{SERVER}/{DATABASE}"
    f"?driver={DRIVER.replace(' ', '+')}&Trusted_Connection=yes"
)

def _get_engine():
    """Return a SQLAlchemy engine."""
    return create_engine(_ENGINE_URL)


def _run_query(query: str) -> pd.DataFrame:
    """Execute *query* against OlistDW and return a DataFrame."""
    engine = _get_engine()
    with engine.connect() as conn:
        df = pd.read_sql(query, conn)
    return df


# ── 1. Monthly Sales Trend ──────────────────────────────────
@st.cache_data(ttl=3600, show_spinner="Loading sales trend …")
def load_monthly_sales() -> pd.DataFrame:
    return _run_query("SELECT * FROM gold.vw_kpi_monthly_sales_trend ORDER BY year, month")


# ── 2. Product Performance ──────────────────────────────────
@st.cache_data(ttl=3600, show_spinner="Loading product data …")
def load_product_performance() -> pd.DataFrame:
    return _run_query("SELECT * FROM gold.vw_kpi_product_performance ORDER BY total_revenue DESC")


# ── 3. Logistics Health ─────────────────────────────────────
@st.cache_data(ttl=3600, show_spinner="Loading logistics data …")
def load_logistics_health() -> pd.DataFrame:
    return _run_query("SELECT * FROM gold.vw_kpi_logistics_health ORDER BY late_delivery_rate_pct DESC")


# ── 4. Seller Scorecard ─────────────────────────────────────
@st.cache_data(ttl=3600, show_spinner="Loading seller data …")
def load_seller_scorecard() -> pd.DataFrame:
    return _run_query("SELECT * FROM gold.vw_kpi_seller_scorecard ORDER BY total_revenue_generated DESC")


# ── 5. Customer Satisfaction ─────────────────────────────────
@st.cache_data(ttl=3600, show_spinner="Loading satisfaction data …")
def load_customer_satisfaction() -> pd.DataFrame:
    return _run_query("SELECT * FROM gold.vw_kpi_customer_satisfaction ORDER BY average_review_score ASC")


# ── 6. Delivery ↔ Review Correlation ────────────────────────
@st.cache_data(ttl=3600, show_spinner="Loading correlation data …")
def load_delivery_review_correlation() -> pd.DataFrame:
    return _run_query("SELECT * FROM gold.vw_kpi_delivery_review_correlation")


# ── 7. Category Freight Ratio ────────────────────────────────
@st.cache_data(ttl=3600, show_spinner="Loading freight data …")
def load_category_freight_ratio() -> pd.DataFrame:
    return _run_query("SELECT * FROM gold.vw_kpi_category_freight_ratio ORDER BY freight_ratio_pct DESC")


# ── 8. Order Status Funnel ───────────────────────────────────
@st.cache_data(ttl=3600, show_spinner="Loading funnel data …")
def load_order_status_funnel() -> pd.DataFrame:
    return _run_query("SELECT * FROM gold.vw_kpi_order_status_funnel ORDER BY total_orders DESC")


# ── ML: Feature extraction (heavy – only called by ml/train.py) ──
@st.cache_data(ttl=3600, show_spinner="Extracting ML features …")
def load_ml_features() -> pd.DataFrame:
    """Run the ML feature-extraction query against Gold tables."""
    import os
    sql_path = os.path.join(os.path.dirname(__file__), "sql", "ml_feature_query.sql")
    with open(sql_path, "r", encoding="utf-8") as f:
        query = f.read()
    return _run_query(query)
