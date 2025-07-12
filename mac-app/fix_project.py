#!/usr/bin/env python3
"""
Fix Xcode project file by removing duplicate entries and fixing file references
"""
import re
import os

def clean_pbxproj():
    project_file = "/Users/anaygupta/Downloads/promise-keeper/mac-app/SidebarApp.xcodeproj/project.pbxproj"
    
    # Read the project file
    with open(project_file, 'r') as f:
        content = f.read()
    
    # Remove duplicate PBXBuildFile entries
    build_file_pattern = r'(\t\t[A-F0-9]{24} /\* (.*?) in Sources \*/ = {isa = PBXBuildFile; fileRef = [A-F0-9]{24} /\* \2 \*/; };)'
    
    # Find all build file entries and group by filename
    build_files = {}
    for match in re.finditer(build_file_pattern, content):
        full_line = match.group(1)
        filename = match.group(2)
        
        if filename not in build_files:
            build_files[filename] = []
        build_files[filename].append(full_line)
    
    # Remove duplicates by keeping only the first occurrence
    for filename, lines in build_files.items():
        if len(lines) > 1:
            print(f"Removing {len(lines)-1} duplicate build file entries for {filename}")
            # Remove all but the first occurrence
            for line in lines[1:]:
                content = content.replace(line + '\n', '')
    
    # Remove duplicate file reference entries
    file_ref_pattern = r'(\t\t[A-F0-9]{24} /\* (.*?) \*/ = {isa = PBXFileReference; lastKnownFileType = sourcecode\.swift; path = \2; sourceTree = "<group>"; };)'
    
    file_refs = {}
    for match in re.finditer(file_ref_pattern, content):
        full_line = match.group(1)
        filename = match.group(2)
        
        if filename not in file_refs:
            file_refs[filename] = []
        file_refs[filename].append(full_line)
    
    # Remove duplicates
    for filename, lines in file_refs.items():
        if len(lines) > 1:
            print(f"Removing {len(lines)-1} duplicate file reference entries for {filename}")
            for line in lines[1:]:
                content = content.replace(line + '\n', '')
    
    # Remove duplicate entries from sources build phase
    sources_pattern = r'(\t\t\t\t[A-F0-9]{24} /\* (.*?) in Sources \*/,)'
    
    sources_files = {}
    for match in re.finditer(sources_pattern, content):
        full_line = match.group(1)
        filename = match.group(2)
        
        if filename not in sources_files:
            sources_files[filename] = []
        sources_files[filename].append(full_line)
    
    # Remove duplicates
    for filename, lines in sources_files.items():
        if len(lines) > 1:
            print(f"Removing {len(lines)-1} duplicate sources entries for {filename}")
            for line in lines[1:]:
                content = content.replace(line + '\n', '')
    
    # Write the cleaned content back
    with open(project_file, 'w') as f:
        f.write(content)
    
    print("Project file cleaned successfully")

if __name__ == "__main__":
    clean_pbxproj()