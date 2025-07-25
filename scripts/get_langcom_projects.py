import requests
import json

url = "https://meta.wikimedia.org/w/api.php?action=sitematrix&format=json"
response = requests.get(url)
response.raise_for_status()
sitematrix = response.json()["sitematrix"]

languages = []
for key, block in sitematrix.items():
    if key.isdigit():
        languages.append({"name": block["name"]})

with open("language_names.json", "w", encoding="utf-8") as f:
    json.dump(languages, f, ensure_ascii=False, indent=2)
