# views/page_executive.py  –  Page 1: Executive Overview

import plotly.graph_objects as go
import streamlit as st
import pandas as pd
from views._chart_theme import COLORS as C, base_layout, PALETTE


def render(df: pd.DataFrame):
    if df.empty:
        st.warning("No sales data available.")
        return

    df = df.sort_values(["year", "month"]).copy()
    df["period"] = df["year"].astype(str) + "-" + df["month"].astype(str).str.zfill(2)

    latest = df.iloc[-1]
    prev = df.iloc[-2] if len(df) > 1 else latest

    c1, c2, c3, c4 = st.columns(4)
    with c1:
        delta_rev = ((latest["total_gross_revenue"] - prev["total_gross_revenue"]) / max(prev["total_gross_revenue"], 1)) * 100
        st.metric("Gross Revenue", f"R$ {latest['total_gross_revenue']:,.0f}", delta=f"{delta_rev:+.1f}%")
    with c2:
        st.metric("Total Orders", f"{latest['total_orders']:,.0f}", delta=f"{latest['total_orders'] - prev['total_orders']:+,.0f}")
    with c3:
        delta_aov = ((latest["average_order_value"] - prev["average_order_value"]) / max(prev["average_order_value"], 1)) * 100
        st.metric("Avg Order Value", f"R$ {latest['average_order_value']:,.2f}", delta=f"{delta_aov:+.1f}%")
    with c4:
        st.metric("Lifetime Revenue", f"R$ {df['total_gross_revenue'].sum():,.0f}")

    st.markdown("<br>", unsafe_allow_html=True)
    col_left, col_right = st.columns([2, 1])

    with col_left:
        fig = go.Figure()
        fig.add_trace(go.Scatter(
            x=df["period"], y=df["total_gross_revenue"],
            mode="lines+markers", name="Gross Revenue",
            line=dict(color=C["PRIMARY"], width=3, shape="spline"), marker=dict(size=5),
            fill="tozeroy", fillcolor="rgba(37,99,235,0.08)",
        ))
        fig.add_trace(go.Bar(
            x=df["period"], y=df["total_orders"],
            name="Orders", yaxis="y2",
            marker_color=C["ACCENT"], opacity=0.35,
        ))
        fig.update_layout(
            **base_layout("Revenue Trend & Order Volume"),
            xaxis=dict(gridcolor=C["GRID"], showline=False),
            yaxis=dict(title="Revenue (R$)", gridcolor=C["GRID"], showline=False),
            yaxis2=dict(title="Orders", overlaying="y", side="right", showgrid=False),
            legend=dict(x=0.5, y=-0.15, xanchor="center", orientation="h", bgcolor="rgba(0,0,0,0)"),
            height=420,
        )
        st.plotly_chart(fig, width="stretch")

    with col_right:
        total_product = df["total_product_revenue"].sum()
        total_freight = df["total_freight_revenue"].sum()
        fig_donut = go.Figure(go.Pie(
            labels=["Product Revenue", "Freight Revenue"],
            values=[total_product, total_freight],
            hole=0.6,
            marker=dict(colors=[C["PRIMARY"], C["ACCENT"]]),
            textinfo="percent+label", textfont=dict(size=11),
        ))
        fig_donut.update_layout(**base_layout("Revenue Composition"), showlegend=False, height=420)
        st.plotly_chart(fig_donut, width="stretch")

    fig_aov = go.Figure(go.Scatter(
        x=df["period"], y=df["average_order_value"],
        mode="lines+markers", name="AOV",
        line=dict(color=C["SUCCESS"], width=2.5, dash="dot", shape="spline"),
        marker=dict(size=5, color=C["SUCCESS"]),
    ))
    fig_aov.update_layout(
        **base_layout("Average Order Value Over Time"),
        xaxis=dict(gridcolor=C["GRID"], showline=False),
        yaxis=dict(title="AOV (R$)", gridcolor=C["GRID"], showline=False),
        height=320,
    )
    st.plotly_chart(fig_aov, width="stretch")

    with st.expander("View Raw Data"):
        st.dataframe(
            df[["period", "month_name", "total_orders", "total_product_revenue",
                "total_freight_revenue", "total_gross_revenue", "average_order_value"]],
            width="stretch", hide_index=True,
        )
