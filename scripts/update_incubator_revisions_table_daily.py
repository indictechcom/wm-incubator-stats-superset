import json
import os
import urllib.request
from datetime import date, datetime

import pandas as pd
import toolforge as forge

user_agent = forge.set_user_agent(
    tool="Wikimedia Incubator Superset Dashboard",
    email="kcvelaga@gmail.com",
)

with open("stats/logs.json", "r") as file:
    logs = json.load(file)


sql_query_url = (
    "https://raw.githubusercontent.com/indictechcom/wm-incubator-stats/main/query.sql"
)
with urllib.request.urlopen(sql_query_url) as response:
    query = response.read().decode()
