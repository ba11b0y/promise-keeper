#!/bin/bash

# Create platform logo imagesets
ASSETS_PATH="/Users/anaygupta/Downloads/promise-keeper/mac-app/PromiseKeeper/Assets.xcassets"
PLATFORMS=("discord-logo" "zoom-logo" "teams-logo" "whatsapp-logo" "telegram-logo" "signal-logo" "gmail-logo" "outlook-logo" "google-meet-logo" "messenger-logo" "instagram-logo" "twitter-logo" "x-logo" "linkedin-logo")

for platform in "${PLATFORMS[@]}"; do
    mkdir -p "$ASSETS_PATH/$platform.imageset"
    cat > "$ASSETS_PATH/$platform.imageset/Contents.json" <<EOF
{
  "images" : [
    {
      "filename" : "$platform.pdf",
      "idiom" : "universal"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  },
  "properties" : {
    "preserves-vector-representation" : true,
    "template-rendering-intent" : "original"
  }
}
EOF
    echo "Created imageset for $platform"
done

echo "All platform logo imagesets created!"