# ──────────────────────────────────────────────────────────────
# views/_chart_theme.py  –  Shared Plotly theme for light mode
# ──────────────────────────────────────────────────────────────
# Import this in every page file:
#   from views._chart_theme import COLORS, base_layout
# ──────────────────────────────────────────────────────────────

COLORS = dict(
    PRIMARY   = "#2563EB", # Blue 600
    SECONDARY = "#3B82F6", # Blue 500
    ACCENT    = "#0EA5E9", # Sky 500
    SUCCESS   = "#10B981", # Emerald 500
    WARNING   = "#F59E0B", # Amber 500
    DANGER    = "#EF4444", # Red 500
    GRID      = "rgba(0,0,0,0.05)",
    TEXT      = "#4B5563", # Gray 600
    BG        = "rgba(0,0,0,0)",
)

# Curated palette for multi-series charts
PALETTE = ["#2563EB", "#0EA5E9", "#10B981", "#F59E0B", "#8B5CF6",
           "#F43F5E", "#06B6D4", "#D946EF", "#F97316", "#14B8A6"]


def base_layout(title: str = "") -> dict:
    """Base Plotly layout — NO xaxis/yaxis/legend, set those per chart."""
    return dict(
        title=dict(text=title, font=dict(size=18, color="#111827", family="Inter, sans-serif"), pad=dict(b=15)),
        paper_bgcolor=COLORS["BG"],
        plot_bgcolor=COLORS["BG"],
        font=dict(color=COLORS["TEXT"], family="Inter, sans-serif", size=12),
        margin=dict(l=40, r=20, t=65, b=40),
        hoverlabel=dict(bgcolor="white", font_size=13, font_family="Inter, sans-serif"),
    )
