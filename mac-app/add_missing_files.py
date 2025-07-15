#!/usr/bin/env python3
import os
import uuid
import re

# List of new files to add to the Xcode project
new_files = [
    "PromiseKeeper/Utilities/AccessibilityHelper.swift",
    "PromiseKeeper/Views/AccessibilitySettingsView.swift",
    "PromiseKeeper/Views/PlatformLogo.swift"
]

def generate_id():
    """Generate a unique ID for Xcode project file"""
    return str(uuid.uuid4()).replace('-', '').upper()[:24]

def add_files_to_project(project_path, files_to_add):
    """Add files to Xcode project.pbxproj"""
    
    with open(project_path, 'r') as f:
        content = f.read()
    
    # Check if files already exist
    files_to_actually_add = []
    for file_path in files_to_add:
        filename = os.path.basename(file_path)
        if filename not in content:
            files_to_actually_add.append(file_path)
        else:
            print(f"Skipping {filename} - already in project")
    
    if not files_to_actually_add:
        print("All files already in project")
        return
    
    # Generate IDs for each file
    file_data = []
    for file_path in files_to_actually_add:
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
    
    # Add to Sources build phase for PromiseKeeper target
    # Find the PromiseKeeper target's Sources build phase
    target_pattern = r'(25D4AD1A2E07338A00F48470 /\* PromiseKeeper \*/ = {.*?buildPhases = \((.*?)\);)'
    target_match = re.search(target_pattern, content, re.DOTALL)
    
    if target_match:
        # Find the Sources build phase ID
        build_phases = target_match.group(2)
        sources_id_match = re.search(r'([A-F0-9]{24}) /\* Sources \*/', build_phases)
        
        if sources_id_match:
            sources_id = sources_id_match.group(1)
            
            # Find the Sources build phase
            sources_pattern = rf'({sources_id} /\* Sources \*/ = {{.*?files = \((.*?)\);)'
            sources_match = re.search(sources_pattern, content, re.DOTALL)
            
            if sources_match:
                source_entries = []
                for file_info in file_data:
                    source_entries.append(f"\t\t\t\t{file_info['build_file_id']} /* {file_info['filename']} in Sources */,")
                
                # Add entries to files list
                existing_files = sources_match.group(2)
                new_files_content = existing_files.rstrip() + "\n" + "\n".join(source_entries) + "\n\t\t\t"
                
                new_sources_section = sources_match.group(1).replace(
                    f"files = ({existing_files});",
                    f"files = ({new_files_content});"
                )
                content = content.replace(sources_match.group(1), new_sources_section)
    
    # Add files to appropriate groups
    # Add Utilities files
    utilities_files = [f for f in file_data if 'Utilities/' in f['path']]
    if utilities_files:
        utilities_pattern = r'(25D4AD822E07339900F48470 /\* Utilities \*/ = {.*?children = \((.*?)\);)'
        utilities_match = re.search(utilities_pattern, content, re.DOTALL)
        
        if utilities_match:
            utility_entries = []
            for file_info in utilities_files:
                utility_entries.append(f"\t\t\t\t{file_info['file_ref_id']} /* {file_info['filename']} */,")
            
            if utility_entries:
                new_children = utilities_match.group(2).rstrip() + "\n" + "\n".join(utility_entries) + "\n\t\t\t"
                new_utilities_section = utilities_match.group(1).replace(
                    f"children = ({utilities_match.group(2)});",
                    f"children = ({new_children});"
                )
                content = content.replace(utilities_match.group(1), new_utilities_section)
    
    # Add Views files
    views_files = [f for f in file_data if 'Views/' in f['path']]
    if views_files:
        views_pattern = r'(25D4AD802E07339900F48470 /\* Views \*/ = {.*?children = \((.*?)\);)'
        views_match = re.search(views_pattern, content, re.DOTALL)
        
        if views_match:
            view_entries = []
            for file_info in views_files:
                view_entries.append(f"\t\t\t\t{file_info['file_ref_id']} /* {file_info['filename']} */,")
            
            if view_entries:
                new_children = views_match.group(2).rstrip() + "\n" + "\n".join(view_entries) + "\n\t\t\t"
                new_views_section = views_match.group(1).replace(
                    f"children = ({views_match.group(2)});",
                    f"children = ({new_children});"
                )
                content = content.replace(views_match.group(1), new_views_section)
    
    # Write updated content
    with open(project_path, 'w') as f:
        f.write(content)
    
    print(f"Added {len(file_data)} files to Xcode project")
    for file_info in file_data:
        print(f"  - {file_info['filename']}")

if __name__ == "__main__":
    project_file = "/Users/anaygupta/Downloads/promise-keeper/mac-app/PromiseKeeper.xcodeproj/project.pbxproj"
    add_files_to_project(project_file, new_files)