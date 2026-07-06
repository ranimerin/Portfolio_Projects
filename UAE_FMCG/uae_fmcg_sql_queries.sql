-- ============================================================
-- UAE FMCG SALES ANALYTICS - PORTFOLIO PROJECT
-- Dataset: 2,000 orders | 2023-2024 | UAE Market
-- ============================================================
use TestDB
SELECT * FROM sales
-- ============================================================
-- 1. REVENUE OVERVIEW
-- Total revenue, profit, and margin summary
-- ============================================================
SELECT
    year,
    quarter,
    ROUND(SUM(revenue_aed), 2)        AS total_revenue_aed,
    ROUND(SUM(cogs_aed), 2)           AS total_cogs_aed,
    ROUND(SUM(gross_profit_aed), 2)   AS total_gross_profit_aed,
    ROUND(SUM(gross_profit_aed) * 100.0 / SUM(revenue_aed), 1) AS gross_margin_pct,
    COUNT(DISTINCT order_id)          AS total_orders
FROM sales
GROUP BY year, quarter
ORDER BY year, quarter;


-- ============================================================
-- 2. MONTH-OVER-MONTH REVENUE GROWTH
-- Tracks revenue trend and growth rate
-- ============================================================
WITH monthly_revenue AS (
    SELECT
        year,
        month,
        ROUND(SUM(revenue_aed), 2) AS revenue
    FROM sales
    GROUP BY year, month
)
SELECT
    year,
    month,
    revenue,
    LAG(revenue) OVER (ORDER BY year, month) AS prev_month_revenue,
    ROUND(
        (revenue - LAG(revenue) OVER (ORDER BY year, month)) * 100.0
        / LAG(revenue) OVER (ORDER BY year, month), 1
    ) AS mom_growth_pct
FROM monthly_revenue
ORDER BY year, month;


-- ============================================================
-- 3. REVENUE BY EMIRATE
-- Performance breakdown across UAE regions
-- ============================================================
SELECT
    emirate,
    COUNT(DISTINCT order_id)                AS total_orders,
    ROUND(SUM(revenue_aed), 2)              AS total_revenue_aed,
    ROUND(AVG(revenue_aed), 2)              AS avg_order_value_aed,
    ROUND(SUM(gross_profit_aed), 2)         AS total_profit_aed,
    ROUND(SUM(gross_profit_aed) * 100.0
          / SUM(revenue_aed), 1)            AS gross_margin_pct,
    ROUND(SUM(revenue_aed) * 100.0
          / (SELECT SUM(revenue_aed) FROM sales), 1) AS revenue_share_pct
FROM sales
GROUP BY emirate
ORDER BY total_revenue_aed DESC;


-- ============================================================
-- 4. TOP 10 PRODUCTS BY REVENUE
-- Best performing SKUs with margin analysis
-- ============================================================
SELECT
    product,
    category,
    SUM(quantity)                           AS total_units_sold,
    ROUND(SUM(revenue_aed), 2)              AS total_revenue_aed,
    ROUND(SUM(gross_profit_aed), 2)         AS total_profit_aed,
    ROUND(SUM(gross_profit_aed) * 100.0
          / SUM(revenue_aed), 1)            AS gross_margin_pct,
    ROUND(AVG(unit_price_aed), 2)           AS avg_unit_price_aed
FROM sales
GROUP BY product, category
ORDER BY total_revenue_aed DESC
LIMIT 10;


-- ============================================================
-- 5. CATEGORY PERFORMANCE
-- Revenue and margin by product category
-- ============================================================
SELECT
    category,
    COUNT(DISTINCT order_id)                AS total_orders,
    SUM(quantity)                           AS total_units_sold,
    ROUND(SUM(revenue_aed), 2)              AS total_revenue_aed,
    ROUND(SUM(gross_profit_aed), 2)         AS total_profit_aed,
    ROUND(SUM(gross_profit_aed) * 100.0
          / SUM(revenue_aed), 1)            AS gross_margin_pct,
    ROUND(SUM(revenue_aed) * 100.0
          / (SELECT SUM(revenue_aed) FROM sales), 1) AS revenue_share_pct
FROM sales
GROUP BY category
ORDER BY total_revenue_aed DESC;


-- ============================================================
-- 6. DISTRIBUTOR PERFORMANCE
-- Ranking distributors by revenue and target achievement
-- ============================================================
SELECT
    distributor,
    COUNT(DISTINCT order_id)                AS total_orders,
    ROUND(SUM(revenue_aed), 2)              AS total_revenue_aed,
    ROUND(SUM(sales_target_aed), 2)         AS total_target_aed,
    ROUND(SUM(revenue_aed) * 100.0
          / SUM(sales_target_aed), 1)       AS target_achievement_pct,
    ROUND(SUM(gross_profit_aed), 2)         AS total_profit_aed,
    ROUND(AVG(target_achieved_pct), 1)      AS avg_target_achieved_pct,
    CASE
        WHEN SUM(revenue_aed) * 100.0 / SUM(sales_target_aed) >= 100 THEN 'On Target'
        WHEN SUM(revenue_aed) * 100.0 / SUM(sales_target_aed) >= 85  THEN 'Near Target'
        ELSE 'Below Target'
    END AS performance_status
FROM sales
GROUP BY distributor
ORDER BY total_revenue_aed DESC;


-- ============================================================
-- 7. SALES REP LEADERBOARD
-- Individual rep performance with ranking
-- ============================================================
SELECT
    RANK() OVER (ORDER BY SUM(revenue_aed) DESC) AS rank,
    sales_rep,
    COUNT(DISTINCT order_id)                AS total_orders,
    ROUND(SUM(revenue_aed), 2)              AS total_revenue_aed,
    ROUND(SUM(gross_profit_aed), 2)         AS total_profit_aed,
    ROUND(AVG(target_achieved_pct), 1)      AS avg_target_pct,
    ROUND(SUM(revenue_aed) / COUNT(DISTINCT order_id), 2) AS revenue_per_order
FROM sales
GROUP BY sales_rep
ORDER BY rank;


-- ============================================================
-- 8. CHANNEL ANALYSIS
-- Which sales channel drives the most revenue
-- ============================================================
SELECT
    channel,
    COUNT(DISTINCT order_id)                AS total_orders,
    ROUND(SUM(revenue_aed), 2)              AS total_revenue_aed,
    ROUND(AVG(revenue_aed), 2)              AS avg_order_value_aed,
    ROUND(SUM(gross_profit_aed) * 100.0
          / SUM(revenue_aed), 1)            AS gross_margin_pct,
    ROUND(SUM(revenue_aed) * 100.0
          / (SELECT SUM(revenue_aed) FROM sales), 1) AS revenue_share_pct
FROM sales
GROUP BY channel
ORDER BY total_revenue_aed DESC;


-- ============================================================
-- 9. SLOW-MOVING SKUs (Analyst Insight)
-- Products with low volume AND low margin — review or discontinue
-- ============================================================
SELECT
    product,
    category,
    SUM(quantity)                           AS total_units_sold,
    ROUND(SUM(revenue_aed), 2)              AS total_revenue_aed,
    ROUND(SUM(gross_profit_aed) * 100.0
          / SUM(revenue_aed), 1)            AS gross_margin_pct
FROM sales
GROUP BY product, category
HAVING SUM(quantity) < 1500
   AND SUM(gross_profit_aed) * 100.0 / SUM(revenue_aed) < 30
ORDER BY total_units_sold ASC;


-- ============================================================
-- 10. YEAR-OVER-YEAR COMPARISON (2023 vs 2024)
-- Growth by category across both years
-- ============================================================
SELECT
    category,
    ROUND(SUM(CASE WHEN year = 2023 THEN revenue_aed ELSE 0 END), 2) AS revenue_2023,
    ROUND(SUM(CASE WHEN year = 2024 THEN revenue_aed ELSE 0 END), 2) AS revenue_2024,
    ROUND(
        (SUM(CASE WHEN year = 2024 THEN revenue_aed ELSE 0 END)
       - SUM(CASE WHEN year = 2023 THEN revenue_aed ELSE 0 END)) * 100.0
        / NULLIF(SUM(CASE WHEN year = 2023 THEN revenue_aed ELSE 0 END), 0), 1
    ) AS yoy_growth_pct
FROM sales
GROUP BY category
ORDER BY yoy_growth_pct DESC;
