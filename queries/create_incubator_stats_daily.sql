CREATE TABLE IF NOT EXISTS incubator_stats_daily (
    snapshot_date DATE COMMENT 'Date on which the snapshot was generated on.',
    project VARCHAR(50) COMMENT 'Expanded project name (e.g., wikipedia).',
    language_code VARCHAR(10) COMMENT 'Language code extracted from the prefix (e.g., en, fr, etc.).',
    rev_date DATE COMMENT 'Date of the revision.',
    rev_count INT COMMENT 'Total number of revisions on that day for the language/project.',
    editor_count INT COMMENT 'Number of active editors (with >5 edits) who made edits that day.',
    edited_page_count INT COMMENT 'Number of distinct pages edited that day.',
    created_page_count INT COMMENT 'Number of pages created that day (identified by rev_parent_id = 0).',
    bytes_added_30d BIGINT COMMENT 'Sum of bytes added across all edits for the day.',
    bytes_removed_30d BIGINT COMMENT 'Sum of bytes removed across all edits for the day.',
    avg_monthly_active_editors DECIMAL(5,1) COMMENT 'Average number of active editors per month for the project.',
)
ENGINE=InnoDB
COMMENT='Daily stats of incubating projects on Wikimedia incubator.';

