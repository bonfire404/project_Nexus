import os
import re

files = [
    r"c:\Users\Project\Project Nexus\lib\features\programs\presentation\screens\discover_screen.dart",
    r"c:\Users\Project\Project Nexus\lib\features\programs\presentation\screens\applications_screen.dart",
    r"c:\Users\Project\Project Nexus\lib\features\profile\presentation\screens\settings_screen.dart",
    r"c:\Users\Project\Project Nexus\lib\features\meetings\presentation\screens\schedule_screen.dart",
    r"c:\Users\Project\Project Nexus\lib\features\learning\presentation\screens\learning_screen.dart",
    r"c:\Users\Project\Project Nexus\lib\features\deliverables\presentation\screens\tasks_screen.dart",
    r"c:\Users\Project\Project Nexus\lib\features\dashboard\presentation\screens\home_screen.dart",
    r"c:\Users\Project\Project Nexus\lib\features\admin\presentation\screens\users_screen.dart",
    r"c:\Users\Project\Project Nexus\lib\features\admin\presentation\screens\programs_management_screen.dart",
]

def replacer(match):
    inner = match.group(0)
    text_match = re.search(r"content:\s*Text\(([^)]+)\)", inner)
    if text_match:
        msg = text_match.group(1).strip()
        return f"showGlassSnackbar(context, {msg});"
    return inner

for file in files:
    if not os.path.exists(file): 
        print(f"Skipping {file}")
        continue
    with open(file, 'r', encoding='utf-8') as f:
        content = f.read()

    new_content = re.sub(r'ScaffoldMessenger\.of\(context\)\.showSnackBar\([^;]+;', replacer, content)

    if new_content != content and "snackbar_utils.dart" not in new_content:
        new_content = re.sub(r"(import 'package:flutter/material\.dart';)", r"\1\nimport 'package:nexus/core/utils/snackbar_utils.dart';", new_content, 1)
        with open(file, 'w', encoding='utf-8') as f:
            f.write(new_content)
        print(f"Updated {file}")
