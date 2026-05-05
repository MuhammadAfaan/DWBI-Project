USE OlistDW;

EXEC bronze.load_bronze;

-- 1. Show all bronze tables exist
SELECT TABLE_SCHEMA, TABLE_NAME 
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_SCHEMA = 'bronze'
ORDER BY TABLE_NAME;

-- 2. Row count summary
SELECT 'bronze.orders'             AS table_name, COUNT(*) AS row_count FROM bronze.orders
UNION ALL
SELECT 'bronze.customers',                         COUNT(*) FROM bronze.customers
UNION ALL
SELECT 'bronze.order_items',                       COUNT(*) FROM bronze.order_items
UNION ALL
SELECT 'bronze.order_payments',                    COUNT(*) FROM bronze.order_payments
UNION ALL
SELECT 'bronze.order_reviews',                     COUNT(*) FROM bronze.order_reviews
UNION ALL
SELECT 'bronze.products',                          COUNT(*) FROM bronze.products
UNION ALL
SELECT 'bronze.sellers',                           COUNT(*) FROM bronze.sellers
UNION ALL
SELECT 'bronze.geolocation',                       COUNT(*) FROM bronze.geolocation
UNION ALL
SELECT 'bronze.category_translation',              COUNT(*) FROM bronze.category_translation
ORDER BY table_name;

-- 3. Audit log showing all tables loaded successfully
SELECT 
    layer_name,
    object_name,
    step_name,
    row_count,
    status,
    event_time_utc
FROM meta.etl_audit
ORDER BY audit_id;

-- 4. ETL run log
SELECT 
    run_id,
    pipeline_name,
    run_start_utc,
    run_end_utc,
    run_status
FROM meta.etl_run
ORDER BY run_id;

-- 5. Sample data from each table
SELECT TOP 5 * FROM bronze.orders;
SELECT TOP 5 * FROM bronze.customers;
SELECT TOP 5 * FROM bronze.order_items;
SELECT TOP 5 * FROM bronze.order_reviews;

SELECT TOP 5 * FROM bronze.products;