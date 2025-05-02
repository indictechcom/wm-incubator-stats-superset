WITH base AS (
  SELECT DISTINCT 
    rev.rev_id, 
    rev.rev_actor, 
    rev.rev_timestamp, 
    rev.rev_len, 
    rev.rev_parent_id,
    page.page_namespace, 
    page.page_id,                                
    actor.actor_id,
    actor.actor_name,
   	rc.rc_new_len - rc.rc_old_len AS byte_diff,
  	-- prefixes
    REGEXP_SUBSTR(page.page_title, 'W[a-z]/[a-z]+') AS prefix,
    SUBSTRING_INDEX(REGEXP_SUBSTR(page.page_title, 'W[a-z]/[a-z]+'), '/', 1) AS project_code,
    -- considered recent
    (rev.rev_timestamp >= DATE_SUB(NOW(), INTERVAL 3 MONTH)) AS is_last_3m
  FROM 
    revision rev
  JOIN 
    page ON rev.rev_page = page.page_id
  JOIN 
    actor ON rev.rev_actor = actor.actor_id
  LEFT JOIN 
    recentchanges rc ON rev.rev_id = rc.rc_this_oldid
  WHERE 
    page.page_namespace IN (0, 1, 10, 11, 14, 15, 828, 829)
    AND page.page_is_redirect = 0
    AND REGEXP_SUBSTR(page.page_title, 'W[a-z]/[a-z]+') IS NOT NULL
    AND actor.actor_name NOT IN ('MF-Warburg', 'Jon Harald Søby', 'Minorax')
)

SELECT
  DATE(NOW()) AS snapshot_date,
  *,
  CASE 
    WHEN project_code = 'Wp' THEN 'wikipedia'
    WHEN project_code = 'Wq' THEN 'wikiquote'
    WHEN project_code = 'Wt' THEN 'wiktionary'
    WHEN project_code = 'Wy' THEN 'wikivoyage'
    WHEN project_code = 'Wb' THEN 'wikibooks'
    WHEN project_code = 'Wn' THEN 'wikinews'
    ELSE 'unknown'
  END AS project
FROM base
;