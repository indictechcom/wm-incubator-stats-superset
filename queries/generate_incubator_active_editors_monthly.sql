WITH base AS (
    SELECT
        rev.rev_id,
        rev.rev_timestamp,
        REGEXP_SUBSTR(page.page_title, 'W[a-z]') AS project_code,
        SUBSTRING_INDEX(REGEXP_SUBSTR(page.page_title, 'W[a-z]/[a-z]+'), '/', -1) AS language_code,
        actor.actor_id
    FROM revision AS rev
    INNER JOIN page   ON rev.rev_page   = page.page_id
    INNER JOIN actor  ON rev.rev_actor  = actor.actor_id
    INNER JOIN user   ON actor.actor_name = user.user_name
    WHERE page.page_namespace   IN (0,1,10,11,14,15,828,829)
      AND page.page_is_redirect  = 0
      AND user.user_name NOT IN {EXCL_USERS}
      AND NOT (
          user.user_name LIKE '%bot%'
          AND user.user_name LIKE '%Bot%'
      )
      AND REGEXP_SUBSTR(page.page_title,'W[a-z]/[a-z]+') NOT IN {EXCL_PREFIXES}
),

monthly_edits AS (
    SELECT
        DATE_FORMAT(rev_timestamp, '%Y-%m-01') AS month_start,
        project_code,
        language_code,
        actor_id,
        COUNT(DISTINCT rev_id) AS edits_in_month
    FROM base
    GROUP BY month_start, project_code, language_code, actor_id
),

monthly_active AS (
    SELECT
        month_start,
        project_code,
        language_code,
        SUM(CASE WHEN edits_in_month >= 5  THEN 1 ELSE 0 END) AS monthly_active_editors_min5,
        SUM(CASE WHEN edits_in_month >= 15 THEN 1 ELSE 0 END) AS monthly_active_editors_min15
    FROM monthly_edits
    GROUP BY month_start, project_code, language_code
)

SELECT
    month_start,
    CASE project_code
      WHEN 'Wp' THEN 'wikipedia'
      WHEN 'Wq' THEN 'wikiquote'
      WHEN 'Wt' THEN 'wiktionary'
      WHEN 'Wy' THEN 'wikivoyage'
      WHEN 'Wb' THEN 'wikibooks'
      WHEN 'Wn' THEN 'wikinews'
      ELSE 'unknown'
    END AS project,
    language_code,
    monthly_active_editors_min5,
    monthly_active_editors_min15
FROM monthly_active
ORDER BY month_start;
