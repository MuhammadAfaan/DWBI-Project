# ──────────────────────────────────────────────────────────────
# app.py  –  Streamlit entry point
# Run:  streamlit run app.py
# ──────────────────────────────────────────────────────────────

import streamlit as st

st.set_page_config(
    page_title="Olist DW Analytics",
    layout="wide",
    initial_sidebar_state="expanded",
)

# ── Custom CSS ───────────────────────────────────────────────
st.markdown("""
<style>
    @import url('https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap');
    html, body, [class*="css"] { font-family: 'Inter', sans-serif; }

    /* Top accent bar */
    .main > div:first-child::before {
        content: '';
        display: block;
        height: 4px;
        background: #4F46E5;
        border-radius: 0 0 4px 4px;
        margin-bottom: 1.5rem;
    }

    /* Metric card styling */
    div[data-testid="stMetric"] {
        background: #ffffff;
        border: 1px solid #e5e7eb;
        border-radius: 8px;
        padding: 20px 24px;
        box-shadow: 0 1px 3px rgba(0,0,0,0.05);
    }
    div[data-testid="stMetric"] label {
        font-size: 0.85rem !important;
        font-weight: 500 !important;
        color: #6b7280 !important;
        text-transform: uppercase;
        letter-spacing: 0.05em;
    }
    div[data-testid="stMetric"] [data-testid="stMetricValue"] {
        font-size: 1.75rem !important;
        font-weight: 600 !important;
        color: #111827 !important;
    }

    /* Sidebar Navigation Styling */
    section[data-testid="stSidebar"] {
        background: #f8fafc;
        border-right: 1px solid #e2e8f0;
    }
    /* Hide the default radio circle */
    div[role="radiogroup"] > div > label > div:first-child {
        display: none !important;
    }
    /* Style the radio labels as nav links */
    div[role="radiogroup"] > div > label {
        padding: 10px 16px;
        border-radius: 6px;
        margin-bottom: 4px;
        background-color: transparent;
        transition: all 0.2s ease;
        border: 1px solid transparent;
        cursor: pointer;
    }
    div[role="radiogroup"] > div > label:hover {
        background-color: #f1f5f9;
        color: #0f172a;
    }
    /* Selected state */
    div[role="radiogroup"] > div > label[data-checked="true"] {
        background-color: #e0e7ff;
        border: 1px solid #c7d2fe;
    }
    div[role="radiogroup"] > div > label[data-checked="true"] p {
        color: #4F46E5 !important;
        font-weight: 600 !important;
    }
    div[role="radiogroup"] p {
        font-size: 0.95rem;
        color: #475569;
        font-weight: 500;
        margin: 0;
    }

    /* Expander */
    details {
        border: 1px solid #e5e7eb !important;
        border-radius: 8px !important;
        background: #ffffff;
    }

    /* Headers */
    h1, h2, h3 {
        color: #0f172a;
        font-weight: 600;
        letter-spacing: -0.02em;
    }

    /* Hide branding */
    #MainMenu {visibility: hidden;}
    footer {visibility: hidden;}
</style>
""", unsafe_allow_html=True)

# ── Sidebar ──────────────────────────────────────────────────
with st.sidebar:
    st.markdown("""
    <div style="padding: 12px 0 24px 8px;">
        <h1 style="color: #0f172a; font-size: 1.5rem; font-weight: 700; margin: 0; letter-spacing: -0.03em;">Olist DW</h1>
        <p style="color: #64748b; font-size: 0.85rem; margin: 4px 0 0 0; font-weight: 500;">Analytics & ML Dashboard</p>
    </div>
    """, unsafe_allow_html=True)

    page = st.radio(
        "Navigation",
        [
            "Executive Overview",
            "Logistics & Delivery",
            "Delivery & Satisfaction",
            "Product & Category",
            "Seller Performance",
            "Order Funnel",
            "ML Risk Predictor",
        ],
        label_visibility="collapsed",
    )

    st.markdown("<br><hr style='margin: 16px 0; border-color: #e2e8f0;'>", unsafe_allow_html=True)
    st.markdown("""
    <div style="padding-left: 8px;">
        <div style="color: #64748b; font-size: 0.75rem; font-weight: 600; text-transform: uppercase; letter-spacing: 0.05em; margin-bottom: 8px;">System Info</div>
        <div style="color: #94a3b8; font-size: 0.8rem; margin-bottom: 4px;">Source: Gold Layer (OlistDW)</div>
        <div style="color: #94a3b8; font-size: 0.8rem;">DWBI Assignment 2</div>
    </div>
    """, unsafe_allow_html=True)

# ── Page routing ─────────────────────────────────────────────
if page == "Executive Overview":
    st.markdown("<h1>Executive Overview</h1>", unsafe_allow_html=True)
    st.caption("Monthly revenue, orders, and average order value trends")
    from data_loader import load_monthly_sales
    from views.page_executive import render
    render(load_monthly_sales())

elif page == "Logistics & Delivery":
    st.markdown("<h1>Logistics & Delivery Health</h1>", unsafe_allow_html=True)
    st.caption("Late delivery rates by Brazilian state — where are the problem zones?")
    from data_loader import load_logistics_health
    from views.page_logistics import render
    render(load_logistics_health())

elif page == "Delivery & Satisfaction":
    st.markdown("<h1>Delivery Speed vs Customer Satisfaction</h1>", unsafe_allow_html=True)
    st.caption("Does late delivery really cause bad reviews? The data says yes.")
    from data_loader import load_delivery_review_correlation, load_customer_satisfaction
    from views.page_satisfaction import render
    render(load_delivery_review_correlation(), load_customer_satisfaction())

elif page == "Product & Category":
    st.markdown("<h1>Product & Category Analysis</h1>", unsafe_allow_html=True)
    st.caption("Revenue by category, freight-to-price ratios, and margin risks")
    from data_loader import load_product_performance, load_category_freight_ratio
    from views.page_products import render
    render(load_product_performance(), load_category_freight_ratio())

elif page == "Seller Performance":
    st.markdown("<h1>Seller Performance Scorecard</h1>", unsafe_allow_html=True)
    st.caption("Top sellers by revenue, state distribution, and efficiency")
    from data_loader import load_seller_scorecard
    from views.page_sellers import render
    df = load_seller_scorecard()
    states = sorted(df["seller_state"].dropna().unique())
    sel_states = st.sidebar.multiselect("Filter by Seller State", states, default=[])
    if sel_states:
        df = df[df["seller_state"].isin(sel_states)]
    render(df)

elif page == "Order Funnel":
    st.markdown("<h1>Order Status Funnel & Revenue Leakage</h1>", unsafe_allow_html=True)
    st.caption("How orders flow through the pipeline — and where revenue is lost")
    from data_loader import load_order_status_funnel
    from views.page_funnel import render
    render(load_order_status_funnel())

elif page == "ML Risk Predictor":
    st.markdown("<h1>ML Late-Delivery Risk Predictor</h1>", unsafe_allow_html=True)
    st.caption("Random Forest classifier trained on Gold layer — predicts which orders will be late")
    from views.page_ml import render
    render()
