-- Check distinct payment types
SELECT payment_type, COUNT(*) AS cnt
FROM bronze.order_payments
GROUP BY payment_type
ORDER BY cnt DESC;

-- Check null counts
SELECT
    SUM(CASE WHEN order_id IS NULL OR order_id = '' THEN 1 ELSE 0 END)             AS null_order_id,
    SUM(CASE WHEN payment_type IS NULL OR payment_type = '' THEN 1 ELSE 0 END)     AS null_payment_type,
    SUM(CASE WHEN payment_value IS NULL OR payment_value = '' THEN 1 ELSE 0 END)   AS null_payment_value
FROM bronze.order_payments;

-- Check for zero or negative payment values
SELECT COUNT(*) AS bad_payment_value
FROM bronze.order_payments
WHERE TRY_CONVERT(DECIMAL(18,2), payment_value) <= 0;

-- Check installments range
SELECT
    MIN(TRY_CONVERT(INT, payment_installments)) AS min_installments,
    MAX(TRY_CONVERT(INT, payment_installments)) AS max_installments
FROM bronze.order_payments;