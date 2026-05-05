# ──────────────────────────────────────────────────────────────
# ml/predict.py  –  Load saved model and score new data
# ──────────────────────────────────────────────────────────────
# Used by pages/page_ml.py for:
#   1. Loading pre-computed predictions  (bulk)
#   2. Live single-order prediction      (interactive form)
# ──────────────────────────────────────────────────────────────

import os
import numpy as np
import pandas as pd
import joblib

PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MODELS_DIR = os.path.join(PROJECT_ROOT, "models")


def _load_artifact(name):
    path = os.path.join(MODELS_DIR, name)
    if not os.path.exists(path):
        return None
    return joblib.load(path)


def load_model():
    """Load the trained Random Forest model."""
    return _load_artifact("random_forest.pkl")


def load_encoders():
    """Load the fitted LabelEncoders dict."""
    return _load_artifact("label_encoders.pkl")


def load_feature_columns():
    """Load the ordered list of feature column names."""
    return _load_artifact("feature_columns.pkl")


def load_metrics():
    """Load the evaluation metrics dict."""
    return _load_artifact("model_metrics.pkl")


def load_feature_importance():
    """Load feature importance DataFrame."""
    fi = _load_artifact("feature_importance.pkl")
    if fi is None:
        csv_path = os.path.join(MODELS_DIR, "feature_importance.csv")
        if os.path.exists(csv_path):
            fi = pd.read_csv(csv_path)
    return fi


def load_predictions():
    """Load the bulk predictions CSV generated during training."""
    csv_path = os.path.join(MODELS_DIR, "ml_predictions.csv")
    if not os.path.exists(csv_path):
        return None
    return pd.read_csv(csv_path)


def predict_single_order(
    customer_state: str,
    order_month: int,
    order_quarter: int,
    order_day_of_week: int,
    order_is_weekend: int,
    total_payment_value: float,
    total_items: int,
    total_price: float,
    total_freight: float,
    avg_item_price: float,
    avg_freight_per_item: float,
    freight_ratio: float,
    dominant_category: str,
    num_distinct_sellers: int,
    primary_seller_state: str,
    is_cross_state: int,
) -> dict:
    """
    Score a single order and return prediction + probability + risk tier.
    Returns dict with keys: predicted_late, probability, risk_tier
    """
    model = load_model()
    encoders = load_encoders()
    feature_cols = load_feature_columns()

    if model is None or encoders is None or feature_cols is None:
        return {"error": "Model not trained yet. Run `python -m ml.train` first."}

    # Encode categorical features
    cat_values = {
        "customer_state": customer_state,
        "dominant_category": dominant_category,
        "primary_seller_state": primary_seller_state,
    }
    encoded_cats = {}
    for col, val in cat_values.items():
        le = encoders.get(col)
        if le is not None and val in le.classes_:
            encoded_cats[col] = le.transform([val])[0]
        else:
            encoded_cats[col] = -1  # unseen label

    # Build feature vector in the same order as training
    feature_map = {
        "customer_state": encoded_cats["customer_state"],
        "dominant_category": encoded_cats["dominant_category"],
        "primary_seller_state": encoded_cats["primary_seller_state"],
        "order_month": order_month,
        "order_quarter": order_quarter,
        "order_day_of_week": order_day_of_week,
        "order_is_weekend": order_is_weekend,
        "total_payment_value": total_payment_value,
        "total_items": total_items,
        "total_price": total_price,
        "total_freight": total_freight,
        "avg_item_price": avg_item_price,
        "avg_freight_per_item": avg_freight_per_item,
        "freight_ratio": freight_ratio,
        "num_distinct_sellers": num_distinct_sellers,
        "is_cross_state": is_cross_state,
    }

    X = np.array([[feature_map[col] for col in feature_cols]])
    prediction = model.predict(X)[0]
    probability = model.predict_proba(X)[0][1]

    if probability > 0.6:
        risk_tier = "High"
    elif probability > 0.3:
        risk_tier = "Medium"
    else:
        risk_tier = "Low"

    return {
        "predicted_late": int(prediction),
        "probability": round(float(probability), 4),
        "risk_tier": risk_tier,
    }
