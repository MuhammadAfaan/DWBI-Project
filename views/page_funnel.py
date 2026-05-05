# views/page_funnel.py  –  Page 6: Order Funnel & Revenue Leakage

import plotly.graph_objects as go
import streamlit as st
import pandas as pd
from views._chart_theme import COLORS as C, base_layout

STATUS_COLORS = {
    "delivered": C["SUCCESS"], "shipped": C["PRIMARY"], "approved": "#818cf8",
    "processing": C["ACCENT"], "invoiced": "#a78bfa",
    "canceled": C["DANGER"], "unavailable": C["WARNING"], "created": "#94a3b8",
}


def render(df: pd.DataFrame):
    if df.empty:
        st.warning("No funnel data available.")
        return

    total_orders = df["total_orders"].sum()
    total_rev = df["total_payment_value"].sum()
    lost_rev = df["lost_revenue_value"].sum()
    lost_orders = df["lost_order_count"].sum()

    c1, c2, c3, c4 = st.columns(4)
    with c1: st.metric("Total Orders", f"{total_orders:,.0f}")
    with c2: st.metric("Total Revenue", f"R$ {total_rev:,.0f}")
    with c3: st.metric("Lost Revenue", f"R$ {lost_rev:,.0f}",
                        delta=f"-{(lost_rev/max(total_rev,1))*100:.2f}%", delta_color="inverse")
    with c4: st.metric("Lost Orders", f"{lost_orders:,.0f}")

    st.markdown("<br>", unsafe_allow_html=True)
    c_left, c_right = st.columns(2)

    with c_left:
        df_sorted = df.sort_values("total_orders", ascending=False)
        colors = [STATUS_COLORS.get(s, C["PRIMARY"]) for s in df_sorted["order_status"]]
        fig = go.Figure(go.Funnel(
            y=df_sorted["order_status"], x=df_sorted["total_orders"],
            textinfo="value+percent initial",
            marker=dict(color=colors),
            connector=dict(line=dict(color="rgba(0,0,0,0.05)", width=1)),
        ))
        fig.update_layout(**base_layout("Order Status Funnel"), height=440)
        st.plotly_chart(fig, width="stretch")

    with c_right:
        fig2 = go.Figure(go.Pie(
            labels=df["order_status"], values=df["total_orders"],
            hole=0.55, marker=dict(colors=[STATUS_COLORS.get(s, C["PRIMARY"]) for s in df["order_status"]]),
            textinfo="percent+label", textfont=dict(size=11),
        ))
        fig2.update_layout(**base_layout("Status Distribution"), showlegend=False, height=440)
        st.plotly_chart(fig2, width="stretch")

    with st.expander("View Funnel Data"):
        display = df[["order_status", "total_orders", "total_payment_value",
                       "avg_order_value", "status_share_pct", "lost_revenue_value", "lost_order_count"]].copy()
        display.columns = ["Status", "Orders", "Payment Value", "Avg Value", "Share %", "Lost Revenue", "Lost Orders"]
        st.dataframe(display.round(2), width="stretch", hide_index=True)
