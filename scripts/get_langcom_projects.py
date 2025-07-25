import requests
import json

# 1. Fetch the live sitematrix JSON from the Wikimedia API
url = "https://meta.wikimedia.org/w/api.php?action=sitematrix&format=json"
response = requests.get(url)
response.raise_for_status()
sitematrix = response.json()["sitematrix"]

# 2. Extract every 'dbname', preserving order, but only keep unique values
dbnames = []
for key, block in sitematrix.items():
    if key.isdigit():
        for site in block.get("site", []):
            dbnames.append(site["dbname"])
    elif key == "specials":
        for site in block:
            dbnames.append(site["dbname"])

# Remove duplicates while preserving original order
unique_dbnames = list(dict.fromkeys(dbnames))

# Wrap each unique dbname in a dict
output = [{"dbname": db} for db in unique_dbnames]

# 3. Write the result to a JSON file
with open("dbnames.json", "w", encoding="utf-8") as f:
    json.dump(output, f, ensure_ascii=False, indent=2)

print(f"Saved {len(output)} unique dbnames to dbnames.json")
