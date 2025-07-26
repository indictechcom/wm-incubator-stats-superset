CREATE TABLE IF NOT EXISTS incubator_active_editors_monthly (
    snapshot_month DATE COMMENT 'First day of the month (YYYY-MM-01)',
    project VARCHAR(50) COMMENT 'Expanded project name (e.g., wikipedia).',
    language_code VARCHAR(10) COMMENT 'Language code (e.g. en, fr, etc.)',
    monthly_active_editors_min5 INT COMMENT 'Distinct editors with ≥5 edits in that month',
    monthly_active_editors_min15 INT COMMENT 'Distinct editors with ≥15 edits in that month'
)
ENGINE=InnoDB
COMMENT='All‑time monthly editor stats by language (one row per year+month+language)';
