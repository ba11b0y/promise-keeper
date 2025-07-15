#!/usr/bin/env python3
import re

def fix_file_groups():
    project_file = "/Users/anaygupta/Downloads/promise-keeper/mac-app/PromiseKeeper.xcodeproj/project.pbxproj"
    
    with open(project_file, 'r') as f:
        content = f.read()
    
    # Find the Utilities group children section
    utilities_match = re.search(r'(B7E076AC2E073ED30003AE17 /\* NotificationManager\.swift \*/,\n)(\s+)(4180AEF62839A13A0054FEA9 /\* AppKit Extensions \*/,)', content)
    
    if utilities_match:
        indent = utilities_match.group(2)
        # Add AccessibilityHelper after NotificationManager
        insert_pos = utilities_match.end(1)
        
        # Check if already there
        if "E418064580294F1EB260A623" not in content[insert_pos-200:insert_pos+200]:
            new_line = f"{indent}E418064580294F1EB260A623 /* AccessibilityHelper.swift */,\n"
            content = content[:insert_pos] + new_line + content[insert_pos:]
            print("Added AccessibilityHelper.swift to Utilities group")
    
    # Find the Views group - look for where other view files are
    views_match = re.search(r'(VIEW_SHARED_STYLES_REF /\* SharedStyles\.swift \*/,\n)(\s+)(VIEW_ELECTRON_REF /\* ElectronMatchingPromiseView\.swift \*/,)', content)
    
    if views_match:
        indent = views_match.group(2)
        insert_pos = views_match.end(1)
        
        # Add our view files
        insertions = []
        if "2A23C509D7A44DD78255607A" not in content[insert_pos-200:insert_pos+200]:
            insertions.append(f"{indent}2A23C509D7A44DD78255607A /* AccessibilitySettingsView.swift */,")
        if "64697AD0FC8F44919F98CF5A" not in content[insert_pos-200:insert_pos+200]:
            insertions.append(f"{indent}64697AD0FC8F44919F98CF5A /* PlatformLogo.swift */,")
        
        if insertions:
            content = content[:insert_pos] + "\n".join(insertions) + "\n" + content[insert_pos:]
            print(f"Added {len(insertions)} files to Views group")
    
    # Write back
    with open(project_file, 'w') as f:
        f.write(content)

if __name__ == "__main__":
    fix_file_groups()