USE OlistDW;

-- Compare silver vs gold row counts side by side
SELECT 'silver.orders'          AS source, COUNT(*) AS silver_count FROM silver.orders
UNION ALL
SELECT 'silver.customers',                 COUNT(*) FROM silver.customers
UNION ALL
SELECT 'silver.order_items',               COUNT(*) FROM silver.order_items
UNION ALL
SELECT 'silver.order_payments',            COUNT(*) FROM silver.order_payments
UNION ALL
SELECT 'silver.order_reviews',             COUNT(*) FROM silver.order_reviews
UNION ALL
SELECT 'silver.products',                  COUNT(*) FROM silver.products
UNION ALL
SELECT 'silver.sellers',                   COUNT(*) FROM silver.sellers;

-- Gold counts
SELECT 'gold.dim_customer'      AS gold_table, COUNT(*) AS gold_count FROM gold.dim_customer
UNION ALL
SELECT 'gold.dim_seller',                       COUNT(*) FROM gold.dim_seller
UNION ALL
SELECT 'gold.dim_product',                      COUNT(*) FROM gold.dim_product
UNION ALL
SELECT 'gold.dim_date',                         COUNT(*) FROM gold.dim_date
UNION ALL
SELECT 'gold.fact_order_items',                 COUNT(*) FROM gold.fact_order_items
UNION ALL
SELECT 'gold.fact_orders',                      COUNT(*) FROM gold.fact_orders
UNION ALL
SELECT 'gold.fact_reviews',                     COUNT(*) FROM gold.fact_reviews;