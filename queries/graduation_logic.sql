WITH MonthlyCriteriaMet AS (
    SELECT
        iam.project,
        iam.language_code,
        iam.snapshot_month,
        iam.monthly_active_editors_min15,
        -- Determine if the criteria (>= 4 active editors with >=15 edits) was met for this month
        CASE WHEN iam.monthly_active_editors_min15 >= 4 THEN 1 ELSE 0 END AS met_criteria_this_month
    FROM
        incubator_active_editors_monthly iam
    WHERE
        -- Filter for the last 4 full months relative to the current date
        iam.snapshot_month >= DATE_SUB(LAST_DAY(CURRENT_DATE) + INTERVAL 1 DAY, INTERVAL 4 MONTH)
        AND iam.snapshot_month <= LAST_DAY(CURRENT_DATE) + INTERVAL 1 DAY - INTERVAL 1 MONTH
),
ProjectSummary AS (
    SELECT
        m.project AS project_type,
        m.language_code,
        -- Count how many of the last 4 months met the criteria
        SUM(m.met_criteria_this_month) AS consecutive_months_met_criteria_count, -- Renamed for clarity
        -- Get the latest recorded active editors within this 4-month window
        MAX(m.monthly_active_editors_min15) AS latest_active_editors,
        -- Get the most recent snapshot_month in the window for this project
        MAX(m.snapshot_month) AS latest_snapshot_month
    FROM
        MonthlyCriteriaMet m
    GROUP BY
        m.project,
        m.language_code
    HAVING
        -- At least 3 out of the last 4 months must have met the criteria
        SUM(m.met_criteria_this_month) >= 3
)
SELECT
    ps.project_type,
    ps.language_code,
    ps.latest_active_editors,
    ps.consecutive_months_met_criteria_count,
    -- Get the total revisions for the most recent month identified in the window
    COALESCE(
        (SELECT SUM(daily.rev_count)
         FROM incubator_stats_daily daily
         WHERE daily.project = ps.project_type
           AND daily.language_code = ps.language_code
           AND daily.rev_date >= DATE_FORMAT(ps.latest_snapshot_month, '%Y-%m-01')
           AND daily.rev_date < DATE_FORMAT(ps.latest_snapshot_month + INTERVAL 1 MONTH, '%Y-%m-01')
        ), 0
    ) AS latest_monthly_total_edits
FROM
    ProjectSummary ps;