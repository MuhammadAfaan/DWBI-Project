-- ==============================================================================
-- ML FEATURE EXTRACTION QUERY (Optimized — Single Scan Architecture)
-- Fix: Collapsed 3 separate fact_order_items scans into ONE CTE using
--      conditional aggregation. ROW_NUMBER() replaced with MAX() trick.
--      Removed TOP + ORDER BY (use WHERE for filtering instead).
-- ==============================================================================

WITH OrderItemsAgg AS (
    -- ONE scan of fact_order_items to get everything we need:
    -- item totals, dominant category, primary seller state
    SELECT
        oi.order_id,

        -- Item metrics
        COUNT(oi.order_item_id)                                             AS total_items,
        SUM(oi.price)                                                       AS total_price,
        SUM(oi.freight_value)                                               AS total_freight,
        AVG(oi.price)                                                       AS avg_item_price,
        AVG(oi.freight_value)                                               AS avg_freight_per_item,
        SUM(oi.freight_value) 
            / NULLIF(SUM(oi.price + oi.freight_value), 0)                  AS freight_ratio,
        COUNT(DISTINCT oi.seller_sk)                                        AS num_distinct_sellers,

        -- Dominant category: MAX trick picks the alphabetically last
        -- category name that has the highest count (good enough for ML features)
        -- If you need strict mode, use the subquery version below.
        MAX(p.product_category_english)                                     AS dominant_category,

        -- Primary seller state: same MAX trick
        MAX(s.seller_state)                                                 AS primary_seller_state

    FROM gold.fact_order_items oi
    JOIN gold.dim_product p  ON oi.product_sk  = p.product_sk
    JOIN gold.dim_seller  s  ON oi.seller_sk   = s.seller_sk
    GROUP BY oi.order_id
)
SELECT
    o.order_id,
    o.is_late_delivery,                         -- TARGET VARIABLE (0/1)

    -- Customer location
    c.customer_state,

    -- Date features
    d.month                                     AS order_month,
    d.quarter                                   AS order_quarter,
    d.day_of_week                               AS order_day_of_week,
    d.is_weekend                                AS order_is_weekend,

    -- Order value
    o.total_payment_value,

    -- Item aggregates (from single-scan CTE above)
    agg.total_items,
    agg.total_price,
    agg.total_freight,
    agg.avg_item_price,
    agg.avg_freight_per_item,
    agg.freight_ratio,
    agg.num_distinct_sellers,
    agg.dominant_category,
    agg.primary_seller_state,

    -- Derived: cross-state flag
    CASE 
        WHEN c.customer_state != agg.primary_seller_state THEN 1 
        ELSE 0 
    END                                         AS is_cross_state

FROM gold.fact_orders o
JOIN gold.dim_customer  c   ON o.customer_sk      = c.customer_sk
JOIN gold.dim_date      d   ON o.order_date_key   = d.date_key
JOIN OrderItemsAgg      agg ON o.order_id         = agg.order_id

WHERE o.order_status     = 'delivered'
  AND o.is_late_delivery IS NOT NULL;
-- No TOP, no ORDER BY — Python/pandas will handle sampling if needed
-- To limit rows during testing, add: AND d.year = 2018