Use OlistDW;
-- Then run silver
EXEC silver.load_silver;

-- Verify silver row counts
SELECT 'silver.orders'              AS table_name, COUNT(*) AS row_count FROM silver.orders
UNION ALL
SELECT 'silver.customers',                          COUNT(*) FROM silver.customers
UNION ALL
SELECT 'silver.order_items',                        COUNT(*) FROM silver.order_items
UNION ALL
SELECT 'silver.order_payments',                     COUNT(*) FROM silver.order_payments
UNION ALL
SELECT 'silver.order_reviews',                      COUNT(*) FROM silver.order_reviews
UNION ALL
SELECT 'silver.products',                           COUNT(*) FROM silver.products
UNION ALL
SELECT 'silver.sellers',                            COUNT(*) FROM silver.sellers
UNION ALL
SELECT 'silver.geolocation',                        COUNT(*) FROM silver.geolocation
UNION ALL
SELECT 'silver.category_translation',               COUNT(*) FROM silver.category_translation;

-- Verify reject counts
SELECT 'reject_orders',         COUNT(*) FROM silver.reject_orders
UNION ALL
SELECT 'reject_customers',      COUNT(*) FROM silver.reject_customers
UNION ALL
SELECT 'reject_order_items',    COUNT(*) FROM silver.reject_order_items
UNION ALL
SELECT 'reject_order_payments', COUNT(*) FROM silver.reject_order_payments
UNION ALL
SELECT 'reject_order_reviews',  COUNT(*) FROM silver.reject_order_reviews
UNION ALL
SELECT 'reject_products',       COUNT(*) FROM silver.reject_products
UNION ALL
SELECT 'reject_sellers',        COUNT(*) FROM silver.reject_sellers
UNION ALL
SELECT 'reject_geolocation',    COUNT(*) FROM silver.reject_geolocation;

-- Check audit log
SELECT object_name, step_name, row_count, status, message
FROM meta.etl_audit
WHERE layer_name = 'SILVER'
ORDER BY audit_id;

SELECT TOP 5 * FROM silver.orders;
SELECT TOP 5 * FROM silver.products
SELECT TOP 5 * FROM silver.sellers;
SELECT TOP 5 * FROM silver.geolocation;
SELECT TOP 5 * FROM silver.order_reviews;
SELECT TOP 5 * FROM silver.order_payments;
SELECT TOP 5 * FROM silver.order_items;
SELECT TOP 5 * FROM silver.customers;
SELECT TOP 5 * FROM silver.category_translation;

--Testing why the issue arrises of the null columns
-- Check sellers zip raw values
SELECT TOP 10 
    seller_id,
    seller_zip_code_prefix,
    LEN(seller_zip_code_prefix) AS len,
    ASCII(LEFT(seller_zip_code_prefix, 1)) AS first_char_ascii
FROM bronze.sellers;

-- Check geolocation zip raw values  
SELECT TOP 10
    geolocation_zip_code_prefix,
    LEN(geolocation_zip_code_prefix) AS len,
    ASCII(LEFT(geolocation_zip_code_prefix, 1)) AS first_char_ascii
FROM bronze.geolocation;


SELECT * FROM silver.reject_order_reviews;
SELECT * FROM silver.reject_order_payments;