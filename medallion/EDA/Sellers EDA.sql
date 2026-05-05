-- Check null counts
SELECT
    SUM(CASE WHEN seller_id IS NULL OR seller_id = '' THEN 1 ELSE 0 END)                   AS null_seller_id,
    SUM(CASE WHEN seller_zip_code_prefix IS NULL OR seller_zip_code_prefix = '' THEN 1 ELSE 0 END) AS null_zip,
    SUM(CASE WHEN seller_city IS NULL OR seller_city = '' THEN 1 ELSE 0 END)               AS null_city,
    SUM(CASE WHEN seller_state IS NULL OR seller_state = '' THEN 1 ELSE 0 END)             AS null_state
FROM bronze.sellers;

-- Check distinct states
SELECT seller_state, COUNT(*) AS cnt
FROM bronze.sellers
GROUP BY seller_state
ORDER BY cnt DESC;

-- Check city casing
SELECT DISTINCT TOP 20 seller_city
FROM bronze.sellers
ORDER BY seller_city;