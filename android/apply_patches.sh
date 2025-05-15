#!/bin/bash
echo "Applying patches to Flutter plugins..."

# macOS path
if [[ "$OSTYPE" == "darwin"* ]]; then
  PLUGIN_PATH="$HOME/.pub-cache/hosted/pub.dev/flutter_local_notifications-9.1.5/android/build.gradle"
else
  # Linux path
  PLUGIN_PATH="$HOME/.pub-cache/hosted/pub.dev/flutter_local_notifications-9.1.5/android/build.gradle"
fi

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PATCH_PATH="$SCRIPT_DIR/patches/flutter_local_notifications_build.gradle"

echo ""
echo "Patching flutter_local_notifications plugin..."
echo "Source: $PATCH_PATH"
echo "Target: $PLUGIN_PATH"

if [ -f "$PLUGIN_PATH" ]; then
    cp "$PATCH_PATH" "$PLUGIN_PATH"
    echo "Patch applied successfully."
else
    echo "ERROR: Plugin build.gradle not found at expected location."
    echo "Please verify the plugin path: $PLUGIN_PATH"
fi

echo ""
echo "All patches completed." 