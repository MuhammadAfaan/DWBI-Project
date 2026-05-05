USE OlistDW;
GO

DROP PROCEDURE IF EXISTS bronze.load_bronze;
GO

CREATE PROCEDURE bronze.load_bronze
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @run_id BIGINT;

    BEGIN TRY

        -- =============================================
        -- 1. START ETL RUN
        -- =============================================
        INSERT INTO meta.etl_run (pipeline_name, notes)
        VALUES ('OLIST_BRONZE_PIPELINE', 'Bronze ingestion from Olist CSV files');
        SET @run_id = SCOPE_IDENTITY();

        -- =============================================
        -- 2. ORDERS
        -- =============================================
        INSERT INTO meta.etl_audit (run_id, layer_name, object_name, step_name, status, message)
        VALUES (@run_id, 'BRONZE', 'bronze.orders', 'LOAD_BRONZE_ORDERS', 'STARTED', 'Starting BULK INSERT');

        TRUNCATE TABLE bronze.orders;

        BULK INSERT bronze.orders
        FROM 'C:\Users\AFAN\Downloads\OlistData\olist_orders_dataset.csv'
        WITH (
            FIRSTROW        = 2,
            FIELDTERMINATOR = ',',
            ROWTERMINATOR   = '0x0a',
            CODEPAGE        = '65001',
            FIELDQUOTE      = '"',
            TABLOCK
        );

        UPDATE meta.etl_audit
        SET status    = 'SUCCESS',
            row_count = (SELECT COUNT(*) FROM bronze.orders),
            message   = 'Loaded successfully'
        WHERE run_id = @run_id AND step_name = 'LOAD_BRONZE_ORDERS';

        -- =============================================
        -- 3. CUSTOMERS
        -- =============================================
        INSERT INTO meta.etl_audit (run_id, layer_name, object_name, step_name, status, message)
        VALUES (@run_id, 'BRONZE', 'bronze.customers', 'LOAD_BRONZE_CUSTOMERS', 'STARTED', 'Starting BULK INSERT');

        TRUNCATE TABLE bronze.customers;

        BULK INSERT bronze.customers
        FROM 'C:\Users\AFAN\Downloads\OlistData\olist_customers_dataset.csv'
        WITH (
            FIRSTROW        = 2,
            FIELDTERMINATOR = ',',
            ROWTERMINATOR   = '0x0a',
            CODEPAGE        = '65001',
            FIELDQUOTE      = '"',
            TABLOCK
        );

        UPDATE meta.etl_audit
        SET status    = 'SUCCESS',
            row_count = (SELECT COUNT(*) FROM bronze.customers),
            message   = 'Loaded successfully'
        WHERE run_id = @run_id AND step_name = 'LOAD_BRONZE_CUSTOMERS';

        -- =============================================
        -- 4. ORDER ITEMS
        -- =============================================
        INSERT INTO meta.etl_audit (run_id, layer_name, object_name, step_name, status, message)
        VALUES (@run_id, 'BRONZE', 'bronze.order_items', 'LOAD_BRONZE_ORDER_ITEMS', 'STARTED', 'Starting BULK INSERT');

        TRUNCATE TABLE bronze.order_items;

        BULK INSERT bronze.order_items
        FROM 'C:\Users\AFAN\Downloads\OlistData\olist_order_items_dataset.csv'
        WITH (
            FIRSTROW        = 2,
            FIELDTERMINATOR = ',',
            ROWTERMINATOR   = '0x0a',
            CODEPAGE        = '65001',
            FIELDQUOTE      = '"',
            TABLOCK
        );

        UPDATE meta.etl_audit
        SET status    = 'SUCCESS',
            row_count = (SELECT COUNT(*) FROM bronze.order_items),
            message   = 'Loaded successfully'
        WHERE run_id = @run_id AND step_name = 'LOAD_BRONZE_ORDER_ITEMS';

        -- =============================================
        -- 5. ORDER PAYMENTS
        -- =============================================
        INSERT INTO meta.etl_audit (run_id, layer_name, object_name, step_name, status, message)
        VALUES (@run_id, 'BRONZE', 'bronze.order_payments', 'LOAD_BRONZE_ORDER_PAYMENTS', 'STARTED', 'Starting BULK INSERT');

        TRUNCATE TABLE bronze.order_payments;

        BULK INSERT bronze.order_payments
        FROM 'C:\Users\AFAN\Downloads\OlistData\olist_order_payments_dataset.csv'
        WITH (
            FIRSTROW        = 2,
            FIELDTERMINATOR = ',',
            ROWTERMINATOR   = '0x0a',
            CODEPAGE        = '65001',
            FIELDQUOTE      = '"',
            TABLOCK
        );

        UPDATE meta.etl_audit
        SET status    = 'SUCCESS',
            row_count = (SELECT COUNT(*) FROM bronze.order_payments),
            message   = 'Loaded successfully'
        WHERE run_id = @run_id AND step_name = 'LOAD_BRONZE_ORDER_PAYMENTS';

        -- =============================================
        -- 6. ORDER REVIEWS
        -- =============================================
        INSERT INTO meta.etl_audit (run_id, layer_name, object_name, step_name, status, message)
        VALUES (@run_id, 'BRONZE', 'bronze.order_reviews', 'LOAD_BRONZE_ORDER_REVIEWS', 'STARTED', 'Starting BULK INSERT');

        TRUNCATE TABLE bronze.order_reviews;

        BULK INSERT bronze.order_reviews
        FROM 'C:\Users\AFAN\Downloads\OlistData\olist_order_reviews_dataset.csv'
        WITH (
            FIRSTROW        = 2,
            FIELDTERMINATOR = ',',
            ROWTERMINATOR   = '0x0a',
            CODEPAGE        = '65001',
            FIELDQUOTE      = '"',
            TABLOCK
        );

        UPDATE meta.etl_audit
        SET status    = 'SUCCESS',
            row_count = (SELECT COUNT(*) FROM bronze.order_reviews),
            message   = 'Loaded successfully'
        WHERE run_id = @run_id AND step_name = 'LOAD_BRONZE_ORDER_REVIEWS';

        -- =============================================
        -- 7. PRODUCTS
        -- =============================================
        INSERT INTO meta.etl_audit (run_id, layer_name, object_name, step_name, status, message)
        VALUES (@run_id, 'BRONZE', 'bronze.products', 'LOAD_BRONZE_PRODUCTS', 'STARTED', 'Starting BULK INSERT');

        TRUNCATE TABLE bronze.products;

        BULK INSERT bronze.products
        FROM 'C:\Users\AFAN\Downloads\OlistData\olist_products_dataset.csv'
        WITH (
            FIRSTROW        = 2,
            FIELDTERMINATOR = ',',
            ROWTERMINATOR   = '0x0a',
            CODEPAGE        = '65001',
            FIELDQUOTE      = '"',
            TABLOCK
        );

        UPDATE meta.etl_audit
        SET status    = 'SUCCESS',
            row_count = (SELECT COUNT(*) FROM bronze.products),
            message   = 'Loaded successfully'
        WHERE run_id = @run_id AND step_name = 'LOAD_BRONZE_PRODUCTS';

        -- =============================================
        -- 8. SELLERS
        -- =============================================
        INSERT INTO meta.etl_audit (run_id, layer_name, object_name, step_name, status, message)
        VALUES (@run_id, 'BRONZE', 'bronze.sellers', 'LOAD_BRONZE_SELLERS', 'STARTED', 'Starting BULK INSERT');

        TRUNCATE TABLE bronze.sellers;

        BULK INSERT bronze.sellers
        FROM 'C:\Users\AFAN\Downloads\OlistData\olist_sellers_dataset.csv'
        WITH (
            FIRSTROW        = 2,
            FIELDTERMINATOR = ',',
            ROWTERMINATOR   = '0x0a',
            CODEPAGE        = '65001',
            FIELDQUOTE      = '"',
            TABLOCK
        );

        UPDATE meta.etl_audit
        SET status    = 'SUCCESS',
            row_count = (SELECT COUNT(*) FROM bronze.sellers),
            message   = 'Loaded successfully'
        WHERE run_id = @run_id AND step_name = 'LOAD_BRONZE_SELLERS';

        -- =============================================
        -- 9. GEOLOCATION
        -- =============================================
        INSERT INTO meta.etl_audit (run_id, layer_name, object_name, step_name, status, message)
        VALUES (@run_id, 'BRONZE', 'bronze.geolocation', 'LOAD_BRONZE_GEOLOCATION', 'STARTED', 'Starting BULK INSERT');

        TRUNCATE TABLE bronze.geolocation;

        BULK INSERT bronze.geolocation
        FROM 'C:\Users\AFAN\Downloads\OlistData\olist_geolocation_dataset.csv'
        WITH (
            FIRSTROW        = 2,
            FIELDTERMINATOR = ',',
            ROWTERMINATOR   = '0x0a',
            CODEPAGE        = '65001',
            FIELDQUOTE      = '"',
            TABLOCK
        );

        UPDATE meta.etl_audit
        SET status    = 'SUCCESS',
            row_count = (SELECT COUNT(*) FROM bronze.geolocation),
            message   = 'Loaded successfully'
        WHERE run_id = @run_id AND step_name = 'LOAD_BRONZE_GEOLOCATION';

        -- =============================================
        -- 10. CATEGORY TRANSLATION
        -- =============================================
        INSERT INTO meta.etl_audit (run_id, layer_name, object_name, step_name, status, message)
        VALUES (@run_id, 'BRONZE', 'bronze.category_translation', 'LOAD_BRONZE_CATEGORY', 'STARTED', 'Starting BULK INSERT');

        TRUNCATE TABLE bronze.category_translation;

        BULK INSERT bronze.category_translation
        FROM 'C:\Users\AFAN\Downloads\OlistData\product_category_name_translation.csv'
        WITH (
            FIRSTROW        = 2,
            FIELDTERMINATOR = ',',
            ROWTERMINATOR   = '0x0a',
            CODEPAGE        = '65001',
            FIELDQUOTE      = '"',
            TABLOCK
        );

        UPDATE meta.etl_audit
        SET status    = 'SUCCESS',
            row_count = (SELECT COUNT(*) FROM bronze.category_translation),
            message   = 'Loaded successfully'
        WHERE run_id = @run_id AND step_name = 'LOAD_BRONZE_CATEGORY';

        -- =============================================
        -- 11. MARK PIPELINE SUCCESS
        -- =============================================
        UPDATE meta.etl_run
        SET run_status  = 'SUCCESS',
            run_end_utc = SYSUTCDATETIME()
        WHERE run_id = @run_id;

        SELECT @run_id AS run_id_completed;

    END TRY

    BEGIN CATCH
        DECLARE @err NVARCHAR(2000) = ERROR_MESSAGE();

        IF @run_id IS NOT NULL
        BEGIN
            UPDATE meta.etl_run
            SET run_status  = 'FAILED',
                run_end_utc = SYSUTCDATETIME(),
                notes       = CONCAT(ISNULL(notes, ''), ' | ERROR: ', @err)
            WHERE run_id = @run_id;

            INSERT INTO meta.etl_audit (run_id, layer_name, object_name, step_name, status, message)
            VALUES (@run_id, 'BRONZE', 'N/A', 'LOAD_BRONZE_FAILED', 'FAILED', @err);
        END

        RAISERROR(@err, 16, 1);
    END CATCH

END
GO