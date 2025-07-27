
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
    try:
        query_url = "https://raw.githubusercontent.com/indictechcom/wm-incubator-stats-superset/refs/heads/main/queries/generate_graduation_alerts.sql"
        query = get_query(query_url)
        
        conn = forge.connect(dbname)
        with conn.cursor() as cur:
            cur.execute(query)
            result = cur.fetchall()
            df = pd.DataFrame(result, columns=[col[0] for col in cur.description])
        
        logging.info(f"Found {len(df)} potential graduation candidates")
        return df
        
    except Exception as e:
        logging.error(f"Failed to fetch graduation candidates: {e}")
        raise

def send_email(df):
    for _, row in df.iterrows():
        send_graduation_alert(
            project_type=row['project'],
            language_code=row['language_code'],
            active_users=row['active_editors'],
            consecutive_months_met_criteria='Yes',
            sender_email='tools.incubator-dashboard@toolforge.org',
            recipient_email='langcom@lists.wikimedia.org'
        )

def main():
    df = fetch_graduation_candidates("s56696__incubator_stats_daily_p")
    send_email(df)
    

if __name__ == "__main__":
    main()