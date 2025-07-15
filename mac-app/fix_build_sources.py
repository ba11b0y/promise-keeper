#!/usr/bin/env python3
import re

def fix_build_sources():
    project_file = "/Users/anaygupta/Downloads/promise-keeper/mac-app/PromiseKeeper.xcodeproj/project.pbxproj"
    
    with open(project_file, 'r') as f:
        content = f.read()
    
    # Find the existing build file IDs for our files
    files_to_add = [
        ("AccessibilityHelper.swift", "8A9F8E90700D4B0AAA4C79AF"),
        ("AccessibilitySettingsView.swift", "C88604EF4BCD4D07A97D39EA"),
        ("PlatformLogo.swift", "7AB62DF003BB43BEBB94A7D8")
    ]
    
    # Find where TokenRefreshManager is in the sources
    token_match = re.search(r'(\s+)(D5EC69D4A9C845899B039316 /\* TokenRefreshManager\.swift in Sources \*/,)', content)
    
    if token_match:
        indent = token_match.group(1)
        
        # Add our files after TokenRefreshManager
        insertions = []
        for filename, build_id in files_to_add:
            # Check if already in content near this location
            search_start = max(0, token_match.start() - 2000)
            search_end = min(len(content), token_match.end() + 2000)
            search_section = content[search_start:search_end]
            
            if build_id not in search_section:
                insertions.append(f"{indent}{build_id} /* {filename} in Sources */,")
        
        if insertions:
            # Insert after the TokenRefreshManager line
            insert_pos = token_match.end()
            new_content = content[:insert_pos] + "\n" + "\n".join(insertions) + content[insert_pos:]
            
            with open(project_file, 'w') as f:
                f.write(new_content)
            
            print(f"Added {len(insertions)} files to build sources")
            for insertion in insertions:
                print(f"  - {insertion.strip()}")
        else:
            print("All files already in build sources")
    else:
        print("Could not find TokenRefreshManager in build sources")

if __name__ == "__main__":
    fix_build_sources()