# ──────────────────────────────────────────────────────────────
# config.py  –  Single source of truth for DB connection
# ──────────────────────────────────────────────────────────────
# Update SERVER to match your SSMS instance name.
# Run `SELECT @@SERVERNAME` in SSMS if you're unsure.
# ──────────────────────────────────────────────────────────────

SERVER   = r".\SQLEXPRESS"   # ← Matches your SSMS screenshot
DATABASE = "OlistDW"
DRIVER   = "ODBC Driver 17 for SQL Server"

CONNECTION_STRING = (
    f"DRIVER={{{DRIVER}}};"
    f"SERVER={SERVER};"
    f"DATABASE={DATABASE};"
    f"Trusted_Connection=yes;"
)
