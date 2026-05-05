-- Check null counts
SELECT
    SUM(CASE WHEN customer_id IS NULL OR customer_id = '' THEN 1 ELSE 0 END)            AS null_customer_id,
    SUM(CASE WHEN customer_unique_id IS NULL OR customer_unique_id = '' THEN 1 ELSE 0 END) AS null_unique_id,
    SUM(CASE WHEN customer_zip_code_prefix IS NULL OR customer_zip_code_prefix = '' THEN 1 ELSE 0 END) AS null_zip,
    SUM(CASE WHEN customer_city IS NULL OR customer_city = '' THEN 1 ELSE 0 END)        AS null_city,
    SUM(CASE WHEN customer_state IS NULL OR customer_state = '' THEN 1 ELSE 0 END)      AS null_state
FROM bronze.customers;

-- Check distinct states -- should all be 2 char Brazilian state codes
SELECT customer_state, COUNT(*) AS cnt
FROM bronze.customers
GROUP BY customer_state
ORDER BY cnt DESC;

-- Check city casing issues
SELECT DISTINCT TOP 20 customer_city
FROM bronze.customers
ORDER BY customer_city;

-- Check zip code converts to int cleanly
SELECT COUNT(*) AS bad_zip
FROM bronze.customers
WHERE TRY_CONVERT(INT, customer_zip_code_prefix) IS NULL
  AND customer_zip_code_prefix IS NOT NULL;