-- Check null counts
SELECT
    SUM(CASE WHEN product_id IS NULL OR product_id = '' THEN 1 ELSE 0 END)                     AS null_product_id,
    SUM(CASE WHEN product_category_name IS NULL OR product_category_name = '' THEN 1 ELSE 0 END) AS null_category,
    SUM(CASE WHEN product_weight_g IS NULL OR product_weight_g = '' THEN 1 ELSE 0 END)         AS null_weight,
    SUM(CASE WHEN product_length_cm IS NULL OR product_length_cm = '' THEN 1 ELSE 0 END)       AS null_length,
    SUM(CASE WHEN product_height_cm IS NULL OR product_height_cm = '' THEN 1 ELSE 0 END)       AS null_height,
    SUM(CASE WHEN product_width_cm IS NULL OR product_width_cm = '' THEN 1 ELSE 0 END)         AS null_width
FROM bronze.products;

-- Check for zero or negative dimensions
SELECT COUNT(*) AS bad_dimensions
FROM bronze.products
WHERE TRY_CONVERT(INT, product_weight_g) <= 0
   OR TRY_CONVERT(INT, product_length_cm) <= 0
   OR TRY_CONVERT(INT, product_height_cm) <= 0
   OR TRY_CONVERT(INT, product_width_cm) <= 0;

-- Check distinct categories
SELECT product_category_name, COUNT(*) AS cnt
FROM bronze.products
GROUP BY product_category_name
ORDER BY cnt DESC;