-- ╔══════════════════════════════════════════════════════════════════════════════╗
-- ║           OLIST DATA WAREHOUSE — FULL DEMO PIPELINE                        ║
-- ║           Medallion Architecture (Bronze → Silver → Gold)                  ║
-- ║           Run this file TOP-TO-BOTTOM in SSMS for your demo                ║
-- ╚══════════════════════════════════════════════════════════════════════════════╝

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECTION 1: SHOW THE DATABASE & SCHEMAS (Architecture Overview)
-- ═══════════════════════════════════════════════════════════════════════════════
-- "First, let me show you the OlistDW database and the 4 schemas
--  that form our Medallion Architecture."

USE OlistDW;
GO

-- 1A. List all schemas in the data warehouse
SELECT 
    s.name          AS schema_name,
    CASE s.name
        WHEN 'bronze' THEN 'Raw ingested data (as-is from CSV files)'
        WHEN 'silver' THEN 'Cleaned, validated, and type-cast data'
        WHEN 'gold'   THEN 'Star schema (dimensions + facts) for analytics'
        WHEN 'meta'   THEN 'ETL audit trail, run logs, QA results'
        ELSE 'System schema'
    END             AS purpose
FROM sys.schemas s
WHERE s.name IN ('bronze', 'silver', 'gold', 'meta')
ORDER BY 
    CASE s.name
        WHEN 'meta'   THEN 1
        WHEN 'bronze' THEN 2
        WHEN 'silver' THEN 3
        WHEN 'gold'   THEN 4
    END;
GO

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECTION 2: META LAYER — ETL Governance & Audit Trail
-- ═══════════════════════════════════════════════════════════════════════════════
-- "Our meta schema provides full ETL governance. Every pipeline run
--  is logged, every table load is audited, and QA checks are recorded."

-- 2A. Show meta tables
SELECT TABLE_SCHEMA, TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'meta'
ORDER BY TABLE_NAME;
GO

-- 2B. Show ETL run history (pipeline-level tracking)
SELECT 
    run_id,
    pipeline_name,
    run_start_utc,
    run_end_utc,
    DATEDIFF(SECOND, run_start_utc, run_end_utc)   AS duration_seconds,
    run_status,
    triggered_by,
    LEFT(notes, 120) AS notes_preview
FROM meta.etl_run
ORDER BY run_id DESC;
GO

-- 2C. Show ETL audit log (table-level tracking)
SELECT TOP 30
    audit_id,
    run_id,
    layer_name,
    object_name,
    step_name,
    row_count,
    status,
    message,
    event_time_utc
FROM meta.etl_audit
ORDER BY audit_id DESC;
GO

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECTION 3: BRONZE LAYER — Raw Data Ingestion
-- ═══════════════════════════════════════════════════════════════════════════════
-- "The Bronze layer stores data exactly as-is from the source CSV files.
--  All columns are NVARCHAR(500) — no type casting, no cleaning. 
--  This preserves the original data for auditability."

-- 3A. List all Bronze tables
SELECT TABLE_SCHEMA, TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'bronze'
ORDER BY TABLE_NAME;
GO

-- 3B. Show Bronze table column types (notice: ALL NVARCHAR!)
SELECT 
    TABLE_NAME,
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'bronze' AND TABLE_NAME = 'orders'
ORDER BY ORDINAL_POSITION;
GO

-- 3C. Bronze row counts
SELECT 'bronze.orders'              AS table_name, COUNT(*) AS row_count FROM bronze.orders
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
GO

-- 3D. Sample raw data (notice the raw string dates, quoted values)
SELECT TOP 5 * FROM bronze.orders;
SELECT TOP 5 * FROM bronze.products;
GO

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECTION 4: SILVER LAYER — Cleaned & Validated Data
-- ═══════════════════════════════════════════════════════════════════════════════
-- "In the Silver layer, we apply data quality rules:
--  - Type casting (strings → DATETIME2, INT, DECIMAL)
--  - NULL handling and trimming
--  - City name standardization (via a UDF)
--  - Geolocation deduplication (one row per zip code)
--  - Bad rows are routed to REJECT tables (not lost!)"

-- 4A. List all Silver tables (notice both clean tables AND reject tables)
SELECT TABLE_SCHEMA, TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'silver'
ORDER BY TABLE_NAME;
GO

-- 4B. Show Silver column types (notice: proper data types now!)
SELECT 
    TABLE_NAME,
    COLUMN_NAME,
    DATA_TYPE,
    NUMERIC_PRECISION,
    NUMERIC_SCALE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'silver' AND TABLE_NAME = 'orders'
ORDER BY ORDINAL_POSITION;
GO

-- 4C. Silver row counts (clean data)
SELECT 'silver.orders'              AS table_name, COUNT(*) AS row_count FROM silver.orders
UNION ALL
SELECT 'silver.customers',                         COUNT(*) FROM silver.customers
UNION ALL
SELECT 'silver.order_items',                       COUNT(*) FROM silver.order_items
UNION ALL
SELECT 'silver.order_payments',                    COUNT(*) FROM silver.order_payments
UNION ALL
SELECT 'silver.order_reviews',                     COUNT(*) FROM silver.order_reviews
UNION ALL
SELECT 'silver.products',                          COUNT(*) FROM silver.products
UNION ALL
SELECT 'silver.sellers',                           COUNT(*) FROM silver.sellers
UNION ALL
SELECT 'silver.geolocation',                       COUNT(*) FROM silver.geolocation
UNION ALL
SELECT 'silver.category_translation',              COUNT(*) FROM silver.category_translation
ORDER BY table_name;
GO

-- 4D. Reject table counts (data quality evidence)
-- "These are the rows that FAILED validation — we don't lose them,
--  we capture them with a reject_reason for investigation."
SELECT 'reject_orders'          AS reject_table, COUNT(*) AS rejected_rows FROM silver.reject_orders
UNION ALL
SELECT 'reject_customers',                        COUNT(*) FROM silver.reject_customers
UNION ALL
SELECT 'reject_order_items',                      COUNT(*) FROM silver.reject_order_items
UNION ALL
SELECT 'reject_order_payments',                   COUNT(*) FROM silver.reject_order_payments
UNION ALL
SELECT 'reject_order_reviews',                    COUNT(*) FROM silver.reject_order_reviews
UNION ALL
SELECT 'reject_products',                         COUNT(*) FROM silver.reject_products
UNION ALL
SELECT 'reject_sellers',                          COUNT(*) FROM silver.reject_sellers
UNION ALL
SELECT 'reject_geolocation',                      COUNT(*) FROM silver.reject_geolocation
ORDER BY reject_table;
GO

-- 4E. Show a few rejected rows (data quality proof)
SELECT TOP 5 reject_reason, order_id, review_score, review_creation_date
FROM silver.reject_order_reviews;
GO

-- 4F. Sample clean silver data (notice: proper dates and integers)
SELECT TOP 5 * FROM silver.orders;
SELECT TOP 5 * FROM silver.products;
GO

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECTION 5: GOLD LAYER — Star Schema (Dimensions + Facts)
-- ═══════════════════════════════════════════════════════════════════════════════
-- "The Gold layer follows a Star Schema design with:
--  - 4 Dimension tables (dim_customer, dim_seller, dim_product, dim_date)
--  - 3 Fact tables (fact_orders, fact_order_items, fact_reviews)
--  Surrogate keys (INT IDENTITY) replace natural keys for performance."

-- 5A. List all Gold tables
SELECT TABLE_SCHEMA, TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'gold'
  AND TABLE_TYPE = 'BASE TABLE'
ORDER BY 
    CASE 
        WHEN TABLE_NAME LIKE 'dim%' THEN 1
        WHEN TABLE_NAME LIKE 'fact%' THEN 2
    END, TABLE_NAME;
GO

-- 5B. Gold row counts
SELECT 'gold.dim_customer'      AS table_name, COUNT(*) AS row_count FROM gold.dim_customer
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
SELECT 'gold.fact_reviews',                     COUNT(*) FROM gold.fact_reviews
ORDER BY table_name;
GO

-- 5C. Show dimension samples (notice surrogate keys & enrichment)
-- "dim_customer now has latitude/longitude from geo data joined in"
SELECT TOP 5 customer_sk, customer_id, customer_city, customer_state, latitude, longitude
FROM gold.dim_customer;
GO

-- "dim_product has English category names from the translation table"
SELECT TOP 5 product_sk, product_id, product_category_english, product_weight_g
FROM gold.dim_product;
GO

-- "dim_date is a full calendar dimension covering 2016-2019"
SELECT TOP 5 date_key, full_date, year, quarter, month_name, day_name, is_weekend
FROM gold.dim_date;
GO

-- 5D. Show fact tables (surrogate key joins + computed KPIs)
-- "fact_orders has pre-computed delivery_time_days and is_late_delivery"
SELECT TOP 10 
    order_sk, order_id, customer_sk, order_status,
    order_date_key, delivery_time_days, is_late_delivery, total_payment_value
FROM gold.fact_orders;
GO

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECTION 6: ETL AUDIT TRAIL — Full Pipeline Verification
-- ═══════════════════════════════════════════════════════════════════════════════
-- "Every ETL step is tracked. We can see exactly when each table was loaded,
--  how many rows were processed, and whether it succeeded or failed."

-- 6A. Full audit trail for the latest run
SELECT 
    a.layer_name,
    a.object_name,
    a.step_name,
    a.row_count,
    a.status,
    a.message,
    a.event_time_utc
FROM meta.etl_audit a
JOIN (SELECT MAX(run_id) AS latest_run FROM meta.etl_run) lr 
    ON a.run_id = lr.latest_run
ORDER BY a.audit_id;
GO

-- 6B. Pipeline success confirmation
SELECT 
    run_id,
    pipeline_name,
    run_status,
    run_start_utc,
    run_end_utc,
    DATEDIFF(SECOND, run_start_utc, run_end_utc) AS total_seconds
FROM meta.etl_run
ORDER BY run_id DESC;
GO

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECTION 7: GOLD VIEWS — Business KPI Queries
-- ═══════════════════════════════════════════════════════════════════════════════
-- "We created 8 Gold views that serve as the analytical layer.
--  These views are consumed by our Streamlit dashboard."

-- 7A. List all views in the Gold schema
SELECT TABLE_SCHEMA, TABLE_NAME
FROM INFORMATION_SCHEMA.VIEWS
WHERE TABLE_SCHEMA = 'gold'
ORDER BY TABLE_NAME;
GO

-- 7B. VIEW 1: Monthly Sales Trend (Executive Overview)
-- "Revenue growth, total orders, and Average Order Value over time"
SELECT *
FROM gold.vw_kpi_monthly_sales_trend
ORDER BY year, month;
GO

-- 7C. VIEW 2: Product Category Performance
-- "Top-selling categories and their shipping costs"
SELECT TOP 15 *
FROM gold.vw_kpi_product_performance
ORDER BY total_revenue DESC;
GO

-- 7D. VIEW 3: Logistics Health by State
-- "Which Brazilian states suffer from late deliveries?"
SELECT *
FROM gold.vw_kpi_logistics_health
ORDER BY late_delivery_rate_pct DESC;
GO

-- 7E. VIEW 4: Seller Scorecard
-- "Top sellers ranked by volume and revenue"
SELECT TOP 15 *
FROM gold.vw_kpi_seller_scorecard
ORDER BY total_revenue_generated DESC;
GO

-- 7F. VIEW 5: Customer Satisfaction
-- "5-star vs 1-star review breakdown by state"
SELECT *
FROM gold.vw_kpi_customer_satisfaction
ORDER BY average_review_score ASC;
GO

-- 7G. VIEW 6: Delivery vs Review Correlation
-- "Does late delivery actually cause bad reviews? YES."
SELECT *
FROM gold.vw_kpi_delivery_review_correlation
ORDER BY delivery_bucket;
GO

-- 7H. VIEW 7: Freight-to-Revenue Ratio
-- "Which categories have unsustainable shipping costs?"
SELECT TOP 15 *
FROM gold.vw_kpi_category_freight_ratio
ORDER BY freight_ratio_pct DESC;
GO

-- 7I. VIEW 8: Order Status Funnel
-- "How orders flow through the pipeline — and where revenue is lost"
SELECT *
FROM gold.vw_kpi_order_status_funnel
ORDER BY total_orders DESC;
GO

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECTION 8: STORED PROCEDURES — Automated ETL Pipeline
-- ═══════════════════════════════════════════════════════════════════════════════
-- "We have 3 stored procedures that automate the entire pipeline."

SELECT 
    ROUTINE_SCHEMA  AS [schema],
    ROUTINE_NAME    AS procedure_name,
    CREATED         AS created_on,
    LAST_ALTERED    AS last_modified
FROM INFORMATION_SCHEMA.ROUTINES
WHERE ROUTINE_TYPE = 'PROCEDURE'
  AND ROUTINE_SCHEMA IN ('bronze', 'silver', 'gold')
ORDER BY 
    CASE ROUTINE_SCHEMA
        WHEN 'bronze' THEN 1
        WHEN 'silver' THEN 2
        WHEN 'gold'   THEN 3
    END;
GO