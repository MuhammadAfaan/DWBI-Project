# ──────────────────────────────────────────────────────────────
# ml/train.py  –  Run this ONCE to train and persist the model
# ──────────────────────────────────────────────────────────────
# Usage:   python -m ml.train
# Output:  models/random_forest.pkl
#          models/label_encoders.pkl
#          models/model_metrics.pkl
#          models/feature_importance.pkl
# ──────────────────────────────────────────────────────────────

import os, sys, json, warnings
warnings.filterwarnings("ignore")

import numpy as np
import pandas as pd
import joblib

from sklearn.model_selection import train_test_split, cross_val_score
from sklearn.ensemble import RandomForestClassifier
from sklearn.linear_model import LogisticRegression
from sklearn.preprocessing import LabelEncoder
from sklearn.metrics import (
    accuracy_score, precision_score, recall_score, f1_score,
    roc_auc_score, confusion_matrix, classification_report,
)

# ── Resolve project root so imports work when run as `python -m ml.train` ──
PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, PROJECT_ROOT)

from config import CONNECTION_STRING

MODELS_DIR = os.path.join(PROJECT_ROOT, "models")
os.makedirs(MODELS_DIR, exist_ok=True)


# ─────────────────────────────────────────────────────────────
# 1.  EXTRACT
# ─────────────────────────────────────────────────────────────
def extract_features() -> pd.DataFrame:
    """Pull ML features from Gold layer via pyodbc."""
    import pyodbc
    print("\n[1/5] 🔍 Connecting to SSMS to extract features...")
    sql_path = os.path.join(PROJECT_ROOT, "sql", "ml_feature_query.sql")
    with open(sql_path, "r", encoding="utf-8") as f:
        query = f.read()
    
    print("      (This may take a minute depending on your dataset size...)")
    conn = pyodbc.connect(CONNECTION_STRING)
    df = pd.read_sql(query, conn)
    conn.close()
    print(f"✅  Extraction complete: {len(df):,} rows found.")
    print(f"📊  Late delivery rate in dataset: {df['is_late_delivery'].mean()*100:.1f}%")
    return df


# ─────────────────────────────────────────────────────────────
# 2.  PREPROCESS
# ─────────────────────────────────────────────────────────────
CATEGORICAL_COLS = ["customer_state", "dominant_category", "primary_seller_state"]
NUMERIC_COLS = [
    "order_month", "order_quarter", "order_day_of_week", "order_is_weekend",
    "total_payment_value", "total_items", "total_price", "total_freight",
    "avg_item_price", "avg_freight_per_item", "freight_ratio",
    "num_distinct_sellers", "is_cross_state",
]
TARGET = "is_late_delivery"


def preprocess(df: pd.DataFrame):
    """Clean, encode, and split into train/test."""
    print("\n[2/5] 🛠️  Preprocessing data (handling nulls & encoding)...")
    df = df.copy()

    # Drop order_id (identifier, not a feature)
    df.drop(columns=["order_id"], inplace=True, errors="ignore")

    # Fill missing categoricals
    for col in CATEGORICAL_COLS:
        df[col] = df[col].fillna("Unknown")

    # Fill missing numerics with median
    for col in NUMERIC_COLS:
        if col in df.columns:
            df[col] = pd.to_numeric(df[col], errors="coerce")
            df[col] = df[col].fillna(df[col].median())

    # Label-encode categoricals
    encoders = {}
    for col in CATEGORICAL_COLS:
        le = LabelEncoder()
        df[col] = le.fit_transform(df[col].astype(str))
        encoders[col] = le

    # Prepare X, y
    feature_cols = CATEGORICAL_COLS + NUMERIC_COLS
    X = df[feature_cols].values
    y = df[TARGET].astype(int).values

    # Stratified split
    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, random_state=42, stratify=y
    )

    print(f"[preprocess]  Train: {len(X_train):,}  |  Test: {len(X_test):,}")
    print(f"[preprocess]  Train late rate: {y_train.mean()*100:.1f}%  |  Test late rate: {y_test.mean()*100:.1f}%")

    return X_train, X_test, y_train, y_test, encoders, feature_cols


# ─────────────────────────────────────────────────────────────
# 3.  TRAIN & EVALUATE
# ─────────────────────────────────────────────────────────────
def evaluate_model(name, model, X_test, y_test):
    """Return a dict of metrics for *model*."""
    y_pred = model.predict(X_test)
    y_proba = model.predict_proba(X_test)[:, 1] if hasattr(model, "predict_proba") else None

    metrics = {
        "model": name,
        "accuracy":  round(accuracy_score(y_test, y_pred), 4),
        "precision": round(precision_score(y_test, y_pred, zero_division=0), 4),
        "recall":    round(recall_score(y_test, y_pred, zero_division=0), 4),
        "f1":        round(f1_score(y_test, y_pred, zero_division=0), 4),
    }
    if y_proba is not None:
        metrics["auc_roc"] = round(roc_auc_score(y_test, y_proba), 4)
    else:
        metrics["auc_roc"] = None

    cm = confusion_matrix(y_test, y_pred)
    metrics["confusion_matrix"] = cm.tolist()

    print(f"\n{'='*50}")
    print(f"  {name}")
    print(f"{'='*50}")
    print(f"  Accuracy : {metrics['accuracy']}")
    print(f"  Precision: {metrics['precision']}")
    print(f"  Recall   : {metrics['recall']}")
    print(f"  F1       : {metrics['f1']}")
    print(f"  AUC-ROC  : {metrics['auc_roc']}")
    print(f"  Confusion Matrix:\n{cm}")
    print(classification_report(y_test, y_pred, target_names=["On-Time", "Late"]))

    return metrics


def train():
    """Full pipeline: extract → preprocess → train → evaluate → save."""

    # Extract
    df = extract_features()

    # Preprocess
    X_train, X_test, y_train, y_test, encoders, feature_cols = preprocess(df)

    # ── Random Forest ────────────────────────────────────────
    print("\n[3/5] 🌲 Training Random Forest Classifier...")
    rf = RandomForestClassifier(
        n_estimators=200,
        max_depth=15,
        min_samples_split=10,
        min_samples_leaf=5,
        class_weight="balanced",
        random_state=42,
        n_jobs=-1,
        verbose=2  # Added verbosity to show progress
    )
    rf.fit(X_train, y_train)
    
    print("\n" + "▼"*50)
    print("  [TRAINING SET PERFORMANCE] - Random Forest")
    print("  (How well it memorized the data it learned from)")
    evaluate_model("Random Forest (Train Data)", rf, X_train, y_train)
    
    print("\n" + "▼"*50)
    print("  [TESTING SET PERFORMANCE] - Random Forest")
    print("  (How well it predicts on completely new, unseen data)")
    rf_metrics = evaluate_model("Random Forest (Test Data)", rf, X_test, y_test)

    # Cross-validation
    print("      🔄 Running Cross-Validation (5-fold)...")
    cv_scores = cross_val_score(rf, X_train, y_train, cv=5, scoring="f1")
    rf_metrics["cv_f1_mean"] = round(cv_scores.mean(), 4)
    rf_metrics["cv_f1_std"]  = round(cv_scores.std(), 4)
    print(f"  CV F1: {cv_scores.mean():.4f} ± {cv_scores.std():.4f}")

    # ── Logistic Regression (baseline) ───────────────────────
    print("\n[4/5] 📈 Training Logistic Regression (Baseline)...")
    lr = LogisticRegression(
        max_iter=1000,
        class_weight="balanced",
        random_state=42,
    )
    lr.fit(X_train, y_train)
    print("\n  [TRAINING SET] - Logistic Regression")
    evaluate_model("Logistic Regression (Train Data)", lr, X_train, y_train)
    print("\n  [TESTING SET] - Logistic Regression")
    lr_metrics = evaluate_model("Logistic Regression (Test Data)", lr, X_test, y_test)

    # ── Feature importance (from RF) ─────────────────────────
    fi = pd.DataFrame({
        "feature": feature_cols,
        "importance": rf.feature_importances_,
    }).sort_values("importance", ascending=False).reset_index(drop=True)
    print(f"\nTop 10 Features:\n{fi.head(10).to_string(index=False)}")

    # ── Save artefacts ───────────────────────────────────────
    print("\n[5/5] 💾 Saving models and artifacts...")
    joblib.dump(rf, os.path.join(MODELS_DIR, "random_forest.pkl"))
    joblib.dump(lr, os.path.join(MODELS_DIR, "logistic_regression.pkl"))
    joblib.dump(encoders, os.path.join(MODELS_DIR, "label_encoders.pkl"))
    joblib.dump(feature_cols, os.path.join(MODELS_DIR, "feature_columns.pkl"))

    # Save metrics as JSON-friendly pkl
    all_metrics = {"random_forest": rf_metrics, "logistic_regression": lr_metrics}
    joblib.dump(all_metrics, os.path.join(MODELS_DIR, "model_metrics.pkl"))

    # Save feature importance
    fi.to_csv(os.path.join(MODELS_DIR, "feature_importance.csv"), index=False)
    joblib.dump(fi, os.path.join(MODELS_DIR, "feature_importance.pkl"))

    # ── Score ALL orders and save predictions ────────────────
    print("\n[save]  Scoring all orders for dashboard …")
    df_score = df.copy()
    df_score_clean = df_score.drop(columns=["order_id", TARGET], errors="ignore")

    for col in CATEGORICAL_COLS:
        df_score_clean[col] = df_score_clean[col].fillna("Unknown")
        le = encoders[col]
        # Handle unseen labels gracefully
        df_score_clean[col] = df_score_clean[col].astype(str).apply(
            lambda x: le.transform([x])[0] if x in le.classes_ else -1
        )

    for col in NUMERIC_COLS:
        if col in df_score_clean.columns:
            df_score_clean[col] = pd.to_numeric(df_score_clean[col], errors="coerce")
            df_score_clean[col] = df_score_clean[col].fillna(df_score_clean[col].median())

    X_all = df_score_clean[feature_cols].values
    probabilities = rf.predict_proba(X_all)[:, 1]
    predictions = rf.predict(X_all)

    results = pd.DataFrame({
        "order_id": df["order_id"],
        "actual_late": df[TARGET].astype(int),
        "predicted_late": predictions,
        "predicted_probability": np.round(probabilities, 4),
        "risk_tier": pd.cut(
            probabilities,
            bins=[-0.01, 0.3, 0.6, 1.01],
            labels=["Low", "Medium", "High"],
        ),
        "customer_state": df["customer_state"],
        "dominant_category": df["dominant_category"],
        "is_cross_state": df["is_cross_state"],
    })
    results.to_csv(os.path.join(MODELS_DIR, "ml_predictions.csv"), index=False)
    print(f"[save]  {len(results):,} predictions saved to models/ml_predictions.csv")

    print("\n✅  Training complete. All artefacts saved to models/")


# ─────────────────────────────────────────────────────────────
if __name__ == "__main__":
    train()
