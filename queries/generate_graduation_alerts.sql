-- WITH monthly_user_edits AS (
--     SELECT
--         DATE_FORMAT(STR_TO_DATE(rev.rev_timestamp, '%Y%m%d%H%i%S'), '%Y-%m') AS edit_month,
--         rev.rev_actor AS actor_id,
--         COUNT(*) AS edit_count
--     FROM revision AS rev
--     WHERE rev.rev_timestamp >= DATE_FORMAT(DATE_SUB(NOW(), INTERVAL 4 MONTH), '%Y%m%d%H%i%S')
--     GROUP BY edit_month, actor_id
--     HAVING edit_count >= 15
-- )

-- SELECT
--     actor.actor_name AS username,
--     mue.edit_month,
--     mue.edit_count
-- FROM monthly_user_edits AS mue
-- JOIN actor ON mue.actor_id = actor.actor_id
-- ORDER BY mue.edit_month DESC, mue.edit_count DESC;

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
     WHERE page.page_namespace = 0
       AND page.page_is_redirect = 0
       AND user.user_name NOT IN {EXCL_USERS}
       AND NOT (
           user.user_name LIKE '%bot%'
           AND user.user_name LIKE '%Bot%'
       )
     HAVING prefix <> ''
       AND prefix NOT IN {EXCL_PREFIXES}
),
