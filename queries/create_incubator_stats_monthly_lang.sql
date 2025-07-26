CREATE TABLE IF NOT EXISTS incubator_stats_monthly_lang (
    year                INT                COMMENT 'Calendar year of the stats',
    month               INT                COMMENT 'Calendar month (1–12) of the stats',
    language_code       VARCHAR(10)        COMMENT 'Language code (e.g. en, fr, etc.)',
    monthly_active_editors_greatereq5 INT             COMMENT 'Distinct editors with ≥5 edits in that month',
    monthly_active_editors_greatereq15 INT             COMMENT 'Distinct editors with ≥15 edits in that month',
)
ENGINE=InnoDB
COMMENT='All‑time monthly editor stats by language (one row per year+month+language)';