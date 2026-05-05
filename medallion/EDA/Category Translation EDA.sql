-- Check total rows and nulls
SELECT
    COUNT(*) AS total_rows,
    SUM(CASE WHEN product_category_name IS NULL OR product_category_name = '' THEN 1 ELSE 0 END) AS null_portuguese,
    SUM(CASE WHEN product_category_name_english IS NULL OR product_category_name_english = '' THEN 1 ELSE 0 END) AS null_english
FROM bronze.category_translation;

-- Check for duplicates
SELECT product_category_name, COUNT(*) AS cnt
FROM bronze.category_translation
GROUP BY product_category_name
HAVING COUNT(*) > 1;

-- See all values
SELECT * FROM bronze.category_translation ORDER BY product_category_name;