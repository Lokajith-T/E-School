import os
import json
import re

with open('assets/translations/en.json', 'r', encoding='utf-8') as f:
    en_dict = json.load(f)

val_to_key = sorted([(v, k) for k, v in en_dict.items()], key=lambda x: len(x[0]), reverse=True)

def process_dart_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    original_content = content
    
    for val, key in val_to_key:
        escaped_val = re.escape(val)
        
        # Replace const Text('val') or const Text("val")
        content = re.sub(r'const\s+Text\(\s*[\'"]' + escaped_val + r'[\'"]\s*\)', f"Text('{key}'.tr())", content)
        
        # Replace Text('val') or Text("val")
        content = re.sub(r'Text\(\s*[\'"]' + escaped_val + r'[\'"]\s*\)', f"Text('{key}'.tr())", content)
        
        # Replace title: const Text('val')
        content = re.sub(r'title:\s*const\s+Text\(\s*[\'"]' + escaped_val + r'[\'"]\s*\)', f"title: Text('{key}'.tr())", content)
        
        # Replace title: Text('val')
        content = re.sub(r'title:\s*Text\(\s*[\'"]' + escaped_val + r'[\'"]\s*\)', f"title: Text('{key}'.tr())", content)
        
        # Replace label: const Text('val')
        content = re.sub(r'label:\s*const\s+Text\(\s*[\'"]' + escaped_val + r'[\'"]\s*\)', f"label: Text('{key}'.tr())", content)
        
        # Replace label: Text('val')
        content = re.sub(r'label:\s*Text\(\s*[\'"]' + escaped_val + r'[\'"]\s*\)', f"label: Text('{key}'.tr())", content)

        # Replace text: 'val' or text: "val" (like in Tab)
        content = re.sub(r'text:\s*[\'"]' + escaped_val + r'[\'"]', f"text: '{key}'.tr()", content)
        
        # Replace labelText: 'val' or labelText: "val"
        content = re.sub(r'labelText:\s*[\'"]' + escaped_val + r'[\'"]', f"labelText: '{key}'.tr()", content)
        
        # Replace hintText: 'val'
        content = re.sub(r'hintText:\s*[\'"]' + escaped_val + r'[\'"]', f"hintText: '{key}'.tr()", content)

        # Replace tooltip: 'val'
        content = re.sub(r'tooltip:\s*[\'"]' + escaped_val + r'[\'"]', f"tooltip: '{key}'.tr()", content)
        
    if content != original_content:
        # Check if we broke any const parents
        # This is a basic attempt to fix `const [ Text(...) ]` -> `[ Text(...) ]`
        # But for now let's just add the import
        if 'package:easy_localization/easy_localization.dart' not in content:
            imports = re.findall(r'^import\s+.*;$', content, re.MULTILINE)
            if imports:
                last_import = imports[-1]
                content = content.replace(last_import, f"{last_import}\nimport 'package:easy_localization/easy_localization.dart';")
            else:
                content = f"import 'package:easy_localization/easy_localization.dart';\n{content}"
                
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        return True
    return False

modified_count = 0
for root, _, files in os.walk('lib'):
    for file in files:
        if file.endswith('.dart'):
            if process_dart_file(os.path.join(root, file)):
                modified_count += 1

print(f"Modified {modified_count} files")
