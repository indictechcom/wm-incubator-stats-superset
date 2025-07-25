import os
import mysql.connector
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
import logging

# --- Configuration ---
# Database connection details (assuming environment variables for security)
DB_HOST = os.getenv('DB_HOST', 'localhost')
DB_USER = os.getenv('DB_USER', 'your_db_user')
DB_PASSWORD = os.getenv('DB_PASSWORD', 'your_db_password')
DB_NAME = os.getenv('DB_NAME', 'your_database_name') # !! IMPORTANT: Replace with your actual database name !!

# Sendinblue SMTP details (assuming environment variables for security)
# Check Sendinblue/Brevo documentation for correct host/port if these don't work
SMTP_HOST = os.getenv('SENDINBLUE_SMTP_HOST', 'smtp-relay.brevo.com') # Common Brevo SMTP host
SMTP_PORT = int(os.getenv('SENDINBLUE_SMTP_PORT', 587)) # Common SMTP ports: 587 (TLS), 465 (SSL)
SMTP_USERNAME = os.getenv('SENDINBLUE_SMTP_USERNAME', '9310b1001@smtp-brevo.com') # Often your Sendinblue login email
SMTP_PASSWORD = os.getenv('SENDINBLUE_SMTP_PASSWORD', 'rN3IH4XwzYm81GkF') # Your Sendinblue SMTP Key/Password

# Email details
SENDER_EMAIL = os.getenv('SENDER_EMAIL', 'incubator-alerts@wikimedia.org') # Use a more appropriate sender email
ALERT_RECIPIENTS_STR = os.getenv('ALERT_RECIPIENTS', 'bharathkrishna2006@gmail.com,langcom@lists.wikimedia.org')
ALERT_RECIPIENTS = [email.strip() for email in ALERT_RECIPIENTS_STR.split(',')]

# Path to the SQL query file
SQL_QUERY_FILE = os.path.join(os.path.dirname(__file__), '../queries/get_project_graduation_status.sql')

# --- Logging Setup ---
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

def get_db_connection():
    """Establishes and returns a database connection."""
    try:
        conn = mysql.connector.connect(
            host=DB_HOST,
            user=DB_USER,
            password=DB_PASSWORD,
            database=DB_NAME
        )
        logging.info("Successfully connected to the database.")
        return conn
    except mysql.connector.Error as err:
        logging.error(f"Error connecting to database: {err}")
        raise

def read_sql_query(file_path):
    """Reads SQL query from a file."""
    try:
        with open(file_path, 'r') as f:
            return f.read()
    except IOError as e:
        logging.error(f"Error reading SQL query file {file_path}: {e}")
        raise

def fetch_project_status(connection, query):
    """Executes the SQL query and fetches project status."""
    cursor = None
    try:
        cursor = connection.cursor(dictionary=True) # Return results as dictionaries
        cursor.execute(query)
        results = cursor.fetchall()
        logging.info(f"Fetched {len(results)} project status entries.")
        return results
    except mysql.connector.Error as err:
        logging.error(f"Error executing SQL query: {err}")
        raise
    finally:
        if cursor:
            cursor.close()

def send_alert_email(graduating_projects, all_project_statuses):
    """Constructs and sends the email alert."""
    if not ALERT_RECIPIENTS:
        logging.warning("No recipient emails configured. Skipping email sending.")
        return

    msg = MIMEMultipart('alternative')
    msg['From'] = SENDER_EMAIL
    msg['To'] = ", ".join(ALERT_RECIPIENTS)
    msg['Subject'] = "Incubator Project Graduation Alert"

    html_content = """
    <html>
    <head>
        <style>
            body {{ font-family: Arial, sans-serif; line-height: 1.6; }}
            h2 {{ color: #333; }}
            .section {{ margin-bottom: 20px; padding: 10px; border: 1px solid #eee; border-radius: 5px; }}
            .graduating {{ background-color: #e6ffe6; border-color: #4CAF50; }}
            .others {{ background-color: #f9f9f9; border-color: #ddd; }}
            table {{ width: 100%; border-collapse: collapse; margin-top: 10px; }}
            th, td {{ border: 1px solid #ddd; padding: 8px; text-align: left; }}
            th {{ background-color: #f2f2f2; }}
            .yes {{ color: green; font-weight: bold; }}
            .no {{ color: orange; }}
        </style>
    </head>
    <body>
        <h2>Incubator Project Graduation Status Report</h2>
    """

    if graduating_projects:
        html_content += """
        <div class="section graduating">
            <h3>&#127881; Projects Potentially Ready for Graduation! &#127881;</h3>
            <p>The following projects meet the criteria of at least 4 active users (or 3 with one dip) per month for 4 consecutive months:</p>
            <ul>
        """
        for p in graduating_projects:
            html_content += f"<li><strong>{p['Project']} ({p['language_code']})</strong> - Last 4 Months: {p['last_4_months_summary']}</li>"
        html_content += "</ul></div>"
    else:
        html_content += """
        <div class="section">
            <h3>No Projects Currently Ready for Graduation</h3>
            <p>No projects met the criteria of at least 4 active users per month for 4 consecutive months in the latest period.</p>
        </div>
        """

    html_content += """
        <div class="section others">
            <h3>Full Project Status Overview</h3>
            <table>
                <thead>
                    <tr>
                        <th>Graduation Ready?</th>
                        <th>Project</th>
                        <th>Language Code</th>
                        <th>Current Month Editors</th>
                        <th>Current Month Edits</th>
                        <th>Last 4 Months Summary</th>
                    </tr>
                </thead>
                <tbody>
    """
    for p in all_project_statuses:
        status_class = "yes" if p['is_ready_for_graduation'] == 'Yes' else "no"
        html_content += f"""
        <tr>
            <td class="{status_class}">{p['is_ready_for_graduation']}</td>
            <td>{p['Project']}</td>
            <td>{p['language_code']}</td>
            <td>{p['current_month_editors']}</td>
            <td>{p['current_month_edits']}</td>
            <td>{p['last_4_months_summary']}</td>
        </tr>
        """
    html_content += """
                </tbody>
            </table>
        </div>
        <p>This alert is generated monthly. Please review the statistics for further evaluation.</p>
    </body>
    </html>
    """

    msg.attach(MIMEText(html_content, 'html'))

    try:
        # Connect to Sendinblue SMTP server
        with smtplib.SMTP(SMTP_HOST, SMTP_PORT) as server:
            server.starttls() # Secure the connection
            server.login(SMTP_USERNAME, SMTP_PASSWORD)
            server.send_message(msg)
        logging.info(f"Email alert sent successfully to {', '.join(ALERT_RECIPIENTS)}")
    except Exception as e:
        logging.error(f"Failed to send email alert: {e}")

def main():
    """Main function to run the graduation check and send alerts."""
    conn = None
    try:
        conn = get_db_connection()
        sql_query = read_sql_query(SQL_QUERY_FILE)
        project_statuses = fetch_project_status(conn, sql_query)

        graduating_projects = [
            p for p in project_statuses if p['is_ready_for_graduation'] == 'Yes'
        ]

        send_alert_email(graduating_projects, project_statuses)

    except Exception as e:
        logging.critical(f"Script failed due to an unhandled error: {e}")
    finally:
        if conn:
            conn.close()
            logging.info("Database connection closed.")

if __name__ == "__main__":
    main()
    