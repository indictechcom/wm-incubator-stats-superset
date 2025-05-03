from datetime import datetime
import urllib.request
import json
import pandas as pd
import toolforge as forge

import os
import logging

from utils import (
    clear_destination_table,
    update_destination_table,
    sql_tuple
)

log_dir = os.path.join(os.path.dirname(os.path.dirname(__file__)), 'logs')
os.makedirs(log_dir, exist_ok=True)

log_file = os.path.join(log_dir, 'incubator_stats_daily.log')

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    handlers=[
        logging.FileHandler(log_file),
        logging.StreamHandler()
    ]
)

user_agent = forge.set_user_agent(
    tool="Wikimedia Incubator Superset Dashboard",
    email="kcvelaga@gmail.com",
)
destination_table = "incubator_stats_daily"

with open('../project_map.json', 'r', encoding='utf-8') as f:
    project_map = json.load(f)

project_map_r = {v: k for k, v in project_map.items()}

with open('../exclude_users.json', 'r', encoding='utf-8') as f:
    exclude_users = json.load(f)

def construct_prefix(lang_code, db_group):
    project_code = project_map_r[db_group]
    return f'{project_code}/{lang_code}'


def get_query(url):
    with urllib.request.urlopen(url) as response:
        return response.read().decode()


def get_canonical_data(db_groups_inscope):
    cd_wikis = (
        pd.read_csv("https://gitlab.wikimedia.org/repos/movement-insights/canonical-data/-/raw/main/wiki/wikis.tsv", sep='\t')
        .query("""
            (visibility == 'public') \
            & (editability == 'public') \
            & (status == 'open') \
            & (database_group == @db_groups_inscope)
        """)
    )
    return cd_wikis


def fetch_data(query, db="incubatorwiki"):
    conn = forge.connect(db)
    with conn.cursor() as cur:
        cur.execute(query)
        result = cur.fetchall()
        df = pd.DataFrame(result, columns=[col[0] for col in cur.description])
    return df


def main():
    logging.info(f"Update process started at {datetime.now()}.")

    db_groups_inscope = list(project_map.values())
    cdw = get_canonical_data(db_groups_inscope)
    cdw['prefix'] = cdw.apply(
        lambda row: construct_prefix(row['language_code'], row['database_group']), axis=1
    )
    excl_prefixes_sql = sql_tuple(cdw['prefix'].tolist())
    excl_user_sql = sql_tuple(exclude_users['exclude'])

    try:
        query = get_query("https://raw.githubusercontent.com/indictechcom/wm-incubator-stats-superset/refs/heads/main/queries/generate_incubator_stats_daily.sql")
        logging.info("Query fetched successfully.")
    except Exception as e:
        logging.error(f"Query fetch failed: {e}")
        return

    try:
        df = fetch_data(query.format(
            EXCL_PREFIXES=excl_prefixes_sql,
            EXCL_USERS=excl_user_sql
        ))
        logging.info(f"Data fetched successfully at {datetime.now()}.")
    except Exception as e:
        logging.error(f"Data fetch failed: {e}")
        return

    if df is not None:
        con = forge.toolsdb("s56696__incubator_stats_daily_p")
        cur = con.cursor()
        try:
            clear_destination_table(destination_table, cur)
            update_destination_table(df, destination_table, cur)
            con.commit()
            logging.info(f"Table '{destination_table}' updated successfully at {datetime.now()}.")
        except Exception as e:
            con.rollback()
            logging.error(f"Update failed: {e}")
        finally:
            cur.close()
            con.close()

    logging.info(f"Update process finished at {datetime.now()}.")


if __name__ == "__main__":
    main()
