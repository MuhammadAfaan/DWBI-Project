USE OlistDW;
GO

CREATE OR ALTER FUNCTION dbo.fn_standardize_city (@city NVARCHAR(200))
RETURNS NVARCHAR(200)
AS
BEGIN
    IF @city IS NULL RETURN NULL;

    DECLARE @clean NVARCHAR(200);

    -- Remove quotes, trim, uppercase
    SET @clean = UPPER(LTRIM(RTRIM(REPLACE(@city, '"', ''))));

    -- Normalize punctuation
    SET @clean = REPLACE(@clean, '’', '''');
    SET @clean = REPLACE(@clean, '.', '');
    SET @clean = REPLACE(@clean, '-', ' ');
    SET @clean = REPLACE(@clean, '/', ' ');

    -- Remove apostrophes completely
    SET @clean = REPLACE(@clean, '''', '');

    -- Fix common Portuguese patterns
    SET @clean = REPLACE(@clean, ' D OESTE', ' DOESTE');
    SET @clean = REPLACE(@clean, ' D AGUA', ' DAGUA');
    SET @clean = REPLACE(@clean, ' D ALIANCA', ' DALIANCA');

    -- Remove double spaces
    WHILE CHARINDEX('  ', @clean) > 0
        SET @clean = REPLACE(@clean, '  ', ' ');

    -- Remove accents (collation trick)
    SET @clean = @clean COLLATE Latin1_General_CI_AI;

    RETURN @clean;
END;
GO


USE OlistDW;
GO

DROP PROCEDURE IF EXISTS silver.load_silver;
GO

CREATE PROCEDURE silver.load_silver
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @run_id BIGINT = (SELECT MAX(run_id) FROM meta.etl_run);

    BEGIN TRY

        -- =============================================
        -- 1. ORDERS
        -- =============================================
        INSERT INTO meta.etl_audit (run_id, layer_name, object_name, step_name, status, message)
        VALUES (@run_id, 'SILVER', 'silver.orders', 'LOAD_SILVER_ORDERS', 'STARTED', 'Transforming orders');

        TRUNCATE TABLE silver.orders;
        TRUNCATE TABLE silver.reject_orders;

        INSERT INTO silver.reject_orders (
            reject_reason, order_id, customer_id, order_status,
            order_purchase_timestamp, order_approved_at,
            order_delivered_carrier_date, order_delivered_customer_date,
            order_estimated_delivery_date
        )
        SELECT
            CASE
                WHEN NULLIF(LTRIM(RTRIM(REPLACE(order_id,'"',''))), '') IS NULL THEN 'NULL order_id'
                WHEN NULLIF(LTRIM(RTRIM(REPLACE(customer_id,'"',''))), '') IS NULL THEN 'NULL customer_id'
            END,
            order_id, customer_id, order_status,
            order_purchase_timestamp, order_approved_at,
            order_delivered_carrier_date, order_delivered_customer_date,
            order_estimated_delivery_date
        FROM bronze.orders
        WHERE NULLIF(LTRIM(RTRIM(REPLACE(order_id,'"',''))), '') IS NULL
           OR NULLIF(LTRIM(RTRIM(REPLACE(customer_id,'"',''))), '') IS NULL;

        INSERT INTO silver.orders (
            order_id, customer_id, order_status,
            order_purchase_timestamp, order_approved_at,
            order_delivered_carrier_date, order_delivered_customer_date,
            order_estimated_delivery_date
        )
        SELECT
            LTRIM(RTRIM(REPLACE(order_id,'"',''))),
            LTRIM(RTRIM(REPLACE(customer_id,'"',''))),
            LTRIM(RTRIM(REPLACE(order_status,'"',''))),
            TRY_CONVERT(DATETIME2, NULLIF(LTRIM(RTRIM(REPLACE(order_purchase_timestamp,'"',''))), '')),
            TRY_CONVERT(DATETIME2, NULLIF(LTRIM(RTRIM(REPLACE(order_approved_at,'"',''))), '')),
            TRY_CONVERT(DATETIME2, NULLIF(LTRIM(RTRIM(REPLACE(order_delivered_carrier_date,'"',''))), '')),
            TRY_CONVERT(DATETIME2, NULLIF(LTRIM(RTRIM(REPLACE(order_delivered_customer_date,'"',''))), '')),
            TRY_CONVERT(DATETIME2, NULLIF(LTRIM(RTRIM(REPLACE(order_estimated_delivery_date,'"',''))), ''))
        FROM bronze.orders
        WHERE NULLIF(LTRIM(RTRIM(REPLACE(order_id,'"',''))), '') IS NOT NULL
          AND NULLIF(LTRIM(RTRIM(REPLACE(customer_id,'"',''))), '') IS NOT NULL;

        UPDATE meta.etl_audit
        SET status    = 'SUCCESS',
            row_count = (SELECT COUNT(*) FROM silver.orders),
            message   = CONCAT('Orders loaded: ', (SELECT COUNT(*) FROM silver.orders),
                               ' | Rejects: ', (SELECT COUNT(*) FROM silver.reject_orders))
        WHERE run_id = @run_id AND step_name = 'LOAD_SILVER_ORDERS';


        -- =============================================
        -- 2. CUSTOMERS (Standardized City/State)
        -- =============================================
        INSERT INTO meta.etl_audit (run_id, layer_name, object_name, step_name, status, message)
        VALUES (@run_id, 'SILVER', 'silver.customers', 'LOAD_SILVER_CUSTOMERS', 'STARTED', 'Transforming customers');

        TRUNCATE TABLE silver.customers;
        TRUNCATE TABLE silver.reject_customers;

        INSERT INTO silver.reject_customers (
            reject_reason, customer_id, customer_unique_id,
            customer_zip_code_prefix, customer_city, customer_state
        )
        SELECT
            CASE
                WHEN NULLIF(LTRIM(RTRIM(REPLACE(customer_id,'"',''))), '') IS NULL THEN 'NULL customer_id'
                WHEN NULLIF(LTRIM(RTRIM(REPLACE(customer_unique_id,'"',''))), '') IS NULL THEN 'NULL customer_unique_id'
            END,
            customer_id, customer_unique_id,
            customer_zip_code_prefix, customer_city, customer_state
        FROM bronze.customers
        WHERE NULLIF(LTRIM(RTRIM(REPLACE(customer_id,'"',''))), '') IS NULL
           OR NULLIF(LTRIM(RTRIM(REPLACE(customer_unique_id,'"',''))), '') IS NULL;

        INSERT INTO silver.customers (
            customer_id, customer_unique_id,
            customer_zip_code_prefix, customer_city, customer_state
        )
        SELECT
            LTRIM(RTRIM(REPLACE(customer_id,'"',''))),
            LTRIM(RTRIM(REPLACE(customer_unique_id,'"',''))),
            TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(REPLACE(customer_zip_code_prefix,'"',''))), '')),
            dbo.fn_standardize_city(customer_city),
            UPPER(LTRIM(RTRIM(REPLACE(customer_state,'"',''))))
        FROM bronze.customers
        WHERE NULLIF(LTRIM(RTRIM(REPLACE(customer_id,'"',''))), '') IS NOT NULL
          AND NULLIF(LTRIM(RTRIM(REPLACE(customer_unique_id,'"',''))), '') IS NOT NULL;

        UPDATE meta.etl_audit
        SET status    = 'SUCCESS',
            row_count = (SELECT COUNT(*) FROM silver.customers),
            message   = CONCAT('Customers loaded: ', (SELECT COUNT(*) FROM silver.customers),
                               ' | Rejects: ', (SELECT COUNT(*) FROM silver.reject_customers))
        WHERE run_id = @run_id AND step_name = 'LOAD_SILVER_CUSTOMERS';


        -- =============================================
        -- 3. ORDER ITEMS
        -- =============================================
        INSERT INTO meta.etl_audit (run_id, layer_name, object_name, step_name, status, message)
        VALUES (@run_id, 'SILVER', 'silver.order_items', 'LOAD_SILVER_ORDER_ITEMS', 'STARTED', 'Transforming order items');

        TRUNCATE TABLE silver.order_items;
        TRUNCATE TABLE silver.reject_order_items;

        INSERT INTO silver.reject_order_items (
            reject_reason, order_id, order_item_id, product_id,
            seller_id, shipping_limit_date, price, freight_value
        )
        SELECT
            CASE
                WHEN NULLIF(LTRIM(RTRIM(REPLACE(order_id,'"',''))), '') IS NULL THEN 'NULL order_id'
                WHEN NULLIF(LTRIM(RTRIM(REPLACE(product_id,'"',''))), '') IS NULL THEN 'NULL product_id'
                WHEN NULLIF(LTRIM(RTRIM(REPLACE(seller_id,'"',''))), '') IS NULL THEN 'NULL seller_id'
            END,
            order_id, order_item_id, product_id,
            seller_id, shipping_limit_date, price, freight_value
        FROM bronze.order_items
        WHERE NULLIF(LTRIM(RTRIM(REPLACE(order_id,'"',''))), '') IS NULL
           OR NULLIF(LTRIM(RTRIM(REPLACE(product_id,'"',''))), '') IS NULL
           OR NULLIF(LTRIM(RTRIM(REPLACE(seller_id,'"',''))), '') IS NULL;

        INSERT INTO silver.order_items (
            order_id, order_item_id, product_id, seller_id,
            shipping_limit_date, price, freight_value
        )
        SELECT
            LTRIM(RTRIM(REPLACE(order_id,'"',''))),
            TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(REPLACE(order_item_id,'"',''))), '')),
            LTRIM(RTRIM(REPLACE(product_id,'"',''))),
            LTRIM(RTRIM(REPLACE(seller_id,'"',''))),
            TRY_CONVERT(DATETIME2, NULLIF(LTRIM(RTRIM(REPLACE(shipping_limit_date,'"',''))), '')),
            TRY_CONVERT(DECIMAL(18,2), NULLIF(LTRIM(RTRIM(REPLACE(price,'"',''))), '')),
            TRY_CONVERT(DECIMAL(18,2), NULLIF(LTRIM(RTRIM(REPLACE(freight_value,'"',''))), ''))
        FROM bronze.order_items
        WHERE NULLIF(LTRIM(RTRIM(REPLACE(order_id,'"',''))), '') IS NOT NULL
          AND NULLIF(LTRIM(RTRIM(REPLACE(product_id,'"',''))), '') IS NOT NULL
          AND NULLIF(LTRIM(RTRIM(REPLACE(seller_id,'"',''))), '') IS NOT NULL;

        UPDATE meta.etl_audit
        SET status    = 'SUCCESS',
            row_count = (SELECT COUNT(*) FROM silver.order_items),
            message   = CONCAT('Order items loaded: ', (SELECT COUNT(*) FROM silver.order_items),
                               ' | Rejects: ', (SELECT COUNT(*) FROM silver.reject_order_items))
        WHERE run_id = @run_id AND step_name = 'LOAD_SILVER_ORDER_ITEMS';


        -- =============================================
        -- 4. ORDER PAYMENTS
        -- =============================================
        INSERT INTO meta.etl_audit (run_id, layer_name, object_name, step_name, status, message)
        VALUES (@run_id, 'SILVER', 'silver.order_payments', 'LOAD_SILVER_ORDER_PAYMENTS', 'STARTED', 'Transforming payments');

        TRUNCATE TABLE silver.order_payments;
        TRUNCATE TABLE silver.reject_order_payments;

        INSERT INTO silver.reject_order_payments (
            reject_reason, order_id, payment_sequential,
            payment_type, payment_installments, payment_value
        )
        SELECT
            CASE
                WHEN NULLIF(LTRIM(RTRIM(REPLACE(order_id,'"',''))), '') IS NULL
                    THEN 'NULL order_id'
                WHEN UPPER(LTRIM(RTRIM(REPLACE(payment_type,'"','')))) NOT IN
                    ('CREDIT_CARD','BOLETO','VOUCHER','DEBIT_CARD')
                    THEN CONCAT('Invalid payment_type: ', payment_type)
                WHEN TRY_CONVERT(DECIMAL(18,2), REPLACE(payment_value,'"','')) IS NULL
                  OR TRY_CONVERT(DECIMAL(18,2), REPLACE(payment_value,'"','')) <= 0
                    THEN CONCAT('Invalid payment_value: ', payment_value)
            END,
            order_id, payment_sequential,
            payment_type, payment_installments, payment_value
        FROM bronze.order_payments
        WHERE NULLIF(LTRIM(RTRIM(REPLACE(order_id,'"',''))), '') IS NULL
           OR UPPER(LTRIM(RTRIM(REPLACE(payment_type,'"','')))) NOT IN
              ('CREDIT_CARD','BOLETO','VOUCHER','DEBIT_CARD')
           OR TRY_CONVERT(DECIMAL(18,2), REPLACE(payment_value,'"','')) IS NULL
           OR TRY_CONVERT(DECIMAL(18,2), REPLACE(payment_value,'"','')) <= 0;

        INSERT INTO silver.order_payments (
            order_id, payment_sequential, payment_type,
            payment_installments, payment_value
        )
        SELECT
            LTRIM(RTRIM(REPLACE(order_id,'"',''))),
            TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(REPLACE(payment_sequential,'"',''))), '')),
            LOWER(LTRIM(RTRIM(REPLACE(payment_type,'"','')))),
            TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(REPLACE(payment_installments,'"',''))), '')),
            TRY_CONVERT(DECIMAL(18,2), NULLIF(LTRIM(RTRIM(REPLACE(payment_value,'"',''))), ''))
        FROM bronze.order_payments
        WHERE NULLIF(LTRIM(RTRIM(REPLACE(order_id,'"',''))), '') IS NOT NULL
          AND UPPER(LTRIM(RTRIM(REPLACE(payment_type,'"','')))) IN
              ('CREDIT_CARD','BOLETO','VOUCHER','DEBIT_CARD')
          AND TRY_CONVERT(DECIMAL(18,2), REPLACE(payment_value,'"','')) IS NOT NULL
          AND TRY_CONVERT(DECIMAL(18,2), REPLACE(payment_value,'"','')) > 0;

        UPDATE meta.etl_audit
        SET status    = 'SUCCESS',
            row_count = (SELECT COUNT(*) FROM silver.order_payments),
            message   = CONCAT('Payments loaded: ', (SELECT COUNT(*) FROM silver.order_payments),
                               ' | Rejects: ', (SELECT COUNT(*) FROM silver.reject_order_payments))
        WHERE run_id = @run_id AND step_name = 'LOAD_SILVER_ORDER_PAYMENTS';


        -- =============================================
        -- 5. ORDER REVIEWS
        -- =============================================
        INSERT INTO meta.etl_audit (run_id, layer_name, object_name, step_name, status, message)
        VALUES (@run_id, 'SILVER', 'silver.order_reviews', 'LOAD_SILVER_ORDER_REVIEWS', 'STARTED', 'Transforming reviews');

        TRUNCATE TABLE silver.order_reviews;
        TRUNCATE TABLE silver.reject_order_reviews;

        INSERT INTO silver.reject_order_reviews (
            reject_reason, review_id, order_id, review_score,
            review_comment_title, review_comment_message,
            review_creation_date, review_answer_timestamp
        )
        SELECT
            CASE
                WHEN NULLIF(LTRIM(RTRIM(REPLACE(review_id,'"',''))), '') IS NULL
                    THEN 'NULL review_id'
                WHEN NULLIF(LTRIM(RTRIM(REPLACE(order_id,'"',''))), '') IS NULL
                    THEN 'NULL order_id'
                WHEN TRY_CONVERT(INT, REPLACE(review_score,'"','')) IS NULL
                  OR TRY_CONVERT(INT, REPLACE(review_score,'"','')) NOT BETWEEN 1 AND 5
                    THEN CONCAT('Invalid review_score: ', review_score)
                WHEN NULLIF(LTRIM(RTRIM(REPLACE(review_creation_date,'"',''))), '') IS NULL
                    THEN 'NULL review_creation_date'
            END,
            review_id, order_id, review_score,
            review_comment_title, review_comment_message,
            review_creation_date, review_answer_timestamp
        FROM bronze.order_reviews
        WHERE NULLIF(LTRIM(RTRIM(REPLACE(review_id,'"',''))), '') IS NULL
           OR NULLIF(LTRIM(RTRIM(REPLACE(order_id,'"',''))), '') IS NULL
           OR TRY_CONVERT(INT, REPLACE(review_score,'"','')) IS NULL
           OR TRY_CONVERT(INT, REPLACE(review_score,'"','')) NOT BETWEEN 1 AND 5
           OR NULLIF(LTRIM(RTRIM(REPLACE(review_creation_date,'"',''))), '') IS NULL;

        INSERT INTO silver.order_reviews (
            review_id, order_id, review_score,
            review_comment_title, review_comment_message,
            review_creation_date, review_answer_timestamp
        )
        SELECT
            LTRIM(RTRIM(REPLACE(review_id,'"',''))),
            LTRIM(RTRIM(REPLACE(order_id,'"',''))),
            TRY_CONVERT(INT, REPLACE(review_score,'"','')),
            NULLIF(LTRIM(RTRIM(REPLACE(review_comment_title,'"',''))), ''),
            NULLIF(LTRIM(RTRIM(review_comment_message)), ''),
            TRY_CONVERT(DATETIME2, NULLIF(LTRIM(RTRIM(REPLACE(review_creation_date,'"',''))), '')),
            TRY_CONVERT(DATETIME2, NULLIF(LTRIM(RTRIM(REPLACE(review_answer_timestamp,'"',''))), ''))
        FROM bronze.order_reviews
        WHERE NULLIF(LTRIM(RTRIM(REPLACE(review_id,'"',''))), '') IS NOT NULL
          AND NULLIF(LTRIM(RTRIM(REPLACE(order_id,'"',''))), '') IS NOT NULL
          AND TRY_CONVERT(INT, REPLACE(review_score,'"','')) BETWEEN 1 AND 5
          AND NULLIF(LTRIM(RTRIM(REPLACE(review_creation_date,'"',''))), '') IS NOT NULL;

        UPDATE meta.etl_audit
        SET status    = 'SUCCESS',
            row_count = (SELECT COUNT(*) FROM silver.order_reviews),
            message   = CONCAT('Reviews loaded: ', (SELECT COUNT(*) FROM silver.order_reviews),
                               ' | Rejects: ', (SELECT COUNT(*) FROM silver.reject_order_reviews))
        WHERE run_id = @run_id AND step_name = 'LOAD_SILVER_ORDER_REVIEWS';


        -- =============================================
        -- 6. PRODUCTS
        -- =============================================
        INSERT INTO meta.etl_audit (run_id, layer_name, object_name, step_name, status, message)
        VALUES (@run_id, 'SILVER', 'silver.products', 'LOAD_SILVER_PRODUCTS', 'STARTED', 'Transforming products');

        TRUNCATE TABLE silver.products;
        TRUNCATE TABLE silver.reject_products;

        -- (same as your original, no city logic here)
        INSERT INTO silver.products (
            product_id, product_category_name,
            product_name_lenght, product_description_lenght,
            product_photos_qty, product_weight_g,
            product_length_cm, product_height_cm, product_width_cm
        )
        SELECT
            LTRIM(RTRIM(REPLACE(product_id,'"',''))),
            NULLIF(LTRIM(RTRIM(REPLACE(product_category_name,'"',''))), ''),
            TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(REPLACE(product_name_lenght,'"',''))), '')),
            TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(REPLACE(product_description_lenght,'"',''))), '')),
            TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(REPLACE(product_photos_qty,'"',''))), '')),
            TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(REPLACE(product_weight_g,'"',''))), '')),
            TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(REPLACE(product_length_cm,'"',''))), '')),
            TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(REPLACE(product_height_cm,'"',''))), '')),
            TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(REPLACE(product_width_cm,'"',''))), ''))
        FROM bronze.products
        WHERE NULLIF(LTRIM(RTRIM(REPLACE(product_id,'"',''))), '') IS NOT NULL;

        UPDATE meta.etl_audit
        SET status    = 'SUCCESS',
            row_count = (SELECT COUNT(*) FROM silver.products),
            message   = CONCAT('Products loaded: ', (SELECT COUNT(*) FROM silver.products))
        WHERE run_id = @run_id AND step_name = 'LOAD_SILVER_PRODUCTS';


        -- =============================================
        -- 7. SELLERS (Standardized City/State)
        -- =============================================
        INSERT INTO meta.etl_audit (run_id, layer_name, object_name, step_name, status, message)
        VALUES (@run_id, 'SILVER', 'silver.sellers', 'LOAD_SILVER_SELLERS', 'STARTED', 'Transforming sellers');

        TRUNCATE TABLE silver.sellers;
        TRUNCATE TABLE silver.reject_sellers;

        INSERT INTO silver.reject_sellers (
            reject_reason, seller_id, seller_zip_code_prefix,
            seller_city, seller_state
        )
        SELECT
            'NULL seller_id',
            seller_id, seller_zip_code_prefix,
            seller_city, seller_state
        FROM bronze.sellers
        WHERE NULLIF(LTRIM(RTRIM(REPLACE(seller_id,'"',''))), '') IS NULL;

        INSERT INTO silver.sellers (
            seller_id, seller_zip_code_prefix,
            seller_city, seller_state
        )
        SELECT
            LTRIM(RTRIM(REPLACE(seller_id,'"',''))),
            TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(REPLACE(seller_zip_code_prefix,'"',''))), '')),
            dbo.fn_standardize_city(seller_city),
            UPPER(LTRIM(RTRIM(REPLACE(seller_state,'"',''))))
        FROM bronze.sellers
        WHERE NULLIF(LTRIM(RTRIM(REPLACE(seller_id,'"',''))), '') IS NOT NULL;

        UPDATE meta.etl_audit
        SET status    = 'SUCCESS',
            row_count = (SELECT COUNT(*) FROM silver.sellers),
            message   = CONCAT('Sellers loaded: ', (SELECT COUNT(*) FROM silver.sellers),
                               ' | Rejects: ', (SELECT COUNT(*) FROM silver.reject_sellers))
        WHERE run_id = @run_id AND step_name = 'LOAD_SILVER_SELLERS';


        -- =============================================
        -- 8. GEOLOCATION (Deduplication + Standardized City)
        -- =============================================
        INSERT INTO meta.etl_audit (run_id, layer_name, object_name, step_name, status, message)
        VALUES (@run_id, 'SILVER', 'silver.geolocation', 'LOAD_SILVER_GEOLOCATION', 'STARTED', 'Transforming geolocation');

        TRUNCATE TABLE silver.geolocation;
        TRUNCATE TABLE silver.reject_geolocation;

        INSERT INTO silver.reject_geolocation (
            reject_reason, geolocation_zip_code_prefix,
            geolocation_lat, geolocation_lng,
            geolocation_city, geolocation_state
        )
        SELECT
            CASE
                WHEN NULLIF(LTRIM(RTRIM(REPLACE(geolocation_zip_code_prefix,'"',''))), '') IS NULL
                    THEN 'NULL zip_code_prefix'
                ELSE CONCAT('Coordinates out of Brazil range: lat=',
                            geolocation_lat, ' lng=', geolocation_lng)
            END,
            geolocation_zip_code_prefix, geolocation_lat,
            geolocation_lng, geolocation_city, geolocation_state
        FROM bronze.geolocation
        WHERE NULLIF(LTRIM(RTRIM(REPLACE(geolocation_zip_code_prefix,'"',''))), '') IS NULL
           OR TRY_CONVERT(FLOAT, REPLACE(geolocation_lat,'"','')) NOT BETWEEN -35 AND 5
           OR TRY_CONVERT(FLOAT, REPLACE(geolocation_lng,'"','')) NOT BETWEEN -74 AND -34;

        ;WITH ranked AS (
            SELECT
                TRY_CONVERT(INT, REPLACE(geolocation_zip_code_prefix,'"','')) AS zip,
                AVG(TRY_CONVERT(FLOAT, REPLACE(geolocation_lat,'"','')))
                    OVER (PARTITION BY REPLACE(geolocation_zip_code_prefix,'"','')) AS avg_lat,
                AVG(TRY_CONVERT(FLOAT, REPLACE(geolocation_lng,'"','')))
                    OVER (PARTITION BY REPLACE(geolocation_zip_code_prefix,'"','')) AS avg_lng,
                dbo.fn_standardize_city(geolocation_city) AS city,
                UPPER(LTRIM(RTRIM(REPLACE(geolocation_state,'"','')))) AS state,
                ROW_NUMBER() OVER (
                    PARTITION BY REPLACE(geolocation_zip_code_prefix,'"','')
                    ORDER BY geolocation_city DESC
                ) AS rn
            FROM bronze.geolocation
            WHERE NULLIF(LTRIM(RTRIM(REPLACE(geolocation_zip_code_prefix,'"',''))), '') IS NOT NULL
              AND TRY_CONVERT(FLOAT, REPLACE(geolocation_lat,'"','')) BETWEEN -35 AND 5
              AND TRY_CONVERT(FLOAT, REPLACE(geolocation_lng,'"','')) BETWEEN -74 AND -34
        )
        INSERT INTO silver.geolocation (
            geolocation_zip_code_prefix, geolocation_lat,
            geolocation_lng, geolocation_city, geolocation_state
        )
        SELECT zip, avg_lat, avg_lng, city, state
        FROM ranked
        WHERE rn = 1;

        UPDATE meta.etl_audit
        SET status    = 'SUCCESS',
            row_count = (SELECT COUNT(*) FROM silver.geolocation),
            message   = CONCAT('Geolocation loaded after dedup: ',
                               (SELECT COUNT(*) FROM silver.geolocation),
                               ' | Rejects: ', (SELECT COUNT(*) FROM silver.reject_geolocation))
        WHERE run_id = @run_id AND step_name = 'LOAD_SILVER_GEOLOCATION';


        -- =============================================
        -- 9. CATEGORY TRANSLATION
        -- =============================================
        INSERT INTO meta.etl_audit (run_id, layer_name, object_name, step_name, status, message)
        VALUES (@run_id, 'SILVER', 'silver.category_translation', 'LOAD_SILVER_CATEGORY', 'STARTED', 'Transforming category translation');

        TRUNCATE TABLE silver.category_translation;

        INSERT INTO silver.category_translation (
            product_category_name,
            product_category_name_english
        )
        SELECT
            LTRIM(RTRIM(REPLACE(product_category_name,'"',''))),
            LTRIM(RTRIM(REPLACE(product_category_name_english,'"','')))
        FROM bronze.category_translation
        WHERE NULLIF(LTRIM(RTRIM(REPLACE(product_category_name,'"',''))), '') IS NOT NULL
          AND NULLIF(LTRIM(RTRIM(REPLACE(product_category_name_english,'"',''))), '') IS NOT NULL;

        UPDATE meta.etl_audit
        SET status    = 'SUCCESS',
            row_count = (SELECT COUNT(*) FROM silver.category_translation),
            message   = CONCAT('Category translation loaded: ',
                               (SELECT COUNT(*) FROM silver.category_translation))
        WHERE run_id = @run_id AND step_name = 'LOAD_SILVER_CATEGORY';


        -- =============================================
        -- MARK PIPELINE SUCCESS
        -- =============================================
        UPDATE meta.etl_run
        SET run_status  = 'SUCCESS',
            run_end_utc = SYSUTCDATETIME(),
            notes       = CONCAT(ISNULL(notes, ''), ' | Silver load completed.')
        WHERE run_id = @run_id;

        SELECT @run_id AS run_id_completed;

    END TRY

    BEGIN CATCH
        DECLARE @err NVARCHAR(2000) = ERROR_MESSAGE();

        UPDATE meta.etl_run
        SET run_status  = 'FAILED',
            run_end_utc = SYSUTCDATETIME(),
            notes       = CONCAT(ISNULL(notes, ''), ' | ERROR: ', @err)
        WHERE run_id = @run_id;

        INSERT INTO meta.etl_audit (run_id, layer_name, object_name, step_name, status, message)
        VALUES (@run_id, 'SILVER', 'N/A', 'LOAD_SILVER_FAILED', 'FAILED', @err);

        THROW;
    END CATCH

END;
GO