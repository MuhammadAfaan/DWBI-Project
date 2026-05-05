USE OlistDW;
GO

-- =============================================
-- BRONZE: ORDERS
-- =============================================
CREATE TABLE bronze.orders (
    order_id                        NVARCHAR(500),
    customer_id                     NVARCHAR(500),
    order_status                    NVARCHAR(500),
    order_purchase_timestamp        NVARCHAR(500),
    order_approved_at               NVARCHAR(500),
    order_delivered_carrier_date    NVARCHAR(500),
    order_delivered_customer_date   NVARCHAR(500),
    order_estimated_delivery_date   NVARCHAR(500)
);
GO

-- =============================================
-- BRONZE: CUSTOMERS
-- =============================================
CREATE TABLE bronze.customers (
    customer_id                 NVARCHAR(500),
    customer_unique_id          NVARCHAR(500),
    customer_zip_code_prefix    NVARCHAR(500),
    customer_city               NVARCHAR(500),
    customer_state              NVARCHAR(500)
);
GO

-- =============================================
-- BRONZE: ORDER ITEMS
-- =============================================
CREATE TABLE bronze.order_items (
    order_id                NVARCHAR(500),
    order_item_id           NVARCHAR(500),
    product_id              NVARCHAR(500),
    seller_id               NVARCHAR(500),
    shipping_limit_date     NVARCHAR(500),
    price                   NVARCHAR(500),
    freight_value           NVARCHAR(500)
);
GO

-- =============================================
-- BRONZE: ORDER PAYMENTS
-- =============================================
CREATE TABLE bronze.order_payments (
    order_id                NVARCHAR(500),
    payment_sequential      NVARCHAR(500),
    payment_type            NVARCHAR(500),
    payment_installments    NVARCHAR(500),
    payment_value           NVARCHAR(500)
);
GO

-- =============================================
-- BRONZE: ORDER REVIEWS
-- =============================================
CREATE TABLE bronze.order_reviews (
    review_id                   NVARCHAR(500),
    order_id                    NVARCHAR(500),
    review_score                NVARCHAR(500),
    review_comment_title        NVARCHAR(500),
    review_comment_message      NVARCHAR(4000),
    review_creation_date        NVARCHAR(500),
    review_answer_timestamp     NVARCHAR(500)
);
GO

-- =============================================
-- BRONZE: PRODUCTS
-- =============================================
CREATE TABLE bronze.products (
    product_id                      NVARCHAR(500),
    product_category_name           NVARCHAR(500),
    product_name_lenght             NVARCHAR(500),
    product_description_lenght      NVARCHAR(500),
    product_photos_qty              NVARCHAR(500),
    product_weight_g                NVARCHAR(500),
    product_length_cm               NVARCHAR(500),
    product_height_cm               NVARCHAR(500),
    product_width_cm                NVARCHAR(500)
);
GO

-- =============================================
-- BRONZE: SELLERS
-- =============================================
CREATE TABLE bronze.sellers (
    seller_id                   NVARCHAR(500),
    seller_zip_code_prefix      NVARCHAR(500),
    seller_city                 NVARCHAR(500),
    seller_state                NVARCHAR(500)
);
GO

-- =============================================
-- BRONZE: GEOLOCATION
-- =============================================
CREATE TABLE bronze.geolocation (
    geolocation_zip_code_prefix     NVARCHAR(500),
    geolocation_lat                 NVARCHAR(500),
    geolocation_lng                 NVARCHAR(500),
    geolocation_city                NVARCHAR(500),
    geolocation_state               NVARCHAR(500)
);
GO

-- =============================================
-- BRONZE: CATEGORY TRANSLATION
-- =============================================
CREATE TABLE bronze.category_translation (
    product_category_name           NVARCHAR(500),
    product_category_name_english   NVARCHAR(500)
);
GO