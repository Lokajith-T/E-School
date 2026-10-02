import json
import os

with open('extracted_strings.json', 'r', encoding='utf-8') as f:
    extracted = json.load(f)

# Update en.json
en_path = 'assets/translations/en.json'
en_data = {}
if os.path.exists(en_path):
    with open(en_path, 'r', encoding='utf-8') as f:
        en_data = json.load(f)

for k in extracted:
    if k not in en_data:
        en_data[k] = k

with open(en_path, 'w', encoding='utf-8') as f:
    json.dump(en_data, f, indent=2, ensure_ascii=False)

# Update ta.json
ta_path = 'assets/translations/ta.json'
ta_data = {}
if os.path.exists(ta_path):
    with open(ta_path, 'r', encoding='utf-8') as f:
        ta_data = json.load(f)

for k in extracted:
    if k not in ta_data:
        ta_data[k] = k # Fill with English temporarily so keys exist

with open(ta_path, 'w', encoding='utf-8') as f:
    json.dump(ta_data, f, indent=2, ensure_ascii=False)

print("Updated en.json and ta.json with all extracted keys!")
