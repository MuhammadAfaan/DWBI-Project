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
    -- Calculate Average Order Value (Gross Revenue / Number of Orders)
    SUM(oi.price + oi.freight_value) / NULLIF(COUNT(DISTINCT oi.order_id), 0) AS average_order_value
FROM gold.fact_order_items oi
JOIN gold.dim_date d ON oi.order_date_key = d.date_key
GROUP BY 
    d.year, d.month, d.month_name;
GO

-- ==============================================================================
-- VIEW 2: PRODUCT CATEGORY PERFORMANCE (The Inventory View)
-- Purpose: Identifies the top-selling product categories and their shipping costs.
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
-- Purpose: Highlights which Brazilian states suffer from late deliveries.
-- ==============================================================================
DROP VIEW IF EXISTS gold.vw_kpi_logistics_health;
GO

CREATE VIEW gold.vw_kpi_logistics_health AS
SELECT 
    c.customer_state,
    COUNT(o.order_sk) AS total_orders_delivered,
    AVG(CAST(o.delivery_time_days AS FLOAT)) AS avg_delivery_days,
    SUM(CAST(o.is_late_delivery AS INT)) AS late_deliveries,
    -- Percentage of deliveries that were late
    (CAST(SUM(CAST(o.is_late_delivery AS INT)) AS FLOAT) / NULLIF(COUNT(o.order_sk), 0)) * 100 AS late_delivery_rate_pct
FROM gold.fact_orders o
JOIN gold.dim_customer c ON o.customer_sk = c.customer_sk
WHERE o.order_status = 'delivered'
GROUP BY 
    c.customer_state;
GO

-- ==============================================================================
-- VIEW 4: SELLER SCORECARD (The Vendor View)
-- Purpose: Ranks sellers based on volume and revenue generation.
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
-- Purpose: Breaks down the ratio of 5-star vs 1-star reviews to gauge happiness.
-- ==============================================================================
DROP VIEW IF EXISTS gold.vw_kpi_customer_satisfaction;
GO

CREATE VIEW gold.vw_kpi_customer_satisfaction AS
SELECT 
    c.customer_state,
    COUNT(r.review_sk) AS total_reviews,
    AVG(CAST(r.review_score AS FLOAT)) AS average_review_score,
    -- Count how many 5-star reviews there are
    SUM(CASE WHEN r.review_score = 5 THEN 1 ELSE 0 END) AS five_star_reviews,
    -- Count how many 1-star reviews there are
    SUM(CASE WHEN r.review_score = 1 THEN 1 ELSE 0 END) AS one_star_reviews,
    -- Percentage of reviews that are 1-star (Highly Dissatisfied)
    (CAST(SUM(CASE WHEN r.review_score = 1 THEN 1 ELSE 0 END) AS FLOAT) / NULLIF(COUNT(r.review_sk), 0)) * 100 AS critical_dissatisfaction_rate_pct
FROM gold.fact_reviews r
JOIN gold.dim_customer c ON r.customer_sk = c.customer_sk
GROUP BY 
    c.customer_state;
GO

USE OlistDW;
GO

-- ==============================================================================
-- VIEW 6: REVIEW vs DELIVERY CORRELATION (The Root Cause View)
-- Purpose: Directly links late delivery to review score at the order level.
--          Answers: "Does being late actually cause bad reviews?"
-- Grain: Per order (with delivery outcome + review score)
-- ==============================================================================
DROP VIEW IF EXISTS gold.vw_kpi_delivery_review_correlation;
GO

CREATE VIEW gold.vw_kpi_delivery_review_correlation AS
SELECT
    -- Delivery bucket for grouping
    CASE
        WHEN o.is_late_delivery = 1                         THEN 'Late'
        WHEN o.delivery_time_days <= 7                      THEN 'Fast (<=7 days)'
        WHEN o.delivery_time_days <= 14                     THEN 'Normal (8-14 days)'
        ELSE                                                     'Slow (15+ days)'
    END AS delivery_bucket,
    COUNT(o.order_sk)                                           AS total_orders,
    AVG(CAST(r.review_score AS FLOAT))                         AS avg_review_score,
    AVG(CAST(o.delivery_time_days AS FLOAT))                   AS avg_delivery_days,
    -- What % of orders in this bucket got a 1-star review
    (CAST(SUM(CASE WHEN r.review_score = 1 THEN 1 ELSE 0 END) AS FLOAT)
        / NULLIF(COUNT(o.order_sk), 0)) * 100                  AS one_star_rate_pct,
    -- What % of orders in this bucket got a 5-star review
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
-- Purpose: Shows which categories have unsustainable shipping costs relative
--          to the product price. High freight ratio = margin risk.
-- Grain: Per product category
-- KPI: freight_ratio_pct = avg_freight / (avg_price + avg_freight) * 100
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
    -- Core KPI: freight as % of total order value (price + freight)
    (AVG(oi.freight_value) / NULLIF(AVG(oi.price + oi.freight_value), 0)) * 100
                                                                AS freight_ratio_pct,
    -- Total freight burden on the platform for this category
    (SUM(oi.freight_value) / NULLIF(SUM(oi.price + oi.freight_value), 0)) * 100
                                                                AS total_freight_burden_pct
FROM gold.fact_order_items oi
JOIN gold.dim_product p ON oi.product_sk = p.product_sk
GROUP BY
    p.product_category_english;
GO

-- ==============================================================================
-- VIEW 8: ORDER STATUS FUNNEL (The Operations View)
-- Purpose: Shows how many orders exist at each status stage.
--          Canceled + unavailable orders = lost revenue opportunity.
-- Grain: Per order_status
-- ==============================================================================
DROP VIEW IF EXISTS gold.vw_kpi_order_status_funnel;
GO

CREATE VIEW gold.vw_kpi_order_status_funnel AS
SELECT
    o.order_status,
    COUNT(o.order_sk)                                           AS total_orders,
    SUM(o.total_payment_value)                                  AS total_payment_value,
    AVG(o.total_payment_value)                                  AS avg_order_value,
    -- % of all orders this status represents
    (CAST(COUNT(o.order_sk) AS FLOAT)
        / NULLIF(SUM(COUNT(o.order_sk)) OVER (), 0)) * 100     AS status_share_pct,
    -- Revenue lost: count canceled/unavailable orders
    SUM(CASE WHEN o.order_status IN ('canceled', 'unavailable')
             THEN o.total_payment_value ELSE 0 END)             AS lost_revenue_value,
    COUNT(CASE WHEN o.order_status IN ('canceled', 'unavailable')
               THEN 1 END)                                      AS lost_order_count
FROM gold.fact_orders o
GROUP BY
    o.order_status;
GO