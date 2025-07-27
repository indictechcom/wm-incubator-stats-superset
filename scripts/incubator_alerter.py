# scripts/main.py

import os
import logging
import sys
from logging.handlers import RotatingFileHandler

# Get the absolute path of the directory containing the current script (main.py)
current_script_dir = os.path.dirname(os.path.abspath(__file__))

# Add this directory to sys.path so Python can find sibling modules
if current_script_dir not in sys.path:
    sys.path.insert(0, current_script_dir)

#  NEW IMPORT: Importing from db_connector instead of log_parser 
from db_connector import get_graduating_projects
from email_sender import send_graduation_alert

# Configuration 

RECIPIENT_EMAIL = "langcom@lists.wikimedia.org" 

SENDER_EMAIL = "incubator-dashboard.alerts@toolforge.org" 
# PRODUCTION LOGGING SETUP 
PROJECT_LOG_DIR = os.path.join(os.path.dirname(os.path.abspath(current_script_dir)), 'logs')
PROJECT_LOG_FILE = os.path.join(PROJECT_LOG_DIR, 'alerter_activity.log')

os.makedirs(PROJECT_LOG_DIR, exist_ok=True)

file_handler = RotatingFileHandler(
    PROJECT_LOG_FILE,
    maxBytes=10 * 1024 * 1024, 
    backupCount=5               
)
formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
file_handler.setFormatter(formatter)

logging.basicConfig(level=logging.INFO,
                    handlers=[
                        file_handler,
                        logging.StreamHandler(sys.stdout)
                    ])
logger = logging.getLogger(__name__)

#  End Production Logging Setup 


def main():
    """
    Main function to orchestrate the graduation alert system.
    1. Queries the database to find projects ready for graduation.
    2. Sends email alerts for each graduating project.
    """
    logger.info("Starting LangCom Graduation Alert System (Database Query Mode).")
    logger.info("Connecting to database for graduation data...")

    # Step 1: Get graduating projects from the database
    # db_connector.py handles loading DB credentials from environment variables internally
    graduating_projects = get_graduating_projects()

    if not graduating_projects:
        logger.info("No projects found ready for graduation from database. Exiting.")
        return

    logger.info(f"Found {len(graduating_projects)} project(s) ready for graduation.")

    # Step 2: Send email alerts for mostly
    for project in graduating_projects:
        # These keys now come directly from the SQL query results
        project_type = project['project_type']
        language_code = project['language_code']
        active_users = project['active_users'] # This maps to latest_active_editors from SQL
        edits = project['edits']             # This maps to latest_monthly_total_edits from SQL
        consecutive_months_met_criteria = project['consecutive_months_met_criteria'] # This maps to months_met_criteria_count from SQL

        logger.info(f"Attempting to send alert for: {project_type} ({language_code})")

        success = send_graduation_alert(
            project_type=project_type,
            language_code=language_code,
            active_users=active_users,
            edits=edits,
            consecutive_months_met_criteria=consecutive_months_met_criteria,
            recipient_email=RECIPIENT_EMAIL,
            sender_email=SENDER_EMAIL
        )

        if success:
            logger.info(f"Alert successfully sent for {project_type} ({language_code}).")
        else:
            logger.error(f"Failed to send alert for {project_type} ({language_code}).")

    logger.info("LangCom Graduation Alert System finished.")

if __name__ == "__main__":
    main()