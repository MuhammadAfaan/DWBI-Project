USE OlistDW;
GO

-- Drop existing tables
DROP TABLE IF EXISTS gold.fact_reviews;
DROP TABLE IF EXISTS gold.fact_order_items;
DROP TABLE IF EXISTS gold.fact_orders;
DROP TABLE IF EXISTS gold.dim_product;
DROP TABLE IF EXISTS gold.dim_customer;
DROP TABLE IF EXISTS gold.dim_seller;
DROP TABLE IF EXISTS gold.dim_date;
GO

-- =============================================
-- GOLD DIMENSIONS
-- =============================================

CREATE TABLE gold.dim_customer (
    customer_sk                 INT IDENTITY(1,1) PRIMARY KEY,
    customer_id                 NVARCHAR(500) NOT NULL,
    customer_unique_id          NVARCHAR(500) NOT NULL,
    customer_zip_code_prefix    INT,
    customer_city               NVARCHAR(200),
    customer_state              NVARCHAR(100),
    latitude                    FLOAT, -- Added for mapping
    longitude                   FLOAT, -- Added for mapping
    dwh_create_date             DATETIME2 DEFAULT SYSUTCDATETIME()
);
GO

CREATE TABLE gold.dim_seller (
    seller_sk                   INT IDENTITY(1,1) PRIMARY KEY,
    seller_id                   NVARCHAR(500) NOT NULL,
    seller_zip_code_prefix      INT,
    seller_city                 NVARCHAR(200),
    seller_state                NVARCHAR(100),
    latitude                    FLOAT, -- Added for mapping
    longitude                   FLOAT, -- Added for mapping
    dwh_create_date             DATETIME2 DEFAULT SYSUTCDATETIME()
);
GO

CREATE TABLE gold.dim_product (
    product_sk                  INT IDENTITY(1,1) PRIMARY KEY,
    product_id                  NVARCHAR(500) NOT NULL,
    product_category_english    NVARCHAR(200), -- Translated English Name
    product_weight_g            INT,
    product_length_cm           INT,
    product_height_cm           INT,
    product_width_cm            INT,
    dwh_create_date             DATETIME2 DEFAULT SYSUTCDATETIME()
);
GO

CREATE TABLE gold.dim_date (
    date_key                    INT PRIMARY KEY, -- Format: YYYYMMDD
    full_date                   DATE NOT NULL,
    year                        INT NOT NULL,
    quarter                     INT NOT NULL,
    month                       INT NOT NULL,
    month_name                  NVARCHAR(20) NOT NULL,
    day_of_month                INT NOT NULL,
    day_of_week                 INT NOT NULL,
    day_name                    NVARCHAR(20) NOT NULL,
    is_weekend                  BIT NOT NULL
);
GO

-- =============================================
-- GOLD FACTS
-- =============================================

CREATE TABLE gold.fact_order_items (
    sales_sk                    BIGINT IDENTITY(1,1) PRIMARY KEY,
    order_id                    NVARCHAR(500) NOT NULL, 
    order_item_id               INT NOT NULL,
    customer_sk                 INT NOT NULL, 
    seller_sk                   INT NOT NULL, 
    product_sk                  INT NOT NULL, 
    order_date_key              INT, 
    price                       DECIMAL(18,2) NOT NULL,
    freight_value               DECIMAL(18,2) NOT NULL,
    dwh_create_date             DATETIME2 DEFAULT SYSUTCDATETIME()
);
GO

CREATE TABLE gold.fact_orders (
    order_sk                        BIGINT IDENTITY(1,1) PRIMARY KEY,
    order_id                        NVARCHAR(500) NOT NULL,
    customer_sk                     INT NOT NULL, 
    order_status                    NVARCHAR(50),
    order_date_key                  INT, 
    estimated_delivery_date_key     INT,          
    actual_delivery_date_key        INT,          
    delivery_time_days              INT,          -- Actual days to deliver
    is_late_delivery                BIT,          -- 1 = Late, 0 = On Time
    total_payment_value             DECIMAL(18,2),-- Summed from payments
    dwh_create_date                 DATETIME2 DEFAULT SYSUTCDATETIME()
);
GO

CREATE TABLE gold.fact_reviews (
    review_sk                       BIGINT IDENTITY(1,1) PRIMARY KEY,
    review_id                       NVARCHAR(500) NOT NULL,
    order_id                        NVARCHAR(500) NOT NULL,
    customer_sk                     INT NOT NULL, 
    review_creation_date_key        INT, 
    review_score                    INT NOT NULL,
    review_comment_title            NVARCHAR(500),  -- Portuguese Text Retained
    review_comment_message          NVARCHAR(4000), -- Portuguese Text Retained
    response_time_days              INT,          
    dwh_create_date                 DATETIME2 DEFAULT SYSUTCDATETIME()
);
GO