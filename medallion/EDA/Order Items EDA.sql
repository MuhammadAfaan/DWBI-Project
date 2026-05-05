-- Check null counts
SELECT
    SUM(CASE WHEN order_id IS NULL OR order_id = '' THEN 1 ELSE 0 END)         AS null_order_id,
    SUM(CASE WHEN product_id IS NULL OR product_id = '' THEN 1 ELSE 0 END)     AS null_product_id,
    SUM(CASE WHEN seller_id IS NULL OR seller_id = '' THEN 1 ELSE 0 END)       AS null_seller_id,
    SUM(CASE WHEN price IS NULL OR price = '' THEN 1 ELSE 0 END)               AS null_price,
    SUM(CASE WHEN freight_value IS NULL OR freight_value = '' THEN 1 ELSE 0 END) AS null_freight
FROM bronze.order_items;

-- Check for negative or zero prices
SELECT COUNT(*) AS bad_price
FROM bronze.order_items
WHERE TRY_CONVERT(DECIMAL(18,2), price) <= 0;

-- Check for negative freight
SELECT COUNT(*) AS bad_freight
FROM bronze.order_items
WHERE TRY_CONVERT(DECIMAL(18,2), freight_value) < 0;

-- Check price range
SELECT
    MIN(TRY_CONVERT(DECIMAL(18,2), price)) AS min_price,
    MAX(TRY_CONVERT(DECIMAL(18,2), price)) AS max_price,
    AVG(TRY_CONVERT(DECIMAL(18,2), price)) AS avg_price
FROM bronze.order_items;