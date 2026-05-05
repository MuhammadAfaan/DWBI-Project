-- Check distinct review scores
SELECT review_score, COUNT(*) AS cnt
FROM bronze.order_reviews
GROUP BY review_score
ORDER BY review_score;

-- Check null counts
SELECT
    SUM(CASE WHEN review_id IS NULL OR review_id = '' THEN 1 ELSE 0 END)               AS null_review_id,
    SUM(CASE WHEN order_id IS NULL OR order_id = '' THEN 1 ELSE 0 END)                 AS null_order_id,
    SUM(CASE WHEN review_score IS NULL OR review_score = '' THEN 1 ELSE 0 END)         AS null_score,
    SUM(CASE WHEN review_comment_title IS NULL OR review_comment_title = '' THEN 1 ELSE 0 END)   AS null_title,
    SUM(CASE WHEN review_comment_message IS NULL OR review_comment_message = '' THEN 1 ELSE 0 END) AS null_message,
    SUM(CASE WHEN review_creation_date IS NULL OR review_creation_date = '' THEN 1 ELSE 0 END)   AS null_creation_dt,
    SUM(CASE WHEN review_answer_timestamp IS NULL OR review_answer_timestamp = '' THEN 1 ELSE 0 END) AS null_answer_ts
FROM bronze.order_reviews;

-- Check scores outside valid range 1-5
SELECT COUNT(*) AS invalid_scores
FROM bronze.order_reviews
WHERE TRY_CONVERT(INT, review_score) NOT IN (1,2,3,4,5)
   OR TRY_CONVERT(INT, review_score) IS NULL;