WITH base AS (
    SELECT DISTINCT
           rev.rev_id,
           rev.rev_actor,
           rev.rev_timestamp,
           DATE(rev.rev_timestamp) AS rev_date,
           rev.rev_len,
           rev.rev_parent_id,
           page.page_namespace,
           page.page_id,
           actor.actor_id,
           REGEXP_SUBSTR(page.page_title, 'W[a-z]/[a-z]+') AS prefix,
           rc.rc_new_len - rc.rc_old_len AS byte_diff
      FROM revision AS rev
     INNER JOIN page ON rev.rev_page = page.page_id
     INNER JOIN actor ON rev.rev_actor = actor.actor_id
     LEFT JOIN recentchanges AS rc ON rev.rev_id = rc.rc_this_oldid
     INNER JOIN user ON actor.actor_name = user.user_name
     WHERE page.page_namespace IN (0, 1, 10, 11, 14, 15, 828, 829)
       AND page.page_is_redirect = 0
       AND user.user_name NOT IN {EXCL_USERS}
       AND NOT (
           user.user_name LIKE '%bot%'
           AND user.user_name LIKE '%Bot%'
       )
     HAVING prefix <> ''
       AND prefix NOT IN {EXCL_PREFIXES}
),

daily_metrics AS (
    SELECT base.prefix,
           base.rev_date,
           COUNT(DISTINCT base.rev_id) AS rev_count,
           COUNT(DISTINCT base.actor_id) AS editor_count,
           COUNT(DISTINCT base.page_id) AS edited_page_count,
           COUNT(DISTINCT CASE WHEN base.rev_parent_id = 0 THEN base.rev_id ELSE NULL END) AS created_page_count,
           SUM(CASE WHEN byte_diff < 0 THEN byte_diff ELSE 0 END) AS bytes_removed_30d,
           SUM(CASE WHEN byte_diff >= 0 THEN byte_diff ELSE 0 END) AS bytes_added_30d
      FROM base
     GROUP BY base.prefix, base.rev_date
),

lang_code AS (
    SELECT REGEXP_SUBSTR(prefix, 'W[a-z]') AS project_code,
           SUBSTRING_INDEX(prefix, '/', -1) AS language_code,
           rev_date,
           rev_count,
           editor_count,
           edited_page_count,
           created_page_count,
           bytes_added_30d,
           bytes_removed_30d
      FROM daily_metrics
),

actor_monthly_edits AS (
    SELECT
        prefix,
        actor_id,
        DATE_FORMAT(rev_timestamp, '%Y-%m-01') AS month_start,
        COUNT(*) AS edits_in_month
      FROM base
     GROUP BY prefix, actor_id, month_start
    HAVING COUNT(*) >= 5
),

monthly_active AS (
    SELECT
        prefix,
        month_start,
        COUNT(*) AS active_editors
      FROM actor_monthly_edits
     GROUP BY prefix, month_start
),

avg_monthly_active AS (
    SELECT
        prefix,
        ROUND(AVG(active_editors), 1) AS avg_monthly_active_editors
      FROM monthly_active
     GROUP BY prefix
)

SELECT DATE(CURRENT_TIME()) AS snapshot_date,
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
       rev_date,
       rev_count,
       editor_count,
       edited_page_count,
       created_page_count,
       bytes_added_30d,
       bytes_removed_30d,
       COALESCE(a.avg_monthly_active_editors, 0.0) AS avg_monthly_active_editors
  FROM lang_code l
  LEFT JOIN avg_monthly_active a
    ON l.prefix = a.prefix;
