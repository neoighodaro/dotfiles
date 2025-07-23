#!/usr/bin/env bash

# This script is used to update the supermaven extension manifest to run on IntelliJ 2025

show_help() {
    echo "Usage: $0 <path-to-supermaven-zip>"
    echo ""
    echo "This script updates the supermaven extension manifest to run on IntelliJ 2025."
    echo ""
    echo "Arguments:"
    echo "  <path-to-supermaven-zip>    Path to the supermaven zip file"
    echo ""
    echo "Example:"
    echo "  $0 ./supermaven-1.43.zip"
    echo "  $0 /path/to/supermaven-1.43.zip"
    echo ""
    echo "You can download the supermaven zip file from:"
    echo "https://plugins.jetbrains.com/plugin/23893-supermaven/versions/stable"
}

# Check if argument is provided
if [ $# -eq 0 ]; then
    echo "Error: No zip file path provided."
    echo ""
    show_help
    exit 1
fi

# Check for help flag
if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    show_help
    exit 0
fi

# Get the zip file path from command line argument
ZIP_FILE_PATH="$1"

# Get current script directory
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# Check if the zip file exists
if [ ! -f "$ZIP_FILE_PATH" ]; then
    echo "Error: The file '$ZIP_FILE_PATH' does not exist."
    echo ""
    show_help
    exit 1
fi

# Get the basename of the zip file (without directory path)
ZIP_FILENAME=$(basename "$ZIP_FILE_PATH")
# Get the filename without extension for output naming
ZIP_BASENAME="${ZIP_FILENAME%.*}"

echo "Updating the supermaven extension manifest to run on IntelliJ 2025..."
echo "Input file: $ZIP_FILE_PATH"

# Create a temporary directory
TMP_DIR=$(mktemp -d)

# Extract the zip file to the temporary directory
unzip -q "$ZIP_FILE_PATH" -d "$TMP_DIR"

# Find the jar file (it might have different naming patterns)
JAR_FILE=$(find "$TMP_DIR" -name "*.jar" -path "*/lib/*" | head -1)

if [ -z "$JAR_FILE" ]; then
    echo "Error: Could not find jar file in the expected location (*/lib/*.jar)"
    rm -rf "$TMP_DIR"
    exit 1
fi

JAR_FILENAME=$(basename "$JAR_FILE")
JAR_BASENAME="${JAR_FILENAME%.*}"
JAR_DIR=$(dirname "$JAR_FILE")

echo "Found jar file: $JAR_FILENAME"

# Unzip the jar file
unzip -q "$JAR_FILE" -d "$JAR_DIR/$JAR_BASENAME"

# Edit the until-build attribute in the plugin.xml file
PLUGIN_XML="$JAR_DIR/$JAR_BASENAME/META-INF/plugin.xml"

if [ ! -f "$PLUGIN_XML" ]; then
    echo "Error: Could not find plugin.xml file at $PLUGIN_XML"
    rm -rf "$TMP_DIR"
    exit 1
fi

echo "Updating plugin.xml..."

# Update the until-build attribute to support IntelliJ 2025 (251.*)
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    sed -i '' 's/until-build="[0-9]*\.\*"/until-build="251.*"/g' "$PLUGIN_XML"
else
    # Linux
    sed -i 's/until-build="[0-9]*\.\*"/until-build="251.*"/g' "$PLUGIN_XML"
fi

# Update the jar file with the new plugin.xml file
echo "Repackaging jar file..."
(cd "$JAR_DIR/$JAR_BASENAME" && zip -qr "$JAR_FILE" .)

# Remove the extracted jar directory
rm -rf "$JAR_DIR/$JAR_BASENAME"

# Create a new zip file from the temporary directory
OUTPUT_FILE="$DIR/${ZIP_BASENAME}-updated.zip"
echo "Creating updated zip file..."
(cd "$TMP_DIR" && zip -qr "$OUTPUT_FILE" .)

# Cleanup the temporary directory
rm -rf "$TMP_DIR"

echo "Done!"
echo "Updated file saved as: $OUTPUT_FILE"
