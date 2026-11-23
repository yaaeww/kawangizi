import re
import os

root = r'F:\TUGASBESAR'
pattern_from = re.compile(r'(from\s+[\'"])(\.\./)+(core|features|shared)/')
pattern_import = re.compile(r'(import\s+[\'"])(\.\./)+(core|features|shared)/')

for dirpath, _, filenames in os.walk(root):
    for fname in filenames:
        if not fname.endswith('.dart'):
            continue
        fpath = os.path.join(dirpath, fname)
        with open(fpath, 'r', encoding='utf-8') as f:
            content = f.read()
        new_content = pattern_from.sub(r"from 'package:kawangizi_mobile/\3/", content)
        new_content = pattern_import.sub(r"import 'package:kawangizi_mobile/\3/", new_content)
        if new_content != content:
            with open(fpath, 'w', encoding='utf-8') as f:
                f.write(new_content)
            print(f"Fixed: {fpath}")

print("Done")