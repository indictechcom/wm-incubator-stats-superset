from datetime import datetime

import urllib.request

import pandas as pd
import toolforge as forge

from utils import (
    clear_destination_table,
    update_destination_table
)

user_agent = forge.set_user_agent(
    tool="Wikimedia Incubator Superset Dashboard",
    email="kcvelaga@gmail.com",
)
destination_table = "incubator_revisions_daily"

def get_query(url):
    with urllib.request.urlopen(url) as response:
        query = response.read().decode()
    return query

def fetch_data(query, db="incubatorwiki"):
    
    try:
        conn = forge.connect(db)
        with conn.cursor() as cur:
            cur.execute(query)
            result = cur.fetchall()

        df = pd.DataFrame(result)
        df["prefix"] = df["prefix"].apply(lambda x: x.decode("utf-8"))
    except:
        df = None
    
    return df

def main():

    query = get_query("https://raw.githubusercontent.com/indictechcom/wm-incubator-stats-superset/refs/heads/main/queries/query.sql")
    df = fetch_data(query)

    if df != None:

        con = forge.toolsdb("s56696__incubator_stats_superset_p")
        cur = con.cursor()
        try:
            clear_destination_table(destination_table, cur)
            update_destination_table(df, destination_table, cur)
            con.commit()
            print(f"incubator revisions daily table updateda at: {datetime.now()}.")
        except Exception as e:
            con.rollback()
            print(f"update failed due to: {e}")
        finally:
            cur.close()
            con.close()

if __name__ == "__main__":
    main()
    
