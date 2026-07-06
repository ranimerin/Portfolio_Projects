
use TestDB
SELECT * FROM churn;


-- ── 1. OVERVIEW: Churn Summary ──────────────────────────────
-- Business Question: What is our overall churn rate?

SELECT
    COUNT(Customer_ID)                              AS total_customers,
    SUM(Churned)                                    AS churned_customers,
    COUNT(Customer_ID) - SUM(Churned)               AS retained_customers,
    ROUND(SUM(Churned) * 100.0 / COUNT(*), 1)       AS churn_rate_pct,
    ROUND(SUM(CASE WHEN Churned=0 THEN Monthly_Spend_AED END), 0)
                                                    AS retained_revenue_aed,
    ROUND(SUM(CASE WHEN Churned=1 THEN Monthly_Spend_AED END), 0)
                                                    AS revenue_at_risk_aed
FROM churn;


-- ── 2. CHURN RATE BY SEGMENT ────────────────────────────────
-- Business Question: Which customer segment is churning most?

SELECT
    Segment,
    COUNT(Customer_ID)                              AS total_customers,
    SUM(Churned)                                    AS churned,
    ROUND(SUM(Churned) * 100.0 / COUNT(*), 1)       AS churn_rate_pct,
    ROUND(SUM(CASE WHEN Churned=1
               THEN Monthly_Spend_AED END), 0)      AS revenue_at_risk_aed
FROM churn
GROUP BY Segment
ORDER BY churn_rate_pct DESC;


-- ── 3. CHURN RATE BY INDUSTRY ───────────────────────────────
-- Business Question: Which industries are hardest to retain?

SELECT
    Industry,
    COUNT(Customer_ID)                              AS total_customers,
    SUM(Churned)                                    AS churned,
    ROUND(SUM(Churned) * 100.0 / COUNT(*), 1)       AS churn_rate_pct,
    ROUND(AVG(Monthly_Spend_AED), 0)                AS avg_monthly_spend
FROM churn
GROUP BY Industry
ORDER BY churn_rate_pct DESC;


-- ── 4. CHURN RATE BY REGION ─────────────────────────────────
-- Business Question: Which GCC city has the highest churn?

SELECT
    Region,
    COUNT(Customer_ID)                              AS total_customers,
    SUM(Churned)                                    AS churned,
    ROUND(SUM(Churned) * 100.0 / COUNT(*), 1)       AS churn_rate_pct,
    ROUND(SUM(CASE WHEN Churned=1
               THEN Monthly_Spend_AED END), 0)      AS revenue_at_risk_aed
FROM churn
GROUP BY Region
ORDER BY churn_rate_pct DESC;


-- ── 5. SUPPORT TICKETS vs CHURN ─────────────────────────────
-- Business Question: Does raising more support tickets predict churn?
-- Insight: Customers with 5+ tickets are high churn risk

SELECT
    Support_Tickets,
    COUNT(Customer_ID)                              AS total_customers,
    SUM(Churned)                                    AS churned,
    ROUND(SUM(Churned) * 100.0 / COUNT(*), 1)       AS churn_rate_pct,
    CASE
        WHEN Support_Tickets >= 5 THEN 'High Risk'
        WHEN Support_Tickets >= 3 THEN 'Medium Risk'
        ELSE 'Low Risk'
    END                                             AS risk_flag
FROM churn
GROUP BY Support_Tickets
ORDER BY Support_Tickets;


-- ── 6. INACTIVITY ANALYSIS ──────────────────────────────────
-- Business Question: How does days since last order relate to churn?

WITH inactivity AS (
    SELECT *,
        CASE
            WHEN Last_Order_Days_Ago <= 30  THEN '0-30 days'
            WHEN Last_Order_Days_Ago <= 60  THEN '31-60 days'
            WHEN Last_Order_Days_Ago <= 90  THEN '61-90 days'
            WHEN Last_Order_Days_Ago <= 120 THEN '91-120 days'
            ELSE '120+ days'
        END AS inactivity_band
    FROM churn
)
SELECT
    inactivity_band,
    COUNT(Customer_ID)                        AS total_customers,
    SUM(Churned)                              AS churned,
    ROUND(SUM(Churned) * 100.0 / COUNT(*), 1) AS churn_rate_pct
FROM inactivity
GROUP BY inactivity_band
ORDER BY MIN(Last_Order_Days_Ago);


-- ── 7. PAYMENT DELAY vs CHURN ───────────────────────────────
-- Business Question: Are customers who delay payments more likely to churn?

SELECT
    Payment_Delays,
    COUNT(Customer_ID)                              AS total_customers,
    SUM(Churned)                                    AS churned,
    ROUND(SUM(Churned) * 100.0 / COUNT(*), 1)       AS churn_rate_pct,
    CASE
        WHEN Payment_Delays >= 4 THEN 'Critical — Intervene Now'
        WHEN Payment_Delays >= 2 THEN 'Watch Closely'
        ELSE 'Normal'
    END                                             AS action_flag
FROM churn
GROUP BY Payment_Delays
ORDER BY Payment_Delays;


-- ── 8. TENURE vs CHURN ──────────────────────────────────────
-- Business Question: Do newer customers churn faster?
WITH tenure AS (
SELECT *,
    CASE
        WHEN Tenure_Months <= 6  THEN '0-6 months (New)'
        WHEN Tenure_Months <= 12 THEN '7-12 months'
        WHEN Tenure_Months <= 24 THEN '13-24 months'
        ELSE '24+ months (Loyal)'
    END                                             AS tenure_band
    FROM Churn 

    )
    SELECT tenure_band,
    COUNT(Customer_ID)                              AS total_customers,
    SUM(Churned)                                    AS churned,
    ROUND(SUM(Churned) * 100.0 / COUNT(*), 1)       AS churn_rate_pct,
    ROUND(AVG(Monthly_Spend_AED), 0)                AS avg_spend_aed
FROM tenure
GROUP BY tenure_band
ORDER BY MIN(Tenure_Months);


-- ── 9. HIGH VALUE CUSTOMERS AT RISK ─────────────────────────
-- Business Question: Which high-spending customers are about to churn?
-- These are the most urgent customers to save!

SELECT TOP 10
    Customer_ID,
    Segment,
    Region,
    Industry,
    ROUND(Monthly_Spend_AED, 0)                     AS monthly_spend_aed,
    Tenure_Months,
    Last_Order_Days_Ago,
    Support_Tickets,
    Payment_Delays,
    Churned,
    CASE
        WHEN Last_Order_Days_Ago > 90
         AND Support_Tickets >= 5  THEN 'CRITICAL'
        WHEN Last_Order_Days_Ago > 60
          OR Support_Tickets >= 4  THEN 'HIGH RISK'
        ELSE 'MONITOR'
    END                                             AS risk_level
FROM churn
WHERE Churned = 0
  AND Monthly_Spend_AED > 8000
  AND (Last_Order_Days_Ago > 60 OR Support_Tickets >= 3)
ORDER BY Monthly_Spend_AED DESC



-- ── 10. CHURN PREVENTION PRIORITY LIST ──────────────────────
-- Business Question: Which active customers should we call first?

WITH scored AS (
    SELECT
        Customer_ID,
        Segment,
        Region,
        ROUND(Monthly_Spend_AED, 0)          AS monthly_spend_aed,
        Last_Order_Days_Ago,
        Support_Tickets,
        Payment_Delays,
        (
            CASE WHEN Last_Order_Days_Ago > 90 THEN 3
                 WHEN Last_Order_Days_Ago > 60 THEN 2
                 WHEN Last_Order_Days_Ago > 30 THEN 1
                 ELSE 0 END
          + CASE WHEN Support_Tickets >= 5 THEN 2
                 WHEN Support_Tickets >= 3 THEN 1
                 ELSE 0 END
          + CASE WHEN Payment_Delays >= 4 THEN 2
                 WHEN Payment_Delays >= 2 THEN 1
                 ELSE 0 END
        )                                    AS churn_risk_score
    FROM churn
    WHERE Churned = 0
)
SELECT TOP 10
    Customer_ID,
    Segment,
    Region,
    monthly_spend_aed,
    Last_Order_Days_Ago,
    Support_Tickets,
    Payment_Delays,
    churn_risk_score,
    CASE
        WHEN churn_risk_score >= 5 THEN 'Call Today'
        WHEN churn_risk_score >= 3 THEN 'Follow Up This Week'
        ELSE 'Monitor'
    END                                      AS action
FROM scored
ORDER BY churn_risk_score DESC, monthly_spend_aed DESC;