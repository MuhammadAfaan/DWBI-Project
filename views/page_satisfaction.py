# views/page_satisfaction.py  –  Page 3: Delivery ↔ Satisfaction

import plotly.graph_objects as go
import plotly.express as px
import streamlit as st
import pandas as pd
from views._chart_theme import COLORS as C, base_layout

BUCKET_ORDER = ["Fast (<=7 days)", "Normal (8-14 days)", "Slow (15+ days)", "Late"]
BUCKET_COLORS = {"Fast (<=7 days)": C["SUCCESS"], "Normal (8-14 days)": C["PRIMARY"],
                 "Slow (15+ days)": C["WARNING"], "Late": C["DANGER"]}


def render(df_corr: pd.DataFrame, df_sat: pd.DataFrame):
    if df_corr.empty:
        st.warning("No correlation data available.")
        return

    late = df_corr[df_corr["delivery_bucket"] == "Late"]
    fast = df_corr[df_corr["delivery_bucket"] == "Fast (<=7 days)"]
    if not late.empty and not fast.empty:
        l1 = late.iloc[0]["one_star_rate_pct"]
        f1 = fast.iloc[0]["one_star_rate_pct"]
        st.info(f"**Key Insight:** Late deliveries have a **{l1:.1f}%** 1-star rate — "
                f"**{l1/max(f1,0.01):.1f}x higher** than fast deliveries ({f1:.1f}%).")

    cols = st.columns(min(len(df_corr), 4))
    for i, (_, row) in enumerate(df_corr.iterrows()):
        b = row["delivery_bucket"]
        with cols[i % len(cols)]:
            st.metric(f"{b}", f"{row['avg_review_score']:.2f} Avg Score",
                      delta=f"{row['total_orders']:,.0f} orders", delta_color="off")

    st.markdown("<br>", unsafe_allow_html=True)
    c1, c2 = st.columns(2)

    with c1:
        dfs = df_corr.copy()
        dfs["delivery_bucket"] = pd.Categorical(dfs["delivery_bucket"], BUCKET_ORDER, ordered=True)
        dfs = dfs.sort_values("delivery_bucket")
        fig = go.Figure(go.Bar(
            x=dfs["delivery_bucket"], y=dfs["avg_review_score"],
            marker_color=[BUCKET_COLORS.get(b, C["PRIMARY"]) for b in dfs["delivery_bucket"]],
            text=dfs["avg_review_score"].apply(lambda v: f"{v:.2f}"), textposition="outside"))
        fig.update_layout(**base_layout("Avg Review Score by Delivery Speed"),
                          xaxis=dict(gridcolor=C["GRID"]),
                          yaxis=dict(title="Avg Score", range=[0, 5.5], gridcolor=C["GRID"]),
                          height=420)
        st.plotly_chart(fig, width="stretch")

    with c2:
        fig2 = go.Figure()
        fig2.add_trace(go.Bar(x=dfs["delivery_bucket"], y=dfs["five_star_rate_pct"],
                              name="5-Star %", marker_color=C["SUCCESS"]))
        fig2.add_trace(go.Bar(x=dfs["delivery_bucket"], y=dfs["one_star_rate_pct"],
                              name="1-Star %", marker_color=C["DANGER"]))
        fig2.update_layout(**base_layout("5-Star vs 1-Star Rate by Delivery Speed"),
                           barmode="group",
                           xaxis=dict(gridcolor=C["GRID"]),
                           yaxis=dict(title="%", gridcolor=C["GRID"]),
                           legend=dict(x=0.6, y=1.05, orientation="h"),
                           height=420)
        st.plotly_chart(fig2, width="stretch")

    if not df_sat.empty:
        st.markdown("### State-Level Satisfaction")
        fig3 = px.scatter(df_sat, x="average_review_score", y="critical_dissatisfaction_rate_pct",
                          size="total_reviews", color="average_review_score",
                          color_continuous_scale=[C["DANGER"], C["WARNING"], C["SUCCESS"]],
                          hover_name="customer_state",
                          labels={"average_review_score": "Avg Score",
                                  "critical_dissatisfaction_rate_pct": "1-Star Rate %"})
        fig3.update_layout(**base_layout("State: Avg Score vs Dissatisfaction Rate"),
                           xaxis=dict(gridcolor=C["GRID"]),
                           yaxis=dict(gridcolor=C["GRID"]),
                           height=420)
        for _, r in df_sat.iterrows():
            fig3.add_annotation(x=r["average_review_score"], y=r["critical_dissatisfaction_rate_pct"],
                                text=r["customer_state"], showarrow=False,
                                font=dict(size=9, color=C["TEXT"]), yshift=12)
        st.plotly_chart(fig3, width="stretch")

    with st.expander("View Raw Data"):
        st.dataframe(df_corr.round(2), width="stretch", hide_index=True)
