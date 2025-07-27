WITH last_4_months AS (
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
),
qualified_projects AS (
  SELECT
    project,
    language_code,
    COUNT(*) AS qualified_months
  FROM last_4_months
  GROUP BY project, language_code
  HAVING qualified_months = 4
),
last_month_editors AS (
  SELECT
    project,
    language_code,
    active_editors AS last_month_editors
  FROM last_4_months
  WHERE snapshot_month = DATE_FORMAT(DATE_SUB(CURDATE(), INTERVAL 1 MONTH), '%Y-%m-01')
)
SELECT 
  qp.project,
  qp.language_code,
  lme.last_month_editors
FROM qualified_projects qp
JOIN last_month_editors lme
  ON qp.project = lme.project AND qp.language_code = lme.language_code
ORDER BY qp.project, qp.language_code;
