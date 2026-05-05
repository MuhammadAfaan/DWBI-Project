USE OlistDW;
GO

-- 1. Clear the table just in case it has partial data
TRUNCATE TABLE gold.dim_date;
GO

-- 2. Standardize server settings (Ensures Sunday is day 1 for the weekend check)
SET DATEFIRST 7; 

-- 3. Set our start and end points
DECLARE @StartDate DATE = '2016-01-01';
DECLARE @EndDate DATE = '2019-12-31';
DECLARE @CurrentDate DATE = @StartDate;

PRINT 'Generating calendar dates...';

-- 4. Loop through every single day
WHILE @CurrentDate <= @EndDate
BEGIN
    INSERT INTO gold.dim_date (
        date_key,
        full_date,
        year,
        quarter,
        month,
        month_name,
        day_of_month,
        day_of_week,
        day_name,
        is_weekend
    )
    VALUES (
        CAST(CONVERT(VARCHAR(8), @CurrentDate, 112) AS INT), -- Turns '2016-01-01' into 20160101
        @CurrentDate,
        YEAR(@CurrentDate),
        DATEPART(QUARTER, @CurrentDate),
        MONTH(@CurrentDate),
        DATENAME(MONTH, @CurrentDate),
        DAY(@CurrentDate),
        DATEPART(WEEKDAY, @CurrentDate),
        DATENAME(WEEKDAY, @CurrentDate),
        CASE WHEN DATEPART(WEEKDAY, @CurrentDate) IN (1, 7) THEN 1 ELSE 0 END -- 1=Sun, 7=Sat
    );

    -- Move to the next day
    SET @CurrentDate = DATEADD(DAY, 1, @CurrentDate);
END

PRINT 'Calendar generation complete!';

-- Verify the row count (Should be 1,461 rows for 4 full years)
SELECT 'gold.dim_date' AS table_name, COUNT(*) AS row_count FROM gold.dim_date;
GO