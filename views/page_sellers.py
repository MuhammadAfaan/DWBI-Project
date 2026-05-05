# views/page_sellers.py  –  Page 5: Seller Performance

import plotly.graph_objects as go
import plotly.express as px
import streamlit as st
import pandas as pd
from views._chart_theme import COLORS as C, base_layout


def render(df: pd.DataFrame):
    if df.empty:
        st.warning("No seller data available.")
        return

    c1, c2, c3, c4 = st.columns(4)
    with c1: st.metric("Total Sellers", f"{len(df):,}")
    with c2: st.metric("Orders Fulfilled", f"{df['total_orders_fulfilled'].sum():,.0f}")
    with c3: st.metric("Items Sold", f"{df['total_items_sold'].sum():,.0f}")
    with c4: st.metric("Revenue", f"R$ {df['total_revenue_generated'].sum():,.0f}")

    st.markdown("<br>", unsafe_allow_html=True)
    c_left, c_right = st.columns(2)

    with c_left:
        top20 = df.nlargest(20, "total_revenue_generated")
        top20["short_id"] = top20["seller_id"].str[:8] + "…"
        fig = go.Figure(go.Bar(
            x=top20["total_revenue_generated"], y=top20["short_id"],
            orientation="h",
            marker=dict(color=top20["total_revenue_generated"],
                        colorscale=[[0, C["PRIMARY"]], [1, C["ACCENT"]]]),
            text=top20["total_revenue_generated"].apply(lambda v: f"R$ {v:,.0f}"),
            textposition="outside"))
        fig.update_layout(**base_layout("Top 20 Sellers by Revenue"),
                          xaxis=dict(gridcolor=C["GRID"]),
                          yaxis=dict(autorange="reversed", gridcolor=C["GRID"]),
                          height=560)
        st.plotly_chart(fig, width="stretch")

    with c_right:
        state_counts = df.groupby("seller_state").agg(
            sellers=("seller_id", "nunique"),
            revenue=("total_revenue_generated", "sum")).reset_index()
        fig2 = go.Figure(go.Bar(
            x=state_counts.sort_values("sellers", ascending=False)["seller_state"],
            y=state_counts.sort_values("sellers", ascending=False)["sellers"],
            marker_color=C["PRIMARY"],
            text=state_counts.sort_values("sellers", ascending=False)["sellers"],
            textposition="outside"))
        fig2.update_layout(**base_layout("Sellers by State"),
                           xaxis=dict(gridcolor=C["GRID"]),
                           yaxis=dict(title="# Sellers", gridcolor=C["GRID"]),
                           height=300)
        st.plotly_chart(fig2, width="stretch")

        fig3 = px.scatter(df, x="total_items_sold", y="total_revenue_generated",
                          color="seller_state", hover_data={"seller_id": True},
                          labels={"total_items_sold": "Items Sold", "total_revenue_generated": "Revenue (R$)"})
        fig3.update_layout(**base_layout("Seller Efficiency: Items vs Revenue"),
                           xaxis=dict(gridcolor=C["GRID"]),
                           yaxis=dict(gridcolor=C["GRID"]),
                           showlegend=False, height=260)
        st.plotly_chart(fig3, width="stretch")

    with st.expander("View Seller Data"):
        st.dataframe(df.round(2), width="stretch", hide_index=True)
