-- Create Table 
CREATE OR REPLACE TABLE `sql82017.sales.sales_2025` AS
SELECT * FROM `sql82017.sales.sales202501`
UNION ALL SELECT *FROM `sql82017.sales.sales202502`
UNION ALL SELECT *FROM `sql82017.sales.sales202503`
UNION ALL SELECT *FROM `sql82017.sales.sales202504`
UNION ALL SELECT *FROM `sql82017.sales.sales202505`
UNION ALL SELECT *FROM `sql82017.sales.sales202506`
UNION ALL SELECT *FROM `sql82017.sales.sales202507`
UNION ALL SELECT *FROM `sql82017.sales.sales202508`
UNION ALL SELECT *FROM `sql82017.sales.sales202509`
UNION ALL SELECT *FROM `sql82017.sales.sales202510`
UNION ALL SELECT *FROM `sql82017.sales.sales202511`
UNION ALL SELECT *FROM `sql82017.sales.sales202512`;

--STEP Calculate RFM
-- Combine views with CTEs

CREATE OR REPLACE VIEW `sql82017.sales.rfm_metrics`
AS
WITH current_date AS (SELECT DATE('2026-03-06')AS analytics_date),
rfm AS (
  SELECT 
  CustomerID,
  MAX(OrderDate) AS last_order_date,
  date_diff((select analytics_date FROM current_date),MAX(OrderDate),DAY) AS recency,
  count(*) AS frequency,
  sum(OrderValue) AS monetary
  FROM `sql82017.sales.sales_2025`
  GROUP BY CustomerID
)

SELECT
rfm.*,
ROW_NUMBER() OVER (ORDER BY recency ASC) AS r_rank,
ROW_NUMBER() OVER (ORDER BY frequency desc) AS f_rank,
ROW_NUMBER() OVER (ORDER BY monetary desc) AS m_rank
FROM rfm;


--Step Assign deciles (10 = best, 1 = worst)


CREATE OR REPLACE VIEW `sql82017.sales.rfm_scores` AS
SELECT 
  *,
  NTILE(10) OVER (order by r_rank DESC) AS r_score,
  NTILE(10) OVER (order by r_rank DESC) AS f_score,
  NTILE(10) OVER (order by r_rank DESC) AS m_score,

FROM `sql82017.sales.rfm_metrics`;

--STEP 4: Total scores

CREATE OR REPLACE VIEW `sql82017.sales.total_scores` AS
SELECT 
  CustomerID,
  recency,
  frequency,
  monetary,
  r_score,
  f_score,
  m_score,
  (r_score+f_score+m_score) as rfm_total_score
From `sql82017.sales.rfm_scores`
order by rfm_total_score DESC;


--STEP 5: Total scores

CREATE OR REPLACE VIEW `sql82017.sales.rfm_segments_final` AS
SELECT 
  CustomerID,
  recency,
  frequency,
  monetary,
  r_score,
  f_score,
  m_score,
  rfm_total_score,
  CASE
    WHEN rfm_total_score >= 28 THEN 'Champion' 
    WHEN rfm_total_score >= 24 THEN 'Loyal VIPs' 
    WHEN rfm_total_score >= 20 THEN 'Potential Loyalist'
    WHEN rfm_total_score >= 16 THEN 'Promising'
    WHEN rfm_total_score >= 12 THEN 'Engaged'
    WHEN rfm_total_score >= 8 THEN 'Requires Attention'
    WHEN rfm_total_score >= 4 THEN 'At Risk'
    ELSE 'Lost/Inactive'
  END AS rfm_segment
FROM `sql82017.sales.total_scores`;

























