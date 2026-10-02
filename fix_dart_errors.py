import os
import re

def fix_errors(directory):
    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.endswith('.dart'):
                filepath = os.path.join(root, file)
                with open(filepath, 'r', encoding='utf-8') as f:
                    content = f.read()

                original_content = content

                # Add missing import if .tr() is used
                if '.tr()' in content and 'easy_localization.dart' not in content:
                    # insert after the last import, or at the top
                    import_statement = "import 'package:easy_localization/easy_localization.dart';\n"
                    # find first import
                    match = re.search(r'^import\s+.*?;', content, re.MULTILINE)
                    if match:
                        content = content[:match.start()] + import_statement + content[match.start():]
                    else:
                        content = import_statement + content

                # Fix const issues: Replace `const ` with empty string for common widgets that might contain .tr()
                # A safe way is to replace `const ` with `` if the same line or next line contains `.tr()`
                # But it's easier to just strip `const ` from specific widget invocations in the whole file
                # because dart analyzer will just say "prefer const" instead of failing to compile.
                
                # We will aggressively remove `const ` before Text, InputDecoration, SnackBar, Center, DropdownMenuItem, Expanded
                # to ensure we catch all the errors.
                content = re.sub(r'const\s+(Text|InputDecoration|SnackBar|Center|DropdownMenuItem|Expanded|SizedBox|Padding|Align|Icon)\(', r'\1(', content)
                
                if content != original_content:
                    with open(filepath, 'w', encoding='utf-8') as f:
                        f.write(content)
                    print(f"Fixed const/imports in {file}")

fix_errors('lib/screens')
