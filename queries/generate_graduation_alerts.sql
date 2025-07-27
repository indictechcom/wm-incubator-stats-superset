WITH monthly_stats AS (
  SELECT
    DATE_TRUNC('month', month_start)::DATE AS month,
    project,
    language_code,
    monthly_active_editors_min15 AS active_editors
  FROM incubator_active_editors_monthly
),
qualified_months AS (
  SELECT
    project,
    language_code,
    month,
    ROW_NUMBER() OVER (PARTITION BY project, language_code ORDER BY month) AS rn,
    EXTRACT(YEAR FROM month) * 12 + EXTRACT(MONTH FROM month) AS month_number
  FROM monthly_stats
  WHERE active_editors >= 4
),
consecutive_blocks AS (
  SELECT
    project,
    language_code,
    month,
    month_number - rn AS group_id
  FROM qualified_months
),
grouped_consecutive AS (
  SELECT
    project,
    language_code,
    group_id,
    COUNT(*) AS consecutive_months
  FROM consecutive_blocks
  GROUP BY project, language_code, group_id
)
SELECT 
  gc.project, 
  gc.language_code, 
  gc.consecutive_months,
  MAX(ms.active_editors) AS active_editors
FROM grouped_consecutive gc
JOIN consecutive_blocks cb
  ON gc.project = cb.project 
  AND gc.language_code = cb.language_code 
  AND gc.group_id = cb.month_number - ROW_NUMBER() OVER (PARTITION BY cb.project, cb.language_code ORDER BY cb.month)
JOIN monthly_stats ms
  ON cb.project = ms.project 
  AND cb.language_code = ms.language_code 
  AND cb.month = ms.month
WHERE gc.consecutive_months >= 4
GROUP BY gc.project, gc.language_code, gc.consecutive_months;
