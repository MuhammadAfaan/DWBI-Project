# views/page_logistics.py  –  Page 2: Logistics & Delivery Health
# Uses GeoJSON for Brazilian state choropleth map

import json
from urllib.request import urlopen
import plotly.graph_objects as go
import plotly.express as px
import streamlit as st
import pandas as pd
from views._chart_theme import COLORS as C, base_layout

BR_STATES = {
    "AC":"Acre","AL":"Alagoas","AP":"Amapá","AM":"Amazonas","BA":"Bahia",
    "CE":"Ceará","DF":"Distrito Federal","ES":"Espírito Santo","GO":"Goiás",
    "MA":"Maranhão","MT":"Mato Grosso","MS":"Mato Grosso do Sul",
    "MG":"Minas Gerais","PA":"Pará","PB":"Paraíba","PR":"Paraná",
    "PE":"Pernambuco","PI":"Piauí","RJ":"Rio de Janeiro",
    "RN":"Rio Grande do Norte","RS":"Rio Grande do Sul","RO":"Rondônia",
    "RR":"Roraima","SC":"Santa Catarina","SP":"São Paulo","SE":"Sergipe","TO":"Tocantins",
}

GEOJSON_URL = "https://raw.githubusercontent.com/codeforamerica/click_that_hood/master/public/data/brazil-states.geojson"

@st.cache_data(show_spinner=False)
def _load_geojson():
    try:
        with urlopen(GEOJSON_URL) as resp:
            return json.loads(resp.read().decode())
    except Exception:
        return None


def render(df: pd.DataFrame):
    if df.empty:
        st.warning("No logistics data available.")
        return

    df = df.copy()
    df["state_name"] = df["customer_state"].map(BR_STATES).fillna(df["customer_state"])

    c1, c2, c3, c4 = st.columns(4)
    with c1:
        st.metric("Total Delivered", f"{df['total_orders_delivered'].sum():,.0f}")
    with c2:
        avg_days = (df["avg_delivery_days"] * df["total_orders_delivered"]).sum() / df["total_orders_delivered"].sum()
        st.metric("Avg Delivery Days", f"{avg_days:.1f}")
    with c3:
        total_late = df["late_deliveries"].sum()
        total_all = df["total_orders_delivered"].sum()
        st.metric("Late Deliveries", f"{total_late:,.0f}", delta=f"{(total_late/total_all)*100:.1f}% rate", delta_color="inverse")
    with c4:
        worst = df.loc[df["late_delivery_rate_pct"].idxmax()]
        st.metric("Highest Late Rate", f"{worst['customer_state']} ({worst['late_delivery_rate_pct']:.1f}%)")

    st.markdown("<br>", unsafe_allow_html=True)
    col_map, col_bar = st.columns([3, 2])

    with col_map:
        geojson = _load_geojson()
        if geojson:
            fig_map = px.choropleth(
                df, geojson=geojson, locations="customer_state",
                featureidkey="properties.sigla",
                color="late_delivery_rate_pct",
                hover_name="state_name",
                hover_data={"total_orders_delivered": True, "avg_delivery_days": ":.1f",
                            "late_delivery_rate_pct": ":.1f", "customer_state": False},
                color_continuous_scale=["#10B981", "#F59E0B", "#EF4444"],
                labels={"late_delivery_rate_pct": "Late %"},
            )
            fig_map.update_geos(fitbounds="locations", visible=False)
            fig_map.update_layout(
                **base_layout("Late Delivery Rate by State"),
                height=460, coloraxis_colorbar=dict(title="Late %", ticksuffix="%"),
            )
            st.plotly_chart(fig_map, width="stretch")
        else:
            st.info("Map unavailable (no internet). Showing bar chart instead.")

    with col_bar:
        top10 = df.nlargest(10, "late_delivery_rate_pct")
        fig_bar = go.Figure(go.Bar(
            y=top10["customer_state"], x=top10["late_delivery_rate_pct"],
            orientation="h",
            marker=dict(color=top10["late_delivery_rate_pct"],
                        colorscale=[[0, C["WARNING"]], [1, C["DANGER"]]]),
            text=top10["late_delivery_rate_pct"].apply(lambda v: f"{v:.1f}%"),
            textposition="outside",
        ))
        fig_bar.update_layout(
            **base_layout("Top 10 Problem States"),
            yaxis=dict(autorange="reversed", gridcolor=C["GRID"]),
            xaxis=dict(title="Late Delivery Rate %", gridcolor=C["GRID"]),
            height=460,
        )
        st.plotly_chart(fig_bar, width="stretch")

    df["on_time"] = df["total_orders_delivered"] - df["late_deliveries"]
    df_sorted = df.sort_values("total_orders_delivered", ascending=False).head(15)
    fig_stack = go.Figure()
    fig_stack.add_trace(go.Bar(x=df_sorted["customer_state"], y=df_sorted["on_time"],
                               name="On-Time", marker_color=C["SUCCESS"]))
    fig_stack.add_trace(go.Bar(x=df_sorted["customer_state"], y=df_sorted["late_deliveries"],
                               name="Late", marker_color=C["DANGER"]))
    fig_stack.update_layout(
        **base_layout("On-Time vs Late Deliveries (Top 15 by Volume)"),
        barmode="stack",
        xaxis=dict(gridcolor=C["GRID"]),
        yaxis=dict(title="Orders", gridcolor=C["GRID"]),
        legend=dict(x=0.8, y=1.05, orientation="h"),
        height=380,
    )
    st.plotly_chart(fig_stack, width="stretch")

    with st.expander("View Raw Data"):
        st.dataframe(df[["customer_state", "state_name", "total_orders_delivered",
                         "avg_delivery_days", "late_deliveries", "late_delivery_rate_pct"]].round(2),
                     width="stretch", hide_index=True)
