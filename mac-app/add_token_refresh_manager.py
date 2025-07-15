#!/usr/bin/env python3
import re
import uuid

def add_file_to_project():
    # Read the project file
    with open('PromiseKeeper.xcodeproj/project.pbxproj', 'r') as f:
        content = f.read()
    
    # Generate unique IDs
    file_ref_id = str(uuid.uuid4()).replace('-', '').upper()[:24]
    build_file_id = str(uuid.uuid4()).replace('-', '').upper()[:24]
    
    # Find the Managers group
    managers_match = re.search(r'(/\* Managers \*/ = \{[^}]+children = \([^)]+)', content, re.DOTALL)
    if not managers_match:
        print("Could not find Managers group")
        return False
    
    # Add file reference to Managers group
    managers_content = managers_match.group(1)
    new_managers_content = managers_content.rstrip() + f",\n\t\t\t\t{file_ref_id} /* TokenRefreshManager.swift */,"
    content = content.replace(managers_content, new_managers_content)
    
    # Add file reference in PBXFileReference section
    file_ref_section = re.search(r'(/\* Begin PBXFileReference section \*/.*?)(/\* End PBXFileReference section \*/)', content, re.DOTALL)
    if file_ref_section:
        new_file_ref = f"\t\t{file_ref_id} /* TokenRefreshManager.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = TokenRefreshManager.swift; sourceTree = \"<group>\"; }};\n"
        content = content.replace(file_ref_section.group(1), file_ref_section.group(1) + new_file_ref)
    
    # Find PromiseKeeper target's sources
    sources_match = re.search(r'(/\* Sources \*/ = \{[^}]+files = \([^)]+)', content, re.DOTALL)
    if sources_match:
        sources_content = sources_match.group(1)
        # Add before the closing parenthesis
        new_sources_content = sources_content.rstrip() + f",\n\t\t\t\t{build_file_id} /* TokenRefreshManager.swift in Sources */,"
        content = content.replace(sources_content, new_sources_content)
    
    # Add build file reference
    build_file_section = re.search(r'(/\* Begin PBXBuildFile section \*/.*?)(/\* End PBXBuildFile section \*/)', content, re.DOTALL)
    if build_file_section:
        new_build_file = f"\t\t{build_file_id} /* TokenRefreshManager.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {file_ref_id} /* TokenRefreshManager.swift */; }};\n"
        content = content.replace(build_file_section.group(1), build_file_section.group(1) + new_build_file)
    
    # Write the updated content
    with open('PromiseKeeper.xcodeproj/project.pbxproj', 'w') as f:
        f.write(content)
    
    print("Successfully added TokenRefreshManager.swift to project")
    return True

if __name__ == "__main__":
    add_file_to_project()