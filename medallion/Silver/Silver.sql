USE OlistDW;
GO

-- =============================================
-- SILVER: ORDERS
-- =============================================
CREATE TABLE silver.orders (
    order_id                        NVARCHAR(500),
    customer_id                     NVARCHAR(500),
    order_status                    NVARCHAR(50),
    order_purchase_timestamp        DATETIME2       NULL,
    order_approved_at               DATETIME2       NULL,
    order_delivered_carrier_date    DATETIME2       NULL,
    order_delivered_customer_date   DATETIME2       NULL,
    order_estimated_delivery_date   DATETIME2       NULL,
    dwh_create_date                 DATETIME2       DEFAULT SYSUTCDATETIME()
);
GO

CREATE TABLE silver.reject_orders (
    reject_id       BIGINT IDENTITY(1,1) PRIMARY KEY,
    reject_reason   NVARCHAR(500),
    order_id                        NVARCHAR(500),
    customer_id                     NVARCHAR(500),
    order_status                    NVARCHAR(500),
    order_purchase_timestamp        NVARCHAR(500),
    order_approved_at               NVARCHAR(500),
    order_delivered_carrier_date    NVARCHAR(500),
    order_delivered_customer_date   NVARCHAR(500),
    order_estimated_delivery_date   NVARCHAR(500),
    captured_utc    DATETIME2       DEFAULT SYSUTCDATETIME()
);
GO

-- =============================================
-- SILVER: CUSTOMERS
-- =============================================
CREATE TABLE silver.customers (
    customer_id                 NVARCHAR(500),
    customer_unique_id          NVARCHAR(500),
    customer_zip_code_prefix    INT,
    customer_city               NVARCHAR(200),
    customer_state              NVARCHAR(100),
    dwh_create_date             DATETIME2       DEFAULT SYSUTCDATETIME()
);
GO

CREATE TABLE silver.reject_customers (
    reject_id       BIGINT IDENTITY(1,1) PRIMARY KEY,
    reject_reason   NVARCHAR(500),
    customer_id                 NVARCHAR(500),
    customer_unique_id          NVARCHAR(500),
    customer_zip_code_prefix    NVARCHAR(500),
    customer_city               NVARCHAR(500),
    customer_state              NVARCHAR(500),
    captured_utc    DATETIME2       DEFAULT SYSUTCDATETIME()
);
GO

-- =============================================
-- SILVER: ORDER ITEMS
-- =============================================
CREATE TABLE silver.order_items (
    order_id                NVARCHAR(500),
    order_item_id           INT,
    product_id              NVARCHAR(500),
    seller_id               NVARCHAR(500),
    shipping_limit_date     DATETIME2       NULL,
    price                   DECIMAL(18,2),
    freight_value           DECIMAL(18,2),
    dwh_create_date         DATETIME2       DEFAULT SYSUTCDATETIME()
);
GO

CREATE TABLE silver.reject_order_items (
    reject_id       BIGINT IDENTITY(1,1) PRIMARY KEY,
    reject_reason   NVARCHAR(500),
    order_id                NVARCHAR(500),
    order_item_id           NVARCHAR(500),
    product_id              NVARCHAR(500),
    seller_id               NVARCHAR(500),
    shipping_limit_date     NVARCHAR(500),
    price                   NVARCHAR(500),
    freight_value           NVARCHAR(500),
    captured_utc    DATETIME2       DEFAULT SYSUTCDATETIME()
);
GO

-- =============================================
-- SILVER: ORDER PAYMENTS
-- =============================================
CREATE TABLE silver.order_payments (
    order_id                NVARCHAR(500),
    payment_sequential      INT,
    payment_type            NVARCHAR(50),
    payment_installments    INT,
    payment_value           DECIMAL(18,2),
    dwh_create_date         DATETIME2       DEFAULT SYSUTCDATETIME()
);
GO

CREATE TABLE silver.reject_order_payments (
    reject_id       BIGINT IDENTITY(1,1) PRIMARY KEY,
    reject_reason   NVARCHAR(500),
    order_id                NVARCHAR(500),
    payment_sequential      NVARCHAR(500),
    payment_type            NVARCHAR(500),
    payment_installments    NVARCHAR(500),
    payment_value           NVARCHAR(500),
    captured_utc    DATETIME2       DEFAULT SYSUTCDATETIME()
);
GO

-- =============================================
-- SILVER: ORDER REVIEWS
-- =============================================
CREATE TABLE silver.order_reviews (
    review_id                   NVARCHAR(500),
    order_id                    NVARCHAR(500),
    review_score                INT,
    review_comment_title        NVARCHAR(500)   NULL,
    review_comment_message      NVARCHAR(4000)  NULL,
    review_creation_date        DATETIME2       NULL,
    review_answer_timestamp     DATETIME2       NULL,
    dwh_create_date             DATETIME2       DEFAULT SYSUTCDATETIME()
);
GO

CREATE TABLE silver.reject_order_reviews (
    reject_id       BIGINT IDENTITY(1,1) PRIMARY KEY,
    reject_reason   NVARCHAR(500),
    review_id                   NVARCHAR(500),
    order_id                    NVARCHAR(500),
    review_score                NVARCHAR(500),
    review_comment_title        NVARCHAR(500),
    review_comment_message      NVARCHAR(4000),
    review_creation_date        NVARCHAR(500),
    review_answer_timestamp     NVARCHAR(500),
    captured_utc    DATETIME2       DEFAULT SYSUTCDATETIME()
);
GO

-- =============================================
-- SILVER: PRODUCTS
-- =============================================
CREATE TABLE silver.products (
    product_id                      NVARCHAR(500),
    product_category_name           NVARCHAR(200)   NULL,
    product_name_lenght             INT             NULL,
    product_description_lenght      INT             NULL,
    product_photos_qty              INT             NULL,
    product_weight_g                INT             NULL,
    product_length_cm               INT             NULL,
    product_height_cm               INT             NULL,
    product_width_cm                INT             NULL,
    dwh_create_date                 DATETIME2       DEFAULT SYSUTCDATETIME()
);
GO

CREATE TABLE silver.reject_products (
    reject_id       BIGINT IDENTITY(1,1) PRIMARY KEY,
    reject_reason   NVARCHAR(500),
    product_id                      NVARCHAR(500),
    product_category_name           NVARCHAR(500),
    product_name_lenght             NVARCHAR(500),
    product_description_lenght      NVARCHAR(500),
    product_photos_qty              NVARCHAR(500),
    product_weight_g                NVARCHAR(500),
    product_length_cm               NVARCHAR(500),
    product_height_cm               NVARCHAR(500),
    product_width_cm                NVARCHAR(500),
    captured_utc    DATETIME2       DEFAULT SYSUTCDATETIME()
);
GO

-- =============================================
-- SILVER: SELLERS
-- =============================================
CREATE TABLE silver.sellers (
    seller_id                   NVARCHAR(500),
    seller_zip_code_prefix      INT,
    seller_city                 NVARCHAR(200),
    seller_state                NVARCHAR(100),
    dwh_create_date             DATETIME2       DEFAULT SYSUTCDATETIME()
);
GO

CREATE TABLE silver.reject_sellers (
    reject_id       BIGINT IDENTITY(1,1) PRIMARY KEY,
    reject_reason   NVARCHAR(500),
    seller_id                   NVARCHAR(500),
    seller_zip_code_prefix      NVARCHAR(500),
    seller_city                 NVARCHAR(500),
    seller_state                NVARCHAR(500),
    captured_utc    DATETIME2       DEFAULT SYSUTCDATETIME()
);
GO

-- =============================================
-- SILVER: GEOLOCATION
-- =============================================
CREATE TABLE silver.geolocation (
    geolocation_zip_code_prefix     INT,
    geolocation_lat                 FLOAT,
    geolocation_lng                 FLOAT,
    geolocation_city                NVARCHAR(200),
    geolocation_state               NVARCHAR(100),
    dwh_create_date                 DATETIME2       DEFAULT SYSUTCDATETIME()
);
GO

CREATE TABLE silver.reject_geolocation (
    reject_id       BIGINT IDENTITY(1,1) PRIMARY KEY,
    reject_reason   NVARCHAR(500),
    geolocation_zip_code_prefix     NVARCHAR(500),
    geolocation_lat                 NVARCHAR(500),
    geolocation_lng                 NVARCHAR(500),
    geolocation_city                NVARCHAR(500),
    geolocation_state               NVARCHAR(500),
    captured_utc    DATETIME2       DEFAULT SYSUTCDATETIME()
);
GO

-- =============================================
-- SILVER: CATEGORY TRANSLATION
-- =============================================
CREATE TABLE silver.category_translation (
    product_category_name           NVARCHAR(200),
    product_category_name_english   NVARCHAR(200),
    dwh_create_date                 DATETIME2       DEFAULT SYSUTCDATETIME()
);
GO