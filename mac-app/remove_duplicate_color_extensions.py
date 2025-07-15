#!/usr/bin/env python3
import re
import os

files_to_fix = [
    "/Users/anaygupta/Downloads/promise-keeper/mac-app/PromiseKeeper/Views/CompactPromiseView.swift",
    "/Users/anaygupta/Downloads/promise-keeper/mac-app/PromiseKeeper/Views/ModernPromiseView.swift",
    "/Users/anaygupta/Downloads/promise-keeper/mac-app/PromiseKeeper/Panes/PromisesPane.swift",
]

def remove_color_extension(filepath):
    """Remove the Color extension from a Swift file"""
    if not os.path.exists(filepath):
        print(f"File not found: {filepath}")
        return
    
    with open(filepath, 'r') as f:
        content = f.read()
    
    # Find the extension Color { ... } block
    # This pattern handles multi-line extensions
    pattern = r'extension Color \{[^}]*\}[\s]*\n?'
    
    matches = list(re.finditer(pattern, content, re.DOTALL))
    
    if matches:
        # Remove from last to first to preserve indices
        for match in reversed(matches):
            content = content[:match.start()] + content[match.end():]
        
        with open(filepath, 'w') as f:
            f.write(content)
        print(f"Removed {len(matches)} Color extension(s) from {os.path.basename(filepath)}")
    else:
        print(f"No Color extension found in {os.path.basename(filepath)}")

# Process each file
for file in files_to_fix:
    remove_color_extension(file)

print("\nDone! Color extensions removed from duplicate files.")