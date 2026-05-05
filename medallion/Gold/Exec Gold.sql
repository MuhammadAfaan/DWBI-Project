USE OlistDW;
GO

-- Execute the Gold load procedure
-- (You can also run EXEC silver.load_silver; right before this if you want a full refresh)
EXEC gold.load_gold;
GO

-- ==========================================
-- Verify Gold Row Counts
-- ==========================================
SELECT 'gold.dim_customer'          AS table_name, COUNT(*) AS row_count FROM gold.dim_customer
UNION ALL
SELECT 'gold.dim_seller',           COUNT(*) FROM gold.dim_seller
UNION ALL
SELECT 'gold.dim_product',          COUNT(*) FROM gold.dim_product
UNION ALL
SELECT 'gold.dim_date',             COUNT(*) FROM gold.dim_date
UNION ALL
SELECT 'gold.fact_order_items',     COUNT(*) FROM gold.fact_order_items
UNION ALL
SELECT 'gold.fact_orders',          COUNT(*) FROM gold.fact_orders
UNION ALL
SELECT 'gold.fact_reviews',         COUNT(*) FROM gold.fact_reviews;

-- ==========================================
-- Check ETL Run Status
-- ==========================================
-- This will show you the start/end times and the success notes for your Gold load
SELECT TOP 5 
    run_id, 
    pipeline_name, 
    run_start_utc, 
    run_end_utc, 
    run_status, 
    notes
FROM meta.etl_run
ORDER BY run_id DESC;

SELECT TOP 5 * FROM gold.dim_product;
SELECT TOP 5 * from gold.fact_orders;