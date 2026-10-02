import os
import re
import json

def process_files(directory):
    text_pattern = re.compile(r'Text\(\s*([\'"])(.*?)\1(?!\.tr\(\))')
    label_pattern = re.compile(r'labelText:\s*([\'"])(.*?)\1(?!\.tr\(\))')
    hint_pattern = re.compile(r'hintText:\s*([\'"])(.*?)\1(?!\.tr\(\))')
    
    extracted_strings = set()
    
    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.endswith('.dart'):
                filepath = os.path.join(root, file)
                with open(filepath, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                # We need a custom replacement function to collect strings
                def repl_text(m):
                    # exclude interpolations
                    if '$' in m.group(2) or '{' in m.group(2) or '}' in m.group(2):
                        return m.group(0)
                    if m.group(2).strip() == '':
                        return m.group(0)
                    extracted_strings.add(m.group(2))
                    return f"Text({m.group(1)}{m.group(2)}{m.group(1)}.tr()"
                
                def repl_label(m):
                    if '$' in m.group(2): return m.group(0)
                    if m.group(2).strip() == '': return m.group(0)
                    extracted_strings.add(m.group(2))
                    return f"labelText: {m.group(1)}{m.group(2)}{m.group(1)}.tr()"
                    
                def repl_hint(m):
                    if '$' in m.group(2): return m.group(0)
                    if m.group(2).strip() == '': return m.group(0)
                    extracted_strings.add(m.group(2))
                    return f"hintText: {m.group(1)}{m.group(2)}{m.group(1)}.tr()"

                new_content = text_pattern.sub(repl_text, content)
                new_content = label_pattern.sub(repl_label, new_content)
                new_content = hint_pattern.sub(repl_hint, new_content)
                
                if new_content != content:
                    with open(filepath, 'w', encoding='utf-8') as f:
                        f.write(new_content)
                    print(f"Updated {file}")

    return extracted_strings

strings = process_files('lib/screens')

# Output to JSON so we can translate
out = {s: s for s in strings}
with open('extracted_strings.json', 'w', encoding='utf-8') as f:
    json.dump(out, f, indent=2, ensure_ascii=False)

print(f"Extracted {len(strings)} strings.")
