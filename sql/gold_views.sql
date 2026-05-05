USE OlistDW;
GO

-- ==============================================================================
-- VIEW 1: MONTHLY SALES TREND (The Executive Overview)
-- Purpose: Tracks revenue growth, total orders, and Average Order Value over time.
-- ==============================================================================
DROP VIEW IF EXISTS gold.vw_kpi_monthly_sales_trend;
GO

CREATE VIEW gold.vw_kpi_monthly_sales_trend AS
SELECT 
    d.year,
    d.month,
    d.month_name,
    COUNT(DISTINCT oi.order_id) AS total_orders,
    SUM(oi.price) AS total_product_revenue,
    SUM(oi.freight_value) AS total_freight_revenue,
    SUM(oi.price + oi.freight_value) AS total_gross_revenue,
    SUM(oi.price + oi.freight_value) / NULLIF(COUNT(DISTINCT oi.order_id), 0) AS average_order_value
FROM gold.fact_order_items oi
JOIN gold.dim_date d ON oi.order_date_key = d.date_key
GROUP BY 
    d.year, d.month, d.month_name;
GO

-- ==============================================================================
-- VIEW 2: PRODUCT CATEGORY PERFORMANCE (The Inventory View)
-- ==============================================================================
DROP VIEW IF EXISTS gold.vw_kpi_product_performance;
GO

CREATE VIEW gold.vw_kpi_product_performance AS
SELECT 
    ISNULL(p.product_category_english, 'Unknown Category') AS product_category,
    COUNT(oi.order_item_id) AS total_items_sold,
    SUM(oi.price) AS total_revenue,
    AVG(oi.price) AS average_item_price,
    AVG(oi.freight_value) AS average_freight_cost
FROM gold.fact_order_items oi
JOIN gold.dim_product p ON oi.product_sk = p.product_sk
GROUP BY 
    p.product_category_english;
GO

-- ==============================================================================
-- VIEW 3: LOGISTICS HEALTH BY STATE (The Supply Chain View)
-- ==============================================================================
DROP VIEW IF EXISTS gold.vw_kpi_logistics_health;
GO

CREATE VIEW gold.vw_kpi_logistics_health AS
SELECT 
    c.customer_state,
    COUNT(o.order_sk) AS total_orders_delivered,
    AVG(CAST(o.delivery_time_days AS FLOAT)) AS avg_delivery_days,
    SUM(CAST(o.is_late_delivery AS INT)) AS late_deliveries,
    (CAST(SUM(CAST(o.is_late_delivery AS INT)) AS FLOAT) / NULLIF(COUNT(o.order_sk), 0)) * 100 AS late_delivery_rate_pct
FROM gold.fact_orders o
JOIN gold.dim_customer c ON o.customer_sk = c.customer_sk
WHERE o.order_status = 'delivered'
GROUP BY 
    c.customer_state;
GO

-- ==============================================================================
-- VIEW 4: SELLER SCORECARD (The Vendor View)
-- ==============================================================================
DROP VIEW IF EXISTS gold.vw_kpi_seller_scorecard;
GO

CREATE VIEW gold.vw_kpi_seller_scorecard AS
SELECT 
    s.seller_id,
    s.seller_state,
    COUNT(DISTINCT oi.order_id) AS total_orders_fulfilled,
    COUNT(oi.order_item_id) AS total_items_sold,
    SUM(oi.price) AS total_revenue_generated
FROM gold.fact_order_items oi
JOIN gold.dim_seller s ON oi.seller_sk = s.seller_sk
GROUP BY 
    s.seller_id, s.seller_state;
GO

-- ==============================================================================
-- VIEW 5: CUSTOMER SATISFACTION (The Quality View)
-- ==============================================================================
DROP VIEW IF EXISTS gold.vw_kpi_customer_satisfaction;
GO

CREATE VIEW gold.vw_kpi_customer_satisfaction AS
SELECT 
    c.customer_state,
    COUNT(r.review_sk) AS total_reviews,
    AVG(CAST(r.review_score AS FLOAT)) AS average_review_score,
    SUM(CASE WHEN r.review_score = 5 THEN 1 ELSE 0 END) AS five_star_reviews,
    SUM(CASE WHEN r.review_score = 1 THEN 1 ELSE 0 END) AS one_star_reviews,
    (CAST(SUM(CASE WHEN r.review_score = 1 THEN 1 ELSE 0 END) AS FLOAT) / NULLIF(COUNT(r.review_sk), 0)) * 100 AS critical_dissatisfaction_rate_pct
FROM gold.fact_reviews r
JOIN gold.dim_customer c ON r.customer_sk = c.customer_sk
GROUP BY 
    c.customer_state;
GO

-- ==============================================================================
-- VIEW 6: REVIEW vs DELIVERY CORRELATION (The Root Cause View)
-- ==============================================================================
DROP VIEW IF EXISTS gold.vw_kpi_delivery_review_correlation;
GO

CREATE VIEW gold.vw_kpi_delivery_review_correlation AS
SELECT
    CASE
        WHEN o.is_late_delivery = 1                         THEN 'Late'
        WHEN o.delivery_time_days <= 7                      THEN 'Fast (<=7 days)'
        WHEN o.delivery_time_days <= 14                     THEN 'Normal (8-14 days)'
        ELSE                                                     'Slow (15+ days)'
    END AS delivery_bucket,
    COUNT(o.order_sk)                                           AS total_orders,
    AVG(CAST(r.review_score AS FLOAT))                         AS avg_review_score,
    AVG(CAST(o.delivery_time_days AS FLOAT))                   AS avg_delivery_days,
    (CAST(SUM(CASE WHEN r.review_score = 1 THEN 1 ELSE 0 END) AS FLOAT)
        / NULLIF(COUNT(o.order_sk), 0)) * 100                  AS one_star_rate_pct,
    (CAST(SUM(CASE WHEN r.review_score = 5 THEN 1 ELSE 0 END) AS FLOAT)
        / NULLIF(COUNT(o.order_sk), 0)) * 100                  AS five_star_rate_pct
FROM gold.fact_orders o
JOIN gold.fact_reviews r   ON o.order_id   = r.order_id
WHERE o.order_status = 'delivered'
  AND o.delivery_time_days IS NOT NULL
GROUP BY
    CASE
        WHEN o.is_late_delivery = 1     THEN 'Late'
        WHEN o.delivery_time_days <= 7  THEN 'Fast (<=7 days)'
        WHEN o.delivery_time_days <= 14 THEN 'Normal (8-14 days)'
        ELSE                                 'Slow (15+ days)'
    END;
GO

-- ==============================================================================
-- VIEW 7: FREIGHT-TO-REVENUE RATIO BY CATEGORY (The Profitability View)
-- ==============================================================================
DROP VIEW IF EXISTS gold.vw_kpi_category_freight_ratio;
GO

CREATE VIEW gold.vw_kpi_category_freight_ratio AS
SELECT
    ISNULL(p.product_category_english, 'Unknown Category')     AS product_category,
    COUNT(oi.order_item_id)                                     AS total_items_sold,
    SUM(oi.price)                                               AS total_revenue,
    SUM(oi.freight_value)                                       AS total_freight_cost,
    AVG(oi.price)                                               AS avg_item_price,
    AVG(oi.freight_value)                                       AS avg_freight_cost,
    (AVG(oi.freight_value) / NULLIF(AVG(oi.price + oi.freight_value), 0)) * 100
                                                                AS freight_ratio_pct,
    (SUM(oi.freight_value) / NULLIF(SUM(oi.price + oi.freight_value), 0)) * 100
                                                                AS total_freight_burden_pct
FROM gold.fact_order_items oi
JOIN gold.dim_product p ON oi.product_sk = p.product_sk
GROUP BY
    p.product_category_english;
GO

-- ==============================================================================
-- VIEW 8: ORDER STATUS FUNNEL (The Operations View)
-- ==============================================================================
DROP VIEW IF EXISTS gold.vw_kpi_order_status_funnel;
GO

CREATE VIEW gold.vw_kpi_order_status_funnel AS
SELECT
    o.order_status,
    COUNT(o.order_sk)                                           AS total_orders,
    SUM(o.total_payment_value)                                  AS total_payment_value,
    AVG(o.total_payment_value)                                  AS avg_order_value,
    (CAST(COUNT(o.order_sk) AS FLOAT)
        / NULLIF(SUM(COUNT(o.order_sk)) OVER (), 0)) * 100     AS status_share_pct,
    SUM(CASE WHEN o.order_status IN ('canceled', 'unavailable')
             THEN o.total_payment_value ELSE 0 END)             AS lost_revenue_value,
    COUNT(CASE WHEN o.order_status IN ('canceled', 'unavailable')
               THEN 1 END)                                      AS lost_order_count
FROM gold.fact_orders o
GROUP BY
    o.order_status;
GO
