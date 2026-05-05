-- Total rows vs unique zip codes
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT geolocation_zip_code_prefix) AS unique_zips
FROM bronze.geolocation;

-- Check null counts
SELECT
    SUM(CASE WHEN geolocation_zip_code_prefix IS NULL OR geolocation_zip_code_prefix = '' THEN 1 ELSE 0 END) AS null_zip,
    SUM(CASE WHEN geolocation_lat IS NULL OR geolocation_lat = '' THEN 1 ELSE 0 END)   AS null_lat,
    SUM(CASE WHEN geolocation_lng IS NULL OR geolocation_lng = '' THEN 1 ELSE 0 END)   AS null_lng,
    SUM(CASE WHEN geolocation_city IS NULL OR geolocation_city = '' THEN 1 ELSE 0 END) AS null_city,
    SUM(CASE WHEN geolocation_state IS NULL OR geolocation_state = '' THEN 1 ELSE 0 END) AS null_state
FROM bronze.geolocation;

-- Check lat lng range -- Brazil is roughly lat -35 to 5, lng -74 to -34
SELECT COUNT(*) AS out_of_range_coords
FROM bronze.geolocation
WHERE TRY_CONVERT(FLOAT, geolocation_lat) NOT BETWEEN -35 AND 5
   OR TRY_CONVERT(FLOAT, geolocation_lng) NOT BETWEEN -74 AND -34;