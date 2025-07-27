SELECT
    iam.project AS project_type,
    iam.language_code,
    -- Get the monthly_active_editors_min15 for the most recent month that met the criteria
    -- or the latest month if no month met the criteria in the window
    COALESCE(
        (SELECT monthly_active_editors_min15
         FROM incubator_active_editors_monthly
         WHERE project = iam.project AND language_code = iam.language_code
           AND snapshot_month = MAX(iam.snapshot_month) -- Get for the latest month in the window
        ), 0
    ) AS latest_active_editors,
    -- Count how many of the last 4 months met the criteria (>= 4 active editors)
    SUM(CASE WHEN iam.monthly_active_editors_min15 >= 4 THEN 1 ELSE 0 END) AS months_met_criteria_count,
    -- Get the total revisions for the most recent month in the window
    COALESCE(
        (SELECT SUM(daily.rev_count)
         FROM incubator_stats_daily daily
         WHERE daily.project = iam.project
           AND daily.language_code = iam.language_code
           AND daily.rev_date >= DATE_FORMAT(MAX(iam.snapshot_month), '%Y-%m-01')
           AND daily.rev_date < DATE_FORMAT(MAX(iam.snapshot_month) + INTERVAL 1 MONTH, '%Y-%m-01')
        ), 0
    ) AS latest_monthly_total_edits
FROM
    incubator_active_editors_monthly iam
WHERE
    -- Consider the last 4 full months relative to the current date
    iam.snapshot_month >= DATE_SUB(LAST_DAY(CURRENT_DATE) + INTERVAL 1 DAY, INTERVAL 4 MONTH)
    AND iam.snapshot_month <= LAST_DAY(CURRENT_DATE) + INTERVAL 1 DAY - INTERVAL 1 MONTH
GROUP BY
    iam.project,
    iam.language_code
HAVING
    -- At least 3 out of the last 4 months must meet the criteria (>= 4 active editors with >=15 edits)
    SUM(CASE WHEN iam.monthly_active_editors_min15 >= 4 THEN 1 ELSE 0 END) >= 3;