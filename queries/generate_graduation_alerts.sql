WITH filtered_4_months AS (
  SELECT
    project,
    language_code,
    snapshot_month,
    monthly_active_editors_min15 AS active_editors
  FROM incubator_active_editors_monthly
  WHERE monthly_active_editors_min15 >= 4
  AND snapshot_month IN (
    DATE_FORMAT(DATE_SUB(CURDATE(), INTERVAL 1 MONTH), '%Y-%m-01'),
    DATE_FORMAT(DATE_SUB(CURDATE(), INTERVAL 2 MONTH), '%Y-%m-01'),
    DATE_FORMAT(DATE_SUB(CURDATE(), INTERVAL 3 MONTH), '%Y-%m-01'),
    DATE_FORMAT(DATE_SUB(CURDATE(), INTERVAL 4 MONTH), '%Y-%m-01')
  )
)
SELECT
  project,
  language_code,
  ROUND(AVG(active_editors), 0) AS avg_active_editors
FROM filtered_4_months
GROUP BY project, language_code
HAVING COUNT(*) = 4
ORDER BY project, language_code;
