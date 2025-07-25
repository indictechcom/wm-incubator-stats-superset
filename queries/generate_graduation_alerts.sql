WITH monthly_user_edits AS (
    SELECT
        DATE_FORMAT(STR_TO_DATE(rev.rev_timestamp, '%Y%m%d%H%i%S'), '%Y-%m') AS edit_month,
        rev.rev_actor AS actor_id,
        COUNT(*) AS edit_count
    FROM revision AS rev
    WHERE rev.rev_timestamp >= DATE_FORMAT(DATE_SUB(NOW(), INTERVAL 4 MONTH), '%Y%m%d%H%i%S')
    GROUP BY edit_month, actor_id
    HAVING edit_count >= 15
)

SELECT
    actor.actor_name AS username,
    mue.edit_month,
    mue.edit_count
FROM monthly_user_edits AS mue
JOIN actor ON mue.actor_id = actor.actor_id
ORDER BY mue.edit_month DESC, mue.edit_count DESC;
