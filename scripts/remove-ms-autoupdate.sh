#!/bin/bash

# Microsoft AutoUpdate Removal Script for macOS
# Based on instructions from OSXDaily https://osxdaily.com/2019/07/20/how-delete-microsoft-autoupdate-mac/
# Usage: ./remove-ms-autoupdate.sh

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        print_error "This script should not be run as root. Please run without sudo."
        print_status "The script will request sudo privileges when needed."
        exit 1
    fi
}

# Function to quit Microsoft AutoUpdate if running
quit_autoupdate() {
    print_status "Checking if Microsoft AutoUpdate is running..."

    # Check if Microsoft AutoUpdate is running
    if pgrep -f "Microsoft AutoUpdate" > /dev/null; then
        print_status "Microsoft AutoUpdate is running. Attempting to quit..."

        # Try to quit gracefully first
        osascript -e 'tell application "Microsoft AutoUpdate" to quit' 2>/dev/null || true

        # Wait a moment for graceful quit
        sleep 2

        # Force quit if still running
        if pgrep -f "Microsoft AutoUpdate" > /dev/null; then
            print_status "Force quitting Microsoft AutoUpdate..."
            pkill -f "Microsoft AutoUpdate" || true
            sleep 1
        fi

        print_success "Microsoft AutoUpdate has been stopped."
    else
        print_status "Microsoft AutoUpdate is not currently running."
    fi
}

# Function to remove a file or directory
remove_item() {
    local item_path="$1"
    local item_description="$2"

    if [[ -e "$item_path" ]]; then
        print_status "Removing $item_description..."
        if sudo rm -rf "$item_path"; then
            print_success "Removed: $item_path"
            return 0
        else
            print_error "Failed to remove: $item_path"
            return 1
        fi
    else
        print_warning "$item_description not found at: $item_path"
        return 0
    fi
}

# Function to find and remove Microsoft AutoUpdate app
remove_autoupdate_app() {
    local ms_support_dir="/Library/Application Support/Microsoft"

    if [[ ! -d "$ms_support_dir" ]]; then
        print_warning "Microsoft Application Support directory not found: $ms_support_dir"
        return 0
    fi

    # Look for MAU or MAU2.0 directories
    local mau_dirs=("$ms_support_dir/MAU" "$ms_support_dir/MAU2.0")
    local found_mau=false

    for mau_dir in "${mau_dirs[@]}"; do
        if [[ -d "$mau_dir" ]]; then
            local autoupdate_app="$mau_dir/Microsoft AutoUpdate.app"
            if [[ -e "$autoupdate_app" ]]; then
                remove_item "$autoupdate_app" "Microsoft AutoUpdate.app"
                found_mau=true
            fi

            # Optionally remove the entire MAU directory if it's empty or only contains the app
            if [[ -d "$mau_dir" ]]; then
                local remaining_items=$(find "$mau_dir" -mindepth 1 -maxdepth 1 | wc -l)
                if [[ $remaining_items -eq 0 ]]; then
                    remove_item "$mau_dir" "Empty MAU directory"
                fi
            fi
        fi
    done

    if [[ "$found_mau" == false ]]; then
        print_warning "Microsoft AutoUpdate.app not found in expected locations"

        # Try to find it with spotlight/find
        print_status "Searching for Microsoft AutoUpdate.app in system..."
        local found_apps=$(find /Library -name "Microsoft AutoUpdate.app" -type d 2>/dev/null)

        if [[ -n "$found_apps" ]]; then
            echo "$found_apps" | while read -r app_path; do
                remove_item "$app_path" "Microsoft AutoUpdate.app (found at alternate location)"
            done
        fi
    fi
}

# Function to remove launch agents and daemons
remove_launch_items() {
    local items=(
        "/Library/LaunchAgents/com.microsoft.update.agent.plist:Launch Agent"
        "/Library/LaunchDaemons/com.microsoft.autoupdate.helper.plist:Launch Daemon"
        "/Library/PrivilegedHelperTools/com.microsoft.autoupdate.helper:Privileged Helper Tool"
    )

    for item in "${items[@]}"; do
        local path="${item%:*}"
        local description="${item#*:}"
        remove_item "$path" "$description"
    done
}

# Function to clean up user-specific items
cleanup_user_items() {
    local user_launch_agents="$HOME/Library/LaunchAgents"
    local user_items=(
        "$user_launch_agents/com.microsoft.update.agent.plist"
        "$user_launch_agents/com.microsoft.autoupdate.helper.plist"
    )

    for item in "${user_items[@]}"; do
        if [[ -e "$item" ]]; then
            print_status "Removing user-specific item: $(basename "$item")"
            rm -f "$item" && print_success "Removed: $item"
        fi
    done
}

# Function to verify removal
verify_removal() {
    print_status "Verifying removal..."

    local verification_failed=false

    # Check for Microsoft AutoUpdate.app
    if find /Library -name "Microsoft AutoUpdate.app" -type d 2>/dev/null | grep -q .; then
        print_warning "Microsoft AutoUpdate.app still found on system"
        verification_failed=true
    fi

    # Check for launch items
    local launch_items=(
        "/Library/LaunchAgents/com.microsoft.update.agent.plist"
        "/Library/LaunchDaemons/com.microsoft.autoupdate.helper.plist"
        "/Library/PrivilegedHelperTools/com.microsoft.autoupdate.helper"
    )

    for item in "${launch_items[@]}"; do
        if [[ -e "$item" ]]; then
            print_warning "Launch item still exists: $item"
            verification_failed=true
        fi
    done

    if [[ "$verification_failed" == false ]]; then
        print_success "Microsoft AutoUpdate has been successfully removed!"
    else
        print_warning "Some items may still remain. Check the warnings above."
    fi
}

# Main function
main() {
    echo -e "${BLUE}Microsoft AutoUpdate Removal Script${NC}"
    echo "======================================"

    # Check if running as root
    check_root

    # Ask for confirmation
    echo
    print_warning "This script will remove Microsoft AutoUpdate from your Mac."
    print_warning "If you still use Microsoft Office apps, you may want to keep AutoUpdate."
    echo
    read -p "Do you want to continue? [y/N]: " -n 1 -r
    echo

    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_status "Operation cancelled by user."
        exit 0
    fi

    echo
    print_status "Starting Microsoft AutoUpdate removal..."

    # Quit Microsoft AutoUpdate if running
    quit_autoupdate

    # Remove Microsoft AutoUpdate app
    remove_autoupdate_app

    # Remove launch agents and daemons
    remove_launch_items

    # Clean up user-specific items
    cleanup_user_items

    # Verify removal
    verify_removal

    echo
    print_success "Microsoft AutoUpdate removal completed!"
    print_status "You may need to restart your Mac for all changes to take effect."

    # Optional: Empty trash
    read -p "Would you like to empty the Trash? [y/N]: " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        osascript -e 'tell application "Finder" to empty trash' 2>/dev/null || {
            print_warning "Could not empty trash automatically. Please empty it manually."
        }
        print_success "Trash emptied."
    fi
}

# Run main function
main "$@"
