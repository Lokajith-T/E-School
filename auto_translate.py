import json
from googletrans import Translator
import time

def translate_dict():
    with open('assets/translations/ta.json', 'r', encoding='utf-8') as f:
        ta_data = json.load(f)
        
    translator = Translator()
    
    translated_count = 0
    for key, value in ta_data.items():
        if value == key: # Needs translation
            try:
                res = translator.translate(key, dest='ta')
                if res and res.text:
                    ta_data[key] = res.text
                    translated_count += 1
                time.sleep(0.1) # Be nice to the API
            except Exception as e:
                print(f"Failed to translate {key}: {e}")
                
    with open('assets/translations/ta.json', 'w', encoding='utf-8') as f:
        json.dump(ta_data, f, indent=2, ensure_ascii=False)
        
    print(f"Successfully auto-translated {translated_count} new strings to Tamil!")

if __name__ == '__main__':
    translate_dict()
