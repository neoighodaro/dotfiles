#!/usr/bin/env bash

# RELATED COMMENT / INSTRUCTIONS

# I couldn't find the zip file anywhere because the page is down, so I got Gemini to adjust the script to work based on an already-installed version of supermaven.
# Basically, I have supermaven installed on a 2024.* version of IntelliJ IDEA, pointed the script at it, and installed the zip file it created in my 2025.* IDEA.
# The script below is aimed at MacOS (Seqouia).
# - fill in your `YOUR_USER_NAME` var
# - run the script
# - Do the "Install plugin from disk" thing in your 2025.* IntelliJ (the plugin will still show as incompatible, ignore that, just click the Restart IDE button)

# This script updates an installed IntelliJ Supermaven plugin to be compatible
# with newer IntelliJ versions (e.g., 2025.x).
# It works by modifying the plugin's metadata directly from the installation
# directory and creating a new, installable ZIP file.

# --- CONFIGURATION ---
# IMPORTANT: This path is set based on the information you provided.
# If your IntelliJ version or user changes, you may need to update it.
YOUR_USER_NAME="neo"
PLUGIN_SOURCE_DIR="/Users/$YOUR_USER_NAME/Library/Application Support/JetBrains/IntelliJIdea2024.3/plugins/supermaven"
OUTPUT_ZIP_NAME="supermaven-updated.zip"
TARGET_BUILD="251.*" # Target build number for compatibility (e.g., "251.*" for 2025.1)

# --- SCRIPT LOGIC ---

# Get the directory where this script is located to place the output file there.
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
OUTPUT_PATH="$SCRIPT_DIR/$OUTPUT_ZIP_NAME"

# 1. Validation
if [ ! -d "$PLUGIN_SOURCE_DIR" ]; then
    echo "Error: The plugin source directory does not exist:"
    echo "$PLUGIN_SOURCE_DIR"
    echo "Please update the PLUGIN_SOURCE_DIR variable in this script."
    exit 1
fi

echo "Found plugin source at: $PLUGIN_SOURCE_DIR"

# Find the main plugin JAR file.
JAR_FILE=$(find "$PLUGIN_SOURCE_DIR/lib" -name "instrumented-supermaven-*.jar")
if [ ! -f "$JAR_FILE" ]; then
    echo "Error: Could not find 'instrumented-supermaven-*.jar' in the lib directory."
    exit 1
fi
echo "Found JAR file to modify: $(basename "$JAR_FILE")"

echo "Updating the supermaven extension manifest to be compatible with build '$TARGET_BUILD'..."

# 2. Prepare temporary directories
TMP_DIR=$(mktemp -d)
# Directory to hold a copy of the plugin for modification
PLUGIN_BUILD_DIR="$TMP_DIR/plugin_build"
# Directory for unzipping the JAR file
JAR_EXTRACT_DIR="$TMP_DIR/jar_contents"

mkdir -p "$PLUGIN_BUILD_DIR"
mkdir -p "$JAR_EXTRACT_DIR"


# 3. Copy the original plugin to a temporary build location
cp -R "$PLUGIN_SOURCE_DIR" "$PLUGIN_BUILD_DIR/supermaven"
TMP_PLUGIN_DIR="$PLUGIN_BUILD_DIR/supermaven"
TMP_JAR_FILE=$(find "$TMP_PLUGIN_DIR/lib" -name "instrumented-supermaven-*.jar")


# 4. Modify the plugin.xml inside the JAR
# Unzip the JAR to our temporary extract location
unzip -q "$TMP_JAR_FILE" -d "$JAR_EXTRACT_DIR"

# Edit the until-build attribute in plugin.xml to the target version
# The regex looks for `until-build="` followed by any characters until the next quote.
sed -i '' "s/until-build=\"[^\"]*\"/until-build=\"$TARGET_BUILD\"/g" "$JAR_EXTRACT_DIR/META-INF/plugin.xml"
echo "Modified plugin.xml."

# 5. Re-create the JAR with the modified plugin.xml
# First, remove the old JAR from our temporary build directory
rm "$TMP_JAR_FILE"
# Then, create the new JAR from the modified contents
(cd "$JAR_EXTRACT_DIR" && zip -qr "$TMP_JAR_FILE" .)
echo "Re-packaged the JAR file."

# 6. Create the final installable ZIP file
# The zip file must contain the 'supermaven' directory at its root for IntelliJ to recognize it.
(cd "$PLUGIN_BUILD_DIR" && zip -qr "$OUTPUT_PATH" supermaven)
echo "Created the final installable zip: $OUTPUT_PATH"

# 7. Cleanup
rm -rf "$TMP_DIR"

echo "Done!"
echo "You can now install '$OUTPUT_ZIP_NAME' in IntelliJ IDEA using 'Install Plugin from Disk...'."
