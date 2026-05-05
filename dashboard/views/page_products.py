# views/page_products.py  –  Page 4: Product & Category Analysis

import plotly.graph_objects as go
import plotly.express as px
import streamlit as st
import pandas as pd
from views._chart_theme import COLORS as C, base_layout


def render(df_prod: pd.DataFrame, df_freight: pd.DataFrame):
    if df_prod.empty:
        st.warning("No product data available.")
        return

    c1, c2, c3, c4 = st.columns(4)
    with c1: st.metric("Categories", f"{len(df_prod)}")
    with c2: st.metric("Items Sold", f"{df_prod['total_items_sold'].sum():,.0f}")
    with c3: st.metric("Total Revenue", f"R$ {df_prod['total_revenue'].sum():,.0f}")
    with c4:
        if not df_freight.empty:
            avg_fr = (df_freight["total_freight_cost"].sum() / max(df_freight["total_revenue"].sum() + df_freight["total_freight_cost"].sum(), 1)) * 100
            st.metric("Avg Freight Ratio", f"{avg_fr:.1f}%")

    st.markdown("<br>", unsafe_allow_html=True)
    c_left, c_right = st.columns(2)

    with c_left:
        top15 = df_prod.nlargest(15, "total_revenue")
        fig_tree = px.treemap(top15, path=["product_category"], values="total_revenue",
                              color="total_revenue", color_continuous_scale=[C["PRIMARY"], C["ACCENT"]],
                              hover_data={"total_items_sold": True, "average_item_price": ":.2f"})
        fig_tree.update_layout(**base_layout("Top 15 Categories by Revenue"),
                               height=460, coloraxis_showscale=False)
        st.plotly_chart(fig_tree, width="stretch")

    with c_right:
        if not df_freight.empty:
            fig_sc = px.scatter(df_freight, x="avg_item_price", y="freight_ratio_pct",
                                size="total_items_sold", color="freight_ratio_pct",
                                color_continuous_scale=[C["SUCCESS"], C["WARNING"], C["DANGER"]],
                                hover_name="product_category",
                                labels={"avg_item_price": "Avg Price (R$)", "freight_ratio_pct": "Freight Ratio %"})
            fig_sc.add_hline(y=30, line_dash="dash", line_color=C["DANGER"],
                             annotation_text="Danger Zone (30%)", annotation_font_color=C["DANGER"])
            fig_sc.update_layout(**base_layout("Freight Ratio vs Price (Danger Zone)"),
                                 xaxis=dict(gridcolor=C["GRID"]),
                                 yaxis=dict(gridcolor=C["GRID"]),
                                 height=460)
            st.plotly_chart(fig_sc, width="stretch")

    if not df_freight.empty:
        top10_fr = df_freight.nlargest(10, "total_freight_burden_pct")
        fig_bar = go.Figure(go.Bar(
            y=top10_fr["product_category"], x=top10_fr["total_freight_burden_pct"],
            orientation="h", marker=dict(color=top10_fr["total_freight_burden_pct"],
                                          colorscale=[[0, C["WARNING"]], [1, C["DANGER"]]]),
            text=top10_fr["total_freight_burden_pct"].apply(lambda v: f"{v:.1f}%"), textposition="outside"))
        fig_bar.update_layout(**base_layout("Top 10 Categories by Freight Burden %"),
                              xaxis=dict(gridcolor=C["GRID"]),
                              yaxis=dict(autorange="reversed", gridcolor=C["GRID"]),
                              height=380)
        st.plotly_chart(fig_bar, width="stretch")

    with st.expander("View Product Data"):
        st.dataframe(df_prod.round(2), width="stretch", hide_index=True)
