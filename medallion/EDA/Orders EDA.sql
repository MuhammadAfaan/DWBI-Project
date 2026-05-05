USE OlistDW;

-- Check distinct order statuses
SELECT order_status, COUNT(*) AS cnt
FROM bronze.orders
GROUP BY order_status
ORDER BY cnt DESC;

-- Check null counts in every column
SELECT
    SUM(CASE WHEN order_id IS NULL OR order_id = '' THEN 1 ELSE 0 END)                         AS null_order_id,
    SUM(CASE WHEN customer_id IS NULL OR customer_id = '' THEN 1 ELSE 0 END)                   AS null_customer_id,
    SUM(CASE WHEN order_status IS NULL OR order_status = '' THEN 1 ELSE 0 END)                 AS null_order_status,
    SUM(CASE WHEN order_purchase_timestamp IS NULL OR order_purchase_timestamp = '' THEN 1 ELSE 0 END) AS null_purchase_ts,
    SUM(CASE WHEN order_approved_at IS NULL OR order_approved_at = '' THEN 1 ELSE 0 END)       AS null_approved_at,
    SUM(CASE WHEN order_delivered_carrier_date IS NULL OR order_delivered_carrier_date = '' THEN 1 ELSE 0 END) AS null_carrier_dt,
    SUM(CASE WHEN order_delivered_customer_date IS NULL OR order_delivered_customer_date = '' THEN 1 ELSE 0 END) AS null_customer_dt,
    SUM(CASE WHEN order_estimated_delivery_date IS NULL OR order_estimated_delivery_date = '' THEN 1 ELSE 0 END) AS null_estimated_dt
FROM bronze.orders;

-- Check if dates convert cleanly
SELECT TOP 10
    order_purchase_timestamp,
    TRY_CONVERT(DATETIME2, order_purchase_timestamp) AS converted
FROM bronze.orders
WHERE TRY_CONVERT(DATETIME2, order_purchase_timestamp) IS NULL
  AND order_purchase_timestamp IS NOT NULL
  AND order_purchase_timestamp != '';