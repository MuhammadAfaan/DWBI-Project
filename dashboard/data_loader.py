# ──────────────────────────────────────────────────────────────
# data_loader.py  –  All Gold-view queries in one place
# ──────────────────────────────────────────────────────────────
# MODE: Reads from local CSV files (exported from Gold views).
#       This allows deployment on Streamlit Cloud without a
#       SQL Server connection.
#
# To re-export CSVs from SQL Server, run the export script
# documented in README.md.
# ──────────────────────────────────────────────────────────────

import os
import pandas as pd
import streamlit as st

DATA_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "data")


def _read_csv(filename: str) -> pd.DataFrame:
    """Read a CSV from the data/ directory."""
    path = os.path.join(DATA_DIR, filename)
    if not os.path.exists(path):
        st.error(f"Data file not found: {filename}")
        return pd.DataFrame()
    return pd.read_csv(path)


# ── 1. Monthly Sales Trend ──────────────────────────────────
@st.cache_data(ttl=3600, show_spinner="Loading sales trend …")
def load_monthly_sales() -> pd.DataFrame:
    return _read_csv("monthly_sales.csv")


# ── 2. Product Performance ──────────────────────────────────
@st.cache_data(ttl=3600, show_spinner="Loading product data …")
def load_product_performance() -> pd.DataFrame:
    return _read_csv("product_performance.csv")


# ── 3. Logistics Health ─────────────────────────────────────
@st.cache_data(ttl=3600, show_spinner="Loading logistics data …")
def load_logistics_health() -> pd.DataFrame:
    return _read_csv("logistics_health.csv")


# ── 4. Seller Scorecard ─────────────────────────────────────
@st.cache_data(ttl=3600, show_spinner="Loading seller data …")
def load_seller_scorecard() -> pd.DataFrame:
    return _read_csv("seller_scorecard.csv")


# ── 5. Customer Satisfaction ─────────────────────────────────
@st.cache_data(ttl=3600, show_spinner="Loading satisfaction data …")
def load_customer_satisfaction() -> pd.DataFrame:
    return _read_csv("customer_satisfaction.csv")


# ── 6. Delivery ↔ Review Correlation ────────────────────────
@st.cache_data(ttl=3600, show_spinner="Loading correlation data …")
def load_delivery_review_correlation() -> pd.DataFrame:
    return _read_csv("delivery_review_correlation.csv")


# ── 7. Category Freight Ratio ────────────────────────────────
@st.cache_data(ttl=3600, show_spinner="Loading freight data …")
def load_category_freight_ratio() -> pd.DataFrame:
    return _read_csv("category_freight_ratio.csv")


# ── 8. Order Status Funnel ───────────────────────────────────
@st.cache_data(ttl=3600, show_spinner="Loading funnel data …")
def load_order_status_funnel() -> pd.DataFrame:
    return _read_csv("order_status_funnel.csv")
