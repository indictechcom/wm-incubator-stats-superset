WITH base AS (
    SELECT DISTINCT
           rev.rev_id,
           rev.rev_actor,
           rev.rev_timestamp,
           DATE(rev.rev_timestamp) AS rev_date,
           REGEXP_SUBSTR(page.page_title, 'W[a-z]/[a-z]+') AS prefix,
           actor.actor_id
      FROM revision AS rev
     INNER JOIN page ON rev.rev_page = page.page_id
     INNER JOIN actor ON rev.rev_actor = actor.actor_id
     LEFT JOIN recentchanges AS rc ON rev.rev_id = rc.rc_this_oldid
     INNER JOIN user ON actor.actor_name = user.user_name
     WHERE page.page_namespace = 0
       AND page.page_is_redirect = 0
       AND user.user_name NOT LIKE '%bot%'
       AND user.user_name NOT LIKE '%Bot%'
       AND user.user_name NOT IN {EXCL_USERS}
),

user_monthly_edits AS (
    SELECT
        prefix,
        actor_id,
        DATE_FORMAT(rev_timestamp, '%Y-%m-01') AS month,
        COUNT(*) AS monthly_edits
    FROM base
    GROUP BY prefix, actor_id, month
),

active_user_months AS (
    SELECT *
    FROM user_monthly_edits
    WHERE monthly_edits >= 15
),

numbered_months AS (
    SELECT 
        prefix,
        actor_id,
        month,
        ROW_NUMBER() OVER (PARTITION BY prefix, actor_id ORDER BY month) AS rn
    FROM active_user_months
),

grouped_months AS (
    SELECT 
        prefix,
        actor_id,
        month,
        DATE_SUB(month, INTERVAL rn MONTH) AS month_group
    FROM numbered_months
),

four_month_streaks AS (
    SELECT prefix, actor_id, month_group
    FROM grouped_months
    GROUP BY prefix, actor_id, month_group
    HAVING COUNT(*) >= 4
),

qualified_prefixes AS (
    SELECT prefix
    FROM four_month_streaks
    GROUP BY prefix
    HAVING COUNT(DISTINCT actor_id) >= 4
)

SELECT * FROM qualified_prefixes;
