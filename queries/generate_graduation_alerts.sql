WITH
  monthly_user_edits AS (
    SELECT
      DATE_FORMAT(
        STR_TO_DATE(rev_timestamp, '%Y%m%d%H%i%S'),
        '%Y-%m'
      )             AS ym,
      rev_actor     AS actor_id,
      COUNT(*)      AS edits
    FROM revision
    GROUP BY ym, actor_id
    HAVING edits >= 15
  ),

  monthly_active_users AS (
    SELECT
      ym,
      COUNT(*)      AS active_users
    FROM monthly_user_edits
    GROUP BY ym
  ),

  filtered_months AS (
    SELECT
      ym,
      active_users,
      ROW_NUMBER() OVER (ORDER BY ym)
        - ROW_NUMBER() OVER (
            PARTITION BY (active_users >= 4)
            ORDER BY ym
          )         AS grp
    FROM monthly_active_users
    WHERE active_users >= 4
  ),

  consecutive_runs AS (
    SELECT
      COUNT(*)      AS run_length
    FROM filtered_months
    GROUP BY grp
    HAVING run_length >= 4
  )

SELECT
  EXISTS(SELECT 1 FROM consecutive_runs) AS meets_threshold;