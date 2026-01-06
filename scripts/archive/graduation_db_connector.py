import pymysql
import logging
import os

# Configure logging for this 
logger = logging.getLogger(__name__)

# The SQL query to identify graduating projects using CTEs
GRADUATION_QUERY = """
WITH MonthlyCriteriaMet AS (
    SELECT
        iam.project,
        iam.language_code,
        iam.snapshot_month,
        iam.monthly_active_editors_min15,
        CASE WHEN iam.monthly_active_editors_min15 >= 4 THEN 1 ELSE 0 END AS met_criteria_this_month
    FROM
        incubator_active_editors_monthly iam
    WHERE
        iam.snapshot_month >= DATE_SUB(LAST_DAY(CURRENT_DATE) + INTERVAL 1 DAY, INTERVAL 4 MONTH)
        AND iam.snapshot_month <= LAST_DAY(CURRENT_DATE) + INTERVAL 1 DAY - INTERVAL 1 MONTH
),
ProjectSummary AS (
    SELECT
        m.project AS project_type,
        m.language_code,
        SUM(m.met_criteria_this_month) AS months_met_criteria_count,
        MAX(m.monthly_active_editors_min15) AS latest_active_editors,
        MAX(m.snapshot_month) AS latest_snapshot_month
    FROM
        MonthlyCriteriaMet m
    GROUP BY
        m.project,
        m.language_code
    HAVING
        SUM(m.met_criteria_this_month) >= 3
)
SELECT
    ps.project_type,
    ps.language_code,
    ps.latest_active_editors,
    ps.months_met_criteria_count,
    COALESCE(
        (SELECT SUM(daily.rev_count)
         FROM incubator_stats_daily daily
         WHERE daily.project = ps.project_type
           AND daily.language_code = ps.language_code
           AND daily.rev_date >= DATE_FORMAT(ps.latest_snapshot_month, '%Y-%m-01')
           AND daily.rev_date < DATE_FORMAT(ps.latest_snapshot_month + INTERVAL 1 MONTH, '%Y-%m-01')
        ), 0
    ) AS latest_monthly_total_edits
FROM
    ProjectSummary ps;
"""

def get_graduating_projects() -> list[dict]:
    """
    Connects to the MySQL database, executes the graduation logic query,
    and returns a list of projects ready for graduation.

    Database credentials are loaded from environment variables:
    DB_HOST, DB_USER, DB_PASSWORD, DB_NAME.

    Returns:
        list[dict]: A list of dictionaries, where each dictionary represents a
                    project ready for graduation. Each dictionary contains:
                    {'project_type': str, 'language_code': str,
                     'latest_active_editors': int, 'months_met_criteria_count': int,
                     'latest_monthly_total_edits': int}
                    Returns an empty list if connection or query fails.
    """
    db_config = {
        'host': os.environ.get('DB_HOST'),
        'user': os.environ.get('DB_USER'),
        'password': os.environ.get('DB_PASSWORD'),
        'database': os.environ.get('DB_NAME'),
        'charset': 'utf8mb4',
        'cursorclass': pymysql.cursors.DictCursor # Returns rows as dictionarie
    }

    # Basic check for essential config
    if not all(db_config[key] for key in ['host', 'user', 'password', 'database']):
        logger.error("Database environment variables (DB_HOST, DB_USER, DB_PASSWORD, DB_NAME) are not set.")
        return []

    graduating_projects = []
    connection = None
    try:
        logger.info(f"Attempting to connect to database at {db_config['host']}/{db_config['database']}")
        connection = pymysql.connect(**db_config)
        logger.info("Database connection successful.")

        with connection.cursor() as cursor:
            logger.info("Executing graduation logic query...")
            cursor.execute(GRADUATION_QUERY)
            results = cursor.fetchall()
            logger.info(f"Query returned {len(results)} potential graduating projects.")

            for row in results:
                graduating_projects.append({
                    'project_type': row['project_type'],
                    'language_code': row['language_code'],
                    'active_users': row['latest_active_editors'], # Map to active_users for email_sender
                    'edits': row['latest_monthly_total_edits'],   # Map to edits for email_sender
                    'consecutive_months_met_criteria': row['months_met_criteria_count'] # Map for email_sender
                })

    except pymysql.Error as e:
        logger.error(f"Database error: {e}")
    except Exception as e:
        logger.error(f"An unexpected error occurred during database operation: {e}")
    finally:
        if connection:
            connection.close()
            logger.info("Database connection closed.")
    
    if not graduating_projects:
        logger.info("No projects found ready to graduate from database query.")

    return graduating_projects
