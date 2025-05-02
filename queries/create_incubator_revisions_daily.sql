CREATE TABLE IF NOT EXISTS incubator_revisions_daily (
    snapshot_date DATE COMMENT 'Date on which the data was last updated on.',
    rev_id BIGINT COMMENT 'Revision ID.',
    rev_actor BIGINT COMMENT 'Actor ID associated with the revision.',
    rev_timestamp DATETIME COMMENT 'Timestamp of the revision.',
    rev_len INT COMMENT 'Length of the revision content.',
    rev_parent_id BIGINT COMMENT 'Revision ID of the parent revision.',
    page_namespace INT COMMENT 'Namespace of the page.',
    page_id BIGINT COMMENT 'Unique ID of the page.',
    actor_id BIGINT COMMENT 'ID of the actor who made the edit.',
    actor_name VARCHAR(255) COMMENT 'Name of the actor who made the edit.',
    byte_diff INT COMMENT 'Difference in bytes between new and old content.',
    prefix VARCHAR(50) COMMENT 'Language-prefixed project code extracted from page title (e.g., Wp/en).',
    project_code VARCHAR(10) COMMENT 'Short project code extracted from prefix (e.g., Wp).',
    is_last_3m BOOLEAN COMMENT 'Indicates if the revision is within the last 3 months.',
    project VARCHAR(50) COMMENT 'Expanded project name derived from project_code (e.g., wikipedia).'
)
ENGINE=InnoDB
COMMENT='Revision and page data joined with actor and recentchanges info, including project classification.'
;
