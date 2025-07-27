
from datetime import datetime, timedelta
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from typing import List, Dict, Optional
import os
import logging
import pandas as pd
import toolforge as forge
import urllib.request
import json
from email_sender import send_graduation_alert

# Setup logging
log_dir = os.path.join(os.path.dirname(os.path.dirname(__file__)), 'logs')
os.makedirs(log_dir, exist_ok=True)
log_file = os.path.join(log_dir, 'graduation_alerts.log')

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    handlers=[
        logging.FileHandler(log_file),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

def get_query(url: str) -> str:
    """Fetch SQL query from URL."""
    try:
        if url.startswith("https://") or url.startswith("http://"):
            with urllib.request.urlopen(url) as response:
                return response.read().decode()
        else:
            with open(url, 'r') as f:
                return f.read()
    except Exception as e:
        logging.error(f"Failed to fetch query from {url}: {e}")
        raise

def fetch_graduation_candidates(dbname: str) -> pd.DataFrame:
    """Fetch projects that meet graduation criteria."""
    db_config = {
        'host': os.environ.get('DB_HOST'),
        'user': os.environ.get('DB_USER'),
        'password': os.environ.get('DB_PASSWORD'),
        'database': os.environ.get('DB_NAME'),
        'charset': 'utf8mb4',
        'cursorclass': pymysql.cursors.DictCursor # Returns rows as dictionarie
    }
    # Advanced environment variable check
    missing_keys = [key for key in ['host', 'user', 'password', 'database'] if not db_config[key]]
    if missing_keys:
        logger.error(f"Missing required DB config keys: {', '.join(missing_keys)}. Check environment variables.")
        return pd.DataFrame()  # Return empty DataFrame instead of []

    try:
        query_url = "https://raw.githubusercontent.com/indictechcom/wm-incubator-stats-superset/refs/heads/main/queries/generate_graduation_alerts.sql"
        query = get_query(query_url)

        logger.info(f"Connecting to Toolforge DB '{dbname}'")
        conn = forge.connect(dbname)
        logger.info("Database connection successful.")

        with conn.cursor() as cur:
            logger.info("Executing graduation logic query...")
            cur.execute(query)
            result = cur.fetchall()
            df = pd.DataFrame(result, columns=[col[0] for col in cur.description])

        logger.info(f"Query returned {len(df)} potential graduation candidates.")
        return df
    except Exception as e:
        logger.error(f"Failed to fetch graduation candidates: {e}")
        raise

def send_email(df: pd.DataFrame):
    for _, row in df.iterrows():
        send_graduation_alert(
            project_type=row['project'],
            language_code=row['language_code'],
            active_users=row['avg_active_editors'],
            sender_email='tools.incubator-dashboard@toolforge.org',
            recipient_email='langcom@lists.wikimedia.org'
        )

def main():
    logger.info("Starting graduation alert process...")
    df = fetch_graduation_candidates("s56696__incubator_stats_daily_p")
    if df.empty:
        logger.info("No graduation candidates found.")
    else:
        send_email(df)
        logger.info("Graduation alert emails sent.")
    

if __name__ == "__main__":
    main()