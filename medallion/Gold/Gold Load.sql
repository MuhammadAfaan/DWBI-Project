USE OlistDW;
GO

DROP PROCEDURE IF EXISTS gold.load_gold;
GO

CREATE PROCEDURE gold.load_gold
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @run_id BIGINT = (SELECT MAX(run_id) FROM meta.etl_run);

    BEGIN TRY
        UPDATE meta.etl_run SET notes = CONCAT(ISNULL(notes, ''), ' | Starting Gold Load') WHERE run_id = @run_id;

        -- =============================================
        -- 1. LOAD DIM CUSTOMER (With Geo)
        -- =============================================
        INSERT INTO meta.etl_audit (run_id, layer_name, object_name, step_name, status, message)
        VALUES (@run_id, 'GOLD', 'gold.dim_customer', 'LOAD_GOLD_DIM_CUSTOMER', 'STARTED', 'Loading dim_customer with geolocation');

        TRUNCATE TABLE gold.dim_customer;
        
        INSERT INTO gold.dim_customer (customer_id, customer_unique_id, customer_zip_code_prefix, customer_city, customer_state, latitude, longitude)
        SELECT 
            c.customer_id, c.customer_unique_id, c.customer_zip_code_prefix, c.customer_city, c.customer_state,
            g.geolocation_lat, g.geolocation_lng
        FROM silver.customers c
        LEFT JOIN silver.geolocation g ON c.customer_zip_code_prefix = g.geolocation_zip_code_prefix;

        UPDATE meta.etl_audit
        SET status    = 'SUCCESS',
            row_count = (SELECT COUNT(*) FROM gold.dim_customer),
            message   = CONCAT('dim_customer loaded: ', (SELECT COUNT(*) FROM gold.dim_customer))
        WHERE run_id = @run_id AND step_name = 'LOAD_GOLD_DIM_CUSTOMER';

        -- =============================================
        -- 2. LOAD DIM SELLER (With Geo)
        -- =============================================
        INSERT INTO meta.etl_audit (run_id, layer_name, object_name, step_name, status, message)
        VALUES (@run_id, 'GOLD', 'gold.dim_seller', 'LOAD_GOLD_DIM_SELLER', 'STARTED', 'Loading dim_seller with geolocation');

        TRUNCATE TABLE gold.dim_seller;

        INSERT INTO gold.dim_seller (seller_id, seller_zip_code_prefix, seller_city, seller_state, latitude, longitude)
        SELECT 
            s.seller_id, s.seller_zip_code_prefix, s.seller_city, s.seller_state,
            g.geolocation_lat, g.geolocation_lng
        FROM silver.sellers s
        LEFT JOIN silver.geolocation g ON s.seller_zip_code_prefix = g.geolocation_zip_code_prefix;

        UPDATE meta.etl_audit
        SET status    = 'SUCCESS',
            row_count = (SELECT COUNT(*) FROM gold.dim_seller),
            message   = CONCAT('dim_seller loaded: ', (SELECT COUNT(*) FROM gold.dim_seller))
        WHERE run_id = @run_id AND step_name = 'LOAD_GOLD_DIM_SELLER';

        -- =============================================
        -- 3. LOAD DIM PRODUCT (With Translation)
        -- =============================================
        INSERT INTO meta.etl_audit (run_id, layer_name, object_name, step_name, status, message)
        VALUES (@run_id, 'GOLD', 'gold.dim_product', 'LOAD_GOLD_DIM_PRODUCT', 'STARTED', 'Loading dim_product with English translation');

        TRUNCATE TABLE gold.dim_product;

        INSERT INTO gold.dim_product (product_id, product_category_english, product_weight_g, product_length_cm, product_height_cm, product_width_cm)
        SELECT 
            p.product_id,
            ISNULL(t.product_category_name_english, ISNULL(p.product_category_name, 'Unknown')),
            p.product_weight_g, p.product_length_cm, p.product_height_cm, p.product_width_cm
        FROM silver.products p
        LEFT JOIN silver.category_translation t ON p.product_category_name = t.product_category_name;

        UPDATE meta.etl_audit
        SET status    = 'SUCCESS',
            row_count = (SELECT COUNT(*) FROM gold.dim_product),
            message   = CONCAT('dim_product loaded: ', (SELECT COUNT(*) FROM gold.dim_product))
        WHERE run_id = @run_id AND step_name = 'LOAD_GOLD_DIM_PRODUCT';

        -- =============================================
        -- 4. LOAD FACT ORDER ITEMS
        -- =============================================
        INSERT INTO meta.etl_audit (run_id, layer_name, object_name, step_name, status, message)
        VALUES (@run_id, 'GOLD', 'gold.fact_order_items', 'LOAD_GOLD_FACT_ORDER_ITEMS', 'STARTED', 'Loading fact_order_items with surrogate keys');

        TRUNCATE TABLE gold.fact_order_items;

        INSERT INTO gold.fact_order_items (order_id, order_item_id, customer_sk, seller_sk, product_sk, order_date_key, price, freight_value)
        SELECT 
            oi.order_id,
            oi.order_item_id,
            ISNULL(c.customer_sk, -1),
            ISNULL(s.seller_sk, -1),
            ISNULL(p.product_sk, -1),
            CAST(CONVERT(VARCHAR(8), o.order_purchase_timestamp, 112) AS INT) AS order_date_key,
            oi.price,
            oi.freight_value
        FROM silver.order_items oi
        JOIN silver.orders o ON oi.order_id = o.order_id
        LEFT JOIN gold.dim_customer c ON o.customer_id = c.customer_id
        LEFT JOIN gold.dim_seller s ON oi.seller_id = s.seller_id
        LEFT JOIN gold.dim_product p ON oi.product_id = p.product_id;

        UPDATE meta.etl_audit
        SET status    = 'SUCCESS',
            row_count = (SELECT COUNT(*) FROM gold.fact_order_items),
            message   = CONCAT('fact_order_items loaded: ', (SELECT COUNT(*) FROM gold.fact_order_items))
        WHERE run_id = @run_id AND step_name = 'LOAD_GOLD_FACT_ORDER_ITEMS';

        -- =============================================
        -- 5. LOAD FACT ORDERS (With Logistics KPIs)
        -- =============================================
        INSERT INTO meta.etl_audit (run_id, layer_name, object_name, step_name, status, message)
        VALUES (@run_id, 'GOLD', 'gold.fact_orders', 'LOAD_GOLD_FACT_ORDERS', 'STARTED', 'Loading fact_orders with delivery KPIs');

        TRUNCATE TABLE gold.fact_orders;

        -- Pre-aggregate payments to avoid duplicating order rows
        ;WITH OrderPayments AS (
            SELECT order_id, SUM(payment_value) as total_payment
            FROM silver.order_payments
            GROUP BY order_id
        )
        INSERT INTO gold.fact_orders (
            order_id, customer_sk, order_status, order_date_key, 
            estimated_delivery_date_key, actual_delivery_date_key, 
            delivery_time_days, is_late_delivery, total_payment_value
        )
        SELECT 
            o.order_id,
            ISNULL(c.customer_sk, -1),
            o.order_status,
            CAST(CONVERT(VARCHAR(8), o.order_purchase_timestamp, 112) AS INT),
            CAST(CONVERT(VARCHAR(8), o.order_estimated_delivery_date, 112) AS INT),
            CAST(CONVERT(VARCHAR(8), o.order_delivered_customer_date, 112) AS INT),
            DATEDIFF(DAY, o.order_purchase_timestamp, o.order_delivered_customer_date) AS delivery_time_days,
            CASE WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN 1 ELSE 0 END AS is_late_delivery,
            ISNULL(op.total_payment, 0)
        FROM silver.orders o
        LEFT JOIN gold.dim_customer c ON o.customer_id = c.customer_id
        LEFT JOIN OrderPayments op ON o.order_id = op.order_id;

        UPDATE meta.etl_audit
        SET status    = 'SUCCESS',
            row_count = (SELECT COUNT(*) FROM gold.fact_orders),
            message   = CONCAT('fact_orders loaded: ', (SELECT COUNT(*) FROM gold.fact_orders))
        WHERE run_id = @run_id AND step_name = 'LOAD_GOLD_FACT_ORDERS';

        -- =============================================
        -- 6. LOAD FACT REVIEWS (With Customer Link)
        -- =============================================
        INSERT INTO meta.etl_audit (run_id, layer_name, object_name, step_name, status, message)
        VALUES (@run_id, 'GOLD', 'gold.fact_reviews', 'LOAD_GOLD_FACT_REVIEWS', 'STARTED', 'Loading fact_reviews with response time');

        TRUNCATE TABLE gold.fact_reviews;

        INSERT INTO gold.fact_reviews (
            review_id, order_id, customer_sk, review_creation_date_key, 
            review_score, review_comment_title, review_comment_message, response_time_days
        )
        SELECT 
            r.review_id,
            r.order_id,
            ISNULL(c.customer_sk, -1),
            CAST(CONVERT(VARCHAR(8), r.review_creation_date, 112) AS INT),
            r.review_score,
            r.review_comment_title,
            r.review_comment_message,
            DATEDIFF(DAY, r.review_creation_date, r.review_answer_timestamp) AS response_time_days
        FROM silver.order_reviews r
        JOIN silver.orders o ON r.order_id = o.order_id
        LEFT JOIN gold.dim_customer c ON o.customer_id = c.customer_id;

        UPDATE meta.etl_audit
        SET status    = 'SUCCESS',
            row_count = (SELECT COUNT(*) FROM gold.fact_reviews),
            message   = CONCAT('fact_reviews loaded: ', (SELECT COUNT(*) FROM gold.fact_reviews))
        WHERE run_id = @run_id AND step_name = 'LOAD_GOLD_FACT_REVIEWS';

        -- =============================================
        -- MARK PIPELINE SUCCESS
        -- =============================================
        UPDATE meta.etl_run
        SET run_status = 'SUCCESS', run_end_utc = SYSUTCDATETIME(), notes = CONCAT(notes, ' | Gold load completed.')
        WHERE run_id = @run_id;

    END TRY
    BEGIN CATCH
        DECLARE @err NVARCHAR(2000) = ERROR_MESSAGE();
        UPDATE meta.etl_run
        SET run_status = 'FAILED', run_end_utc = SYSUTCDATETIME(), notes = CONCAT(notes, ' | ERROR IN GOLD: ', @err)
        WHERE run_id = @run_id;
        THROW;
    END CATCH
END;
GO