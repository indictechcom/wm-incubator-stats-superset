SELECT
  DATE_FORMAT(
    STR_TO_DATE(CONCAT(year,'-',LPAD(month,2,'0'),'-01'), '%Y-%m-%d'),
    '%m/%Y'
  )                                     AS month_year,
  language_code                         AS lang,
  monthly_active_editors_greatereq5     AS editors_gte_5,
  monthly_active_editors_greatereq15    AS editors_gte_15
FROM incubator_stats_monthly_lang
ORDER BY year, month;