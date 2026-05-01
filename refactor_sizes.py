import re
import os

files_to_process = [
    'd:/habitz/lib/Features/solo/widgets/challenge_result_card.dart',
    'd:/habitz/lib/Features/solo/widgets/smart_feed_card.dart'
]

import_statement = "import '../constants/solo_constants.dart';"

for file_path in files_to_process:
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    if import_statement not in content:
        content = re.sub(r"(import 'package:flutter/material.dart';)", r"\1\n" + import_statement, content)

    # Use a set of rules to replace sizes
    # fontSize: 18 -> fontSize: 18.rs(context)
    content = re.sub(r'(fontSize:\s*)([0-9]+(?:\.[0-9]+)?)(?![\.r])', r'\1\2.rs(context)', content)

    # SizedBox(height: 16) -> SizedBox(height: 16.rs(context))
    content = re.sub(r'(SizedBox\s*\(\s*(?:width|height):\s*)([0-9]+(?:\.[0-9]+)?)(?![\.r])', r'\1\2.rs(context)', content)

    # padding: const EdgeInsets.all(22) -> padding: EdgeInsets.all(22.rs(context))
    content = re.sub(r'const\s*(EdgeInsets\.all\()([0-9]+(?:\.[0-9]+)?)\)', r'\1\2.rs(context))', content)
    
    # helper functions for symmetric, only, fromLTRB
    def res_sym(m):
        res = m.group(1).replace('const ', '')
        inner = m.group(2)
        inner = re.sub(r'(horizontal|vertical):\s*([0-9]+(?:\.[0-9]+)?)', r'\1: \2.rs(context)', inner)
        return res + inner + ')'
        
    content = re.sub(r'(const\s*EdgeInsets\.symmetric\()([^)]+)\)', res_sym, content)

    def res_only(m):
        res = m.group(1).replace('const ', '')
        inner = m.group(2)
        inner = re.sub(r'(left|right|top|bottom):\s*([0-9]+(?:\.[0-9]+)?)', r'\1: \2.rs(context)', inner)
        return res + inner + ')'

    content = re.sub(r'(const\s*EdgeInsets\.only\()([^)]+)\)', res_only, content)

    def res_fromLTRB(m):
        res = m.group(1).replace('const ', '')
        nums = m.group(2).split(',')
        new_nums = [n.strip() + '.rs(context)' for n in nums]
        return res + ', '.join(new_nums) + ')'

    content = re.sub(r'(const\s*EdgeInsets\.fromLTRB\()([^)]+)\)', res_fromLTRB, content)

    # Other common sizes
    # width: 52
    # height: 52
    content = re.sub(r'((?:^\s*|\b)(?:width|height|size|blurRadius):\s*)([0-9]+(?:\.[0-9]+)?)(?![\.r0-9a-zA-Z])', r'\1\2.rs(context)', content)
    
    # BorderRadius.circular(28) -> BorderRadius.circular(28.rs(context))
    content = re.sub(r'(BorderRadius\.circular\()([0-9]+(?:\.[0-9]+)?)\)', r'\1\2.rs(context))', content)

    # Remove duplicates like 18.rs(context).rs(context) which might happen
    content = re.sub(r'\.rs\(context\)\.rs\(context\)', '.rs(context)', content)

    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)

print('Done')
