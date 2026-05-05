# views/page_ml.py  –  Page 7: ML Late-Delivery Risk Insights

import os, sys
import plotly.graph_objects as go
import streamlit as st
import pandas as pd
import numpy as np

PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, PROJECT_ROOT)

from ml.predict import (
    load_metrics, load_feature_importance, load_predictions,
    load_encoders, predict_single_order,
)
from views._chart_theme import COLORS as C, base_layout

RISK_COLORS = {"Low": C["SUCCESS"], "Medium": C["WARNING"], "High": C["DANGER"]}


def render():
    metrics = load_metrics()
    fi = load_feature_importance()
    preds = load_predictions()

    if metrics is None:
        st.error("**Model not trained yet.** Run `python -m ml.train` from the project root.")
        st.code("cd \"DWBI Project\"\npy -m ml.train", language="bash")
        return

    rf = metrics.get("random_forest", {})
    lr = metrics.get("logistic_regression", {})

    st.markdown("### Model Performance — Random Forest vs Logistic Regression")
    cols = st.columns(5)
    names = ["accuracy", "precision", "recall", "f1", "auc_roc"]
    labels = ["Accuracy", "Precision", "Recall", "F1-Score", "AUC-ROC"]
    for i, (key, label) in enumerate(zip(names, labels)):
        with cols[i]:
            rf_val = rf.get(key, 0) or 0
            lr_val = lr.get(key, 0) or 0
            st.metric(f"{label}", f"{rf_val:.2%}", delta=f"vs LR: {lr_val:.2%}", delta_color="off")

    st.markdown("<br>", unsafe_allow_html=True)
    c_left, c_right = st.columns(2)

    with c_left:
        cm = rf.get("confusion_matrix", [[0, 0], [0, 0]])
        fig_cm = go.Figure(go.Heatmap(
            z=cm, x=["On-Time", "Late"], y=["On-Time", "Late"],
            text=[[str(v) for v in row] for row in cm],
            texttemplate="%{text}", textfont=dict(size=18, color="white"),
            colorscale=[[0, "#e0e7ff"], [1, C["PRIMARY"]]], showscale=False,
        ))
        fig_cm.update_layout(**base_layout("Confusion Matrix (Random Forest)"),
                             xaxis=dict(title="Predicted"),
                             yaxis=dict(title="Actual", autorange="reversed"),
                             height=380)
        st.plotly_chart(fig_cm, width="stretch")

    with c_right:
        if fi is not None and not fi.empty:
            top10 = fi.head(10).sort_values("importance")
            fig_fi = go.Figure(go.Bar(
                x=top10["importance"], y=top10["feature"], orientation="h",
                marker=dict(color=top10["importance"],
                            colorscale=[[0, C["PRIMARY"]], [1, C["ACCENT"]]]),
                text=top10["importance"].apply(lambda v: f"{v:.3f}"), textposition="outside",
            ))
            fig_fi.update_layout(**base_layout("Top 10 Feature Importance"),
                                 xaxis=dict(gridcolor=C["GRID"]),
                                 yaxis=dict(gridcolor=C["GRID"]),
                                 height=380)
            st.plotly_chart(fig_fi, width="stretch")

    if preds is not None and not preds.empty:
        st.markdown("### Prediction Results on All Delivered Orders")
        c1, c2 = st.columns(2)

        with c1:
            risk_counts = preds["risk_tier"].value_counts().reset_index()
            risk_counts.columns = ["risk_tier", "count"]
            fig_risk = go.Figure(go.Pie(
                labels=risk_counts["risk_tier"], values=risk_counts["count"],
                hole=0.6, marker=dict(colors=[RISK_COLORS.get(r, C["PRIMARY"]) for r in risk_counts["risk_tier"]]),
                textinfo="percent+label",
            ))
            fig_risk.update_layout(**base_layout("Risk Tier Distribution"), showlegend=False, height=380)
            st.plotly_chart(fig_risk, width="stretch")

        with c2:
            val = preds.groupby("risk_tier").agg(
                total=("actual_late", "count"),
                actually_late=("actual_late", "sum")).reset_index()
            val["actual_late_rate"] = (val["actually_late"] / val["total"]) * 100
            val["risk_tier"] = pd.Categorical(val["risk_tier"], ["Low", "Medium", "High"], ordered=True)
            val = val.sort_values("risk_tier")
            fig_val = go.Figure(go.Bar(
                x=val["risk_tier"], y=val["actual_late_rate"],
                marker_color=[RISK_COLORS.get(r, C["PRIMARY"]) for r in val["risk_tier"]],
                text=val["actual_late_rate"].apply(lambda v: f"{v:.1f}%"), textposition="outside",
            ))
            fig_val.update_layout(**base_layout("Actual Late Rate by Predicted Risk Tier"),
                                  xaxis=dict(gridcolor=C["GRID"]),
                                  yaxis=dict(title="Actual Late %", gridcolor=C["GRID"]),
                                  height=380)
            st.plotly_chart(fig_val, width="stretch")

        if "customer_state" in preds.columns:
            state_risk = preds.groupby("customer_state")["predicted_probability"].mean().reset_index()
            state_risk.columns = ["state", "avg_risk"]
            state_risk = state_risk.sort_values("avg_risk", ascending=False)
            fig_sr = go.Figure(go.Bar(
                x=state_risk["state"], y=state_risk["avg_risk"] * 100,
                marker=dict(color=state_risk["avg_risk"],
                            colorscale=[[0, C["SUCCESS"]], [0.5, C["WARNING"]], [1, C["DANGER"]]]),
                text=(state_risk["avg_risk"] * 100).apply(lambda v: f"{v:.1f}%"), textposition="outside",
            ))
            fig_sr.update_layout(**base_layout("Avg Predicted Late-Delivery Risk by State"),
                                 xaxis=dict(gridcolor=C["GRID"]),
                                 yaxis=dict(title="Risk %", gridcolor=C["GRID"]),
                                 height=380)
            st.plotly_chart(fig_sr, width="stretch")

    st.markdown("---")
    st.markdown("### Live Order Risk Predictor")
    st.caption("Input order attributes to predict late-delivery risk in real-time.")

    encoders = load_encoders()
    states = list(encoders["customer_state"].classes_) if encoders and "customer_state" in encoders else ["SP", "RJ", "MG"]
    categories = list(encoders["dominant_category"].classes_) if encoders and "dominant_category" in encoders else ["housewares"]

    with st.container():
        st.markdown("""
        <style>
        div[data-testid="stForm"] {
            border: none;
            box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06);
            border-radius: 12px;
            padding: 30px;
            background-color: #ffffff;
        }
        </style>
        """, unsafe_allow_html=True)
        with st.form("predict_form"):
            fc1, fc2, fc3 = st.columns(3)
            with fc1:
                cust_state = st.selectbox("Customer State", states, index=0)
                order_month = st.slider("Order Month", 1, 12, 6)
                total_items = st.number_input("Total Items", 1, 50, 2)
                total_price = st.number_input("Total Price (R$)", 1.0, 10000.0, 150.0)
            with fc2:
                seller_state = st.selectbox("Seller State", states, index=0)
                order_dow = st.slider("Day of Week (0=Mon)", 0, 6, 2)
                total_freight = st.number_input("Total Freight (R$)", 0.0, 500.0, 25.0)
                num_sellers = st.number_input("Distinct Sellers", 1, 10, 1)
            with fc3:
                category = st.selectbox("Dominant Category", categories, index=0)
                is_weekend = st.selectbox("Is Weekend?", [0, 1], index=0)

            st.markdown("<br>", unsafe_allow_html=True)
            submitted = st.form_submit_button("Predict Risk", type="primary", use_container_width=True)

    if submitted:
        avg_price = total_price / max(total_items, 1)
        avg_freight = total_freight / max(total_items, 1)
        fr_ratio = total_freight / max(total_price + total_freight, 0.01)
        quarter = (order_month - 1) // 3 + 1
        cross = 1 if cust_state != seller_state else 0

        result = predict_single_order(
            customer_state=cust_state, order_month=order_month, order_quarter=quarter,
            order_day_of_week=order_dow, order_is_weekend=is_weekend,
            total_payment_value=total_price + total_freight,
            total_items=total_items, total_price=total_price, total_freight=total_freight,
            avg_item_price=avg_price, avg_freight_per_item=avg_freight, freight_ratio=fr_ratio,
            dominant_category=category, num_distinct_sellers=num_sellers,
            primary_seller_state=seller_state, is_cross_state=cross,
        )

        if "error" in result:
            st.error(result["error"])
        else:
            tier = result["risk_tier"]
            color = RISK_COLORS.get(tier, C["PRIMARY"])
            prob = result["probability"]
            st.markdown(f"""
            <div style="background: {color}15; border-left: 6px solid {color};
                        border-radius: 8px; padding: 24px; margin: 24px 0;
                        box-shadow: 0 1px 3px rgba(0,0,0,0.05);">
                <h2 style="color: {color}; margin:0; font-size: 1.5rem;">Risk Level: {tier}</h2>
                <p style="color: #4b5563; font-size: 1.1rem; margin: 8px 0 0 0;">
                    Late delivery probability: <strong style="color: #111827;">{prob:.1%}</strong>
                </p>
            </div>
            """, unsafe_allow_html=True)
