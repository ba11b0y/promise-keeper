#!/usr/bin/env python3
import os
import subprocess
import sys

# Files to add to the project
files_to_add = [
    "PromiseKeeper/Utilities/AccessibilityHelper.swift",
    "PromiseKeeper/Views/AccessibilitySettingsView.swift", 
    "PromiseKeeper/Views/PlatformLogo.swift"
]

# Project file path
project_path = "PromiseKeeper.xcodeproj"

def add_file_to_xcode_project(file_path, project_path):
    """Add a file to Xcode project using xcodeproj Ruby gem"""
    ruby_script = f"""
require 'xcodeproj'

project_path = '{project_path}'
file_path = '{file_path}'

# Open the project
project = Xcodeproj::Project.open(project_path)

# Get the main target
main_target = project.targets.find {{ |t| t.name == 'PromiseKeeper' }}

# Get the main group
main_group = project.main_group['PromiseKeeper']

# Determine which group to add to based on path
if file_path.include?('Utilities')
  group = main_group['Utilities'] || main_group.new_group('Utilities')
elsif file_path.include?('Views')  
  group = main_group['Views'] || main_group.new_group('Views')
else
  group = main_group
end

# Check if file already exists
file_ref = group.files.find {{ |f| f.path == File.basename(file_path) }}

if file_ref.nil?
  # Add the file reference
  file_ref = group.new_file(file_path)
  
  # Add to target
  main_target.add_file_references([file_ref])
  
  puts "Added #{file_path} to project"
else
  puts "#{file_path} already in project"
end

# Save the project
project.save
"""
    
    # Write the Ruby script to a temporary file
    script_path = '/tmp/add_to_xcode.rb'
    with open(script_path, 'w') as f:
        f.write(ruby_script)
    
    # Execute the Ruby script
    result = subprocess.run(['ruby', script_path], capture_output=True, text=True)
    
    if result.returncode != 0:
        print(f"Error adding {file_path}: {result.stderr}")
        return False
    else:
        print(result.stdout.strip())
        return True

def main():
    print("Adding files to Xcode project...")
    
    # Check if xcodeproj gem is installed
    check_gem = subprocess.run(['gem', 'list', 'xcodeproj', '-i'], capture_output=True, text=True)
    if check_gem.stdout.strip() != 'true':
        print("Installing xcodeproj gem...")
        subprocess.run(['sudo', 'gem', 'install', 'xcodeproj'])
    
    # Add each file
    success_count = 0
    for file_path in files_to_add:
        if os.path.exists(file_path):
            if add_file_to_xcode_project(file_path, project_path):
                success_count += 1
        else:
            print(f"Warning: {file_path} does not exist")
    
    print(f"\nSuccessfully added {success_count}/{len(files_to_add)} files to the project")
    
    # Clean up
    if os.path.exists('/tmp/add_to_xcode.rb'):
        os.remove('/tmp/add_to_xcode.rb')

if __name__ == "__main__":
    main()