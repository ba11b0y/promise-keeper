#!/usr/bin/env python3
import os
import uuid
import re

# List of new files to add to the Xcode project
new_files = [
    "PromiseKeeper/Managers/ScreenshotManager.swift",
    "PromiseKeeper/Managers/AutoPromiseManager.swift", 
    "PromiseKeeper/Managers/BAMLAPIClient.swift",
    "PromiseKeeper/Managers/MCPClient.swift",
    "PromiseKeeper/Views/CompactPromiseView.swift",
    "PromiseKeeper/Views/ModernPromiseView.swift",
    "PromiseKeeper/Utilities/StubManagers.swift"
]

def generate_id():
    """Generate a unique ID for Xcode project file"""
    return str(uuid.uuid4()).replace('-', '').upper()[:24]

def add_files_to_project(project_path, files_to_add):
    """Add files to Xcode project.pbxproj"""
    
    with open(project_path, 'r') as f:
        content = f.read()
    
    # Generate IDs for each file
    file_data = []
    for file_path in files_to_add:
        filename = os.path.basename(file_path)
        build_file_id = generate_id()
        file_ref_id = generate_id()
        
        file_data.append({
            'path': file_path,
            'filename': filename,
            'build_file_id': build_file_id,
            'file_ref_id': file_ref_id
        })
    
    # Add PBXBuildFile entries
    build_file_section = re.search(r'(/\* Begin PBXBuildFile section \*/.*?/\* End PBXBuildFile section \*/)', content, re.DOTALL)
    if build_file_section:
        build_entries = []
        for file_info in file_data:
            build_entries.append(f"\t\t{file_info['build_file_id']} /* {file_info['filename']} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_info['file_ref_id']} /* {file_info['filename']} */; }};")
        
        # Insert before "/* End PBXBuildFile section */"
        new_build_section = build_file_section.group(1).replace(
            "/* End PBXBuildFile section */",
            "\n".join(build_entries) + "\n/* End PBXBuildFile section */"
        )
        content = content.replace(build_file_section.group(1), new_build_section)
    
    # Add PBXFileReference entries  
    file_ref_section = re.search(r'(/\* Begin PBXFileReference section \*/.*?/\* End PBXFileReference section \*/)', content, re.DOTALL)
    if file_ref_section:
        ref_entries = []
        for file_info in file_data:
            ref_entries.append(f"\t\t{file_info['file_ref_id']} /* {file_info['filename']} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {file_info['filename']}; sourceTree = \"<group>\"; }};")
        
        # Insert before "/* End PBXFileReference section */"
        new_ref_section = file_ref_section.group(1).replace(
            "/* End PBXFileReference section */",
            "\n".join(ref_entries) + "\n/* End PBXFileReference section */"
        )
        content = content.replace(file_ref_section.group(1), new_ref_section)
    
    # Add to Sources build phase
    sources_section = re.search(r'(buildActionMask = 2147483647;.*?files = \(.*?\);)', content, re.DOTALL)
    if sources_section:
        source_entries = []
        for file_info in file_data:
            source_entries.append(f"\t\t\t\t{file_info['build_file_id']} /* {file_info['filename']} in Sources */,")
        
        # Insert before closing "); 
        sources_content = sources_section.group(1)
        files_section = re.search(r'(files = \((.*?)\);)', sources_content, re.DOTALL)
        if files_section:
            new_files_content = files_section.group(2) + "\n" + "\n".join(source_entries) + "\n\t\t\t"
            new_sources_section = sources_content.replace(
                files_section.group(1),
                f"files = ({new_files_content});"
            )
            content = content.replace(sources_section.group(1), new_sources_section)
    
    # Add files to appropriate groups (find and add to existing groups)
    # Add Managers files to existing structure
    managers_pattern = r'(25D4AD832E07339900F48470 /\* Managers \*/ = {.*?children = \((.*?)\);)'
    managers_match = re.search(managers_pattern, content, re.DOTALL)
    
    if managers_match:
        manager_files = [f for f in file_data if 'Managers/' in f['path']]
        manager_entries = []
        for file_info in manager_files:
            manager_entries.append(f"\t\t\t\t{file_info['file_ref_id']} /* {file_info['filename']} */,")
        
        if manager_entries:
            new_children = managers_match.group(2) + "\n" + "\n".join(manager_entries) + "\n\t\t\t"
            new_managers_section = managers_match.group(1).replace(
                f"children = ({managers_match.group(2)});",
                f"children = ({new_children});"
            )
            content = content.replace(managers_match.group(1), new_managers_section)
    
    # Write updated content
    with open(project_path, 'w') as f:
        f.write(content)
    
    print(f"Added {len(file_data)} files to Xcode project")
    for file_info in file_data:
        print(f"  - {file_info['filename']}")

if __name__ == "__main__":
    project_file = "/Users/anaygupta/Downloads/promise-keeper/mac-app/PromiseKeeper.xcodeproj/project.pbxproj"
    add_files_to_project(project_file, new_files)