#!/usr/bin/env python3
import re

def remove_supabase_dependencies(project_path):
    """Remove Supabase dependencies from Xcode project file"""
    
    with open(project_path, 'r') as f:
        content = f.read()
    
    # Remove framework dependencies from Frameworks section
    frameworks_to_remove = [
        "25D4AD9B2E0737C900F48470 /* PostgREST in Frameworks */,",
        "25D4AD992E0737C900F48470 /* Functions in Frameworks */,", 
        "25D4ADA12E0737C900F48470 /* Supabase in Frameworks */,",
        "25D4AD972E0737C900F48470 /* Auth in Frameworks */,",
        "25D4AD9F2E0737C900F48470 /* Storage in Frameworks */,",
        "25D4AD9D2E0737C900F48470 /* Realtime in Frameworks */,"
    ]
    
    for framework in frameworks_to_remove:
        content = content.replace(f"\t\t\t\t{framework}\n", "")
    
    # Remove package references
    package_ref_pattern = r'\s*25D4AD942E0737AF00F48470 /\* XCRemoteSwiftPackageReference "supabase-swift" \*/,'
    content = re.sub(package_ref_pattern, '', content)
    
    # Remove XCRemoteSwiftPackageReference section for supabase
    supabase_section = r'25D4AD942E0737AF00F48470 /\* XCRemoteSwiftPackageReference "supabase-swift" \*/ = \{[^}]*\};'
    content = re.sub(supabase_section, '', content, flags=re.DOTALL)
    
    # Remove all XCSwiftPackageProductDependency entries for Supabase
    supabase_deps = [
        r'25D4AD962E0737C900F48470 /\* Auth \*/ = \{[^}]*\};',
        r'25D4AD982E0737C900F48470 /\* Functions \*/ = \{[^}]*\};',
        r'25D4AD9A2E0737C900F48470 /\* PostgREST \*/ = \{[^}]*\};',
        r'25D4AD9C2E0737C900F48470 /\* Realtime \*/ = \{[^}]*\};',
        r'25D4AD9E2E0737C900F48470 /\* Storage \*/ = \{[^}]*\};',
        r'25D4ADA02E0737C900F48470 /\* Supabase \*/ = \{[^}]*\};'
    ]
    
    for dep in supabase_deps:
        content = re.sub(dep, '', content, flags=re.DOTALL)
    
    # Clean up empty sections and extra whitespace
    content = re.sub(r'\n\s*\n\s*\n', '\n\n', content)
    
    with open(project_path, 'w') as f:
        f.write(content)
    
    print("Removed Supabase dependencies from Xcode project")

if __name__ == "__main__":
    project_file = "/Users/anaygupta/Downloads/promise-keeper/mac-app/PromiseKeeper.xcodeproj/project.pbxproj"
    remove_supabase_dependencies(project_file)