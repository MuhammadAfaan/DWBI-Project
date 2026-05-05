USE OlistDW;
GO


SELECT *
FROM gold.vw_kpi_monthly_sales_trend
ORDER BY year, month;
GO



SELECT TOP 20 *
FROM gold.vw_kpi_product_performance
ORDER BY total_revenue DESC;
GO



SELECT *
FROM gold.vw_kpi_logistics_health
ORDER BY late_delivery_rate_pct DESC;
GO



SELECT TOP 20 *
FROM gold.vw_kpi_seller_scorecard
ORDER BY total_revenue_generated DESC;
GO



SELECT *
FROM gold.vw_kpi_customer_satisfaction
ORDER BY average_review_score ASC;
GO



SELECT *
FROM gold.vw_kpi_delivery_review_correlation
ORDER BY delivery_bucket ASC;
GO



SELECT *
FROM gold.vw_kpi_category_freight_ratio
ORDER BY freight_ratio_pct ASC;
GO



SELECT *
FROM gold.vw_kpi_order_status_funnel
ORDER BY total_orders DESC;
GO