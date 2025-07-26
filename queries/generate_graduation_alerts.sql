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
    COUNT(*) AS consecutive_months
  FROM consecutive_blocks
  GROUP BY project, language_code, group_id
)
SELECT DISTINCT project, language_code, consecutive_months
FROM grouped_consecutive
WHERE consecutive_months >= 4;