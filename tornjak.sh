#!/bin/bash

PASSFILE="$HOME/.password-store/passwords.gpg"
TEMP_FILE="/tmp/pass_temp"
CLIPBOARD_TIMEOUT=45  # seconds before clearing clipboard

# Function to handle errors
error() {
    echo "Error: $1" >&2
    exit 1
}

# Function to detect clipboard command
get_clipboard_cmd() {
    if command -v xclip >/dev/null 2>&1; then
        echo "xclip -selection clipboard"
    elif command -v pbcopy >/dev/null 2>&1; then
        echo "pbcopy"
    else
        error "Clipboard tool not found. Please install xclip (Linux) or use macOS"
    fi
}

# Function to clear clipboard after timeout
clear_clipboard() {
    local clipboard_cmd="$1"
    sleep $CLIPBOARD_TIMEOUT
    echo -n "" | $clipboard_cmd
    echo "Clipboard cleared."
}

# Ensure password store directory exists
mkdir -p "$HOME/.password-store" || error "Failed to create password store directory"

# Function to check dependencies
check_dependencies() {
    command -v gpg >/dev/null 2>&1 || error "GPG is not installed. Please install it first"
    # Check for clipboard command during initialization
    get_clipboard_cmd >/dev/null || exit 1
}

# Function to initialize GPG key
init_gpg() {
    if ! gpg --list-secret-keys | grep -q "^sec"; then
        error "No GPG key found. Please create one first by running: gpg --full-generate-key"
    fi
}

# Function to add a new password
add_password() {
    local service="$1"
    local username="$2"

    # Read password securely
    echo -n "Enter password for $service: "
    read -s password || error "Failed to read password"
    echo

    # Create temporary file
    echo -n > "$TEMP_FILE" || error "Failed to create temporary file"

    # Decrypt existing file if it exists
    if [ -f "$PASSFILE" ]; then
        gpg --use-agent --decrypt "$PASSFILE" > "$TEMP_FILE" 2>/dev/null || error "Failed to decrypt password file"
    fi

    # Add new entry
    echo "$service:$username:$password" >> "$TEMP_FILE" || error "Failed to write to temporary file"

    # Encrypt and save
    local recipient
    recipient=$(gpg --list-secret-keys --keyid-format LONG | grep ^sec | cut -d'/' -f2 | cut -d' ' -f1) || error "Failed to get GPG key"
    gpg --yes --encrypt --recipient "$recipient" --output "$PASSFILE" "$TEMP_FILE" || error "Failed to encrypt password file"

    # Clean up
    shred -u "$TEMP_FILE" 2>/dev/null || error "Failed to securely delete temporary file"
    echo "Password added successfully!"
}

# Function to get a password
get_password() {
    local service="$1"

    [ -f "$PASSFILE" ] || error "No password file found"

    # Get clipboard command
    local clipboard_cmd
    clipboard_cmd=$(get_clipboard_cmd) || exit 1

    # Reset GPG agent to force passphrase prompt
    echo RELOADAGENT | gpg-connect-agent > /dev/null 2>&1 || error "Failed to reset GPG agent"

    # Decrypt and search
    local password_found=false
    local decrypted
    decrypted=$(gpg --use-agent --decrypt "$PASSFILE" 2>/dev/null) || error "Failed to decrypt password file"

    while IFS=':' read -r svc user pass; do
        if [ "$svc" = "$service" ]; then
            echo "$pass" | $clipboard_cmd || error "Failed to copy to clipboard"
            echo "Username: $user"
            echo "Password copied to clipboard. Will be cleared in $CLIPBOARD_TIMEOUT seconds."
            clear_clipboard "$clipboard_cmd" &
            password_found=true
            break
        fi
    done < <(echo "$decrypted" | grep "^$service:")

    [ "$password_found" = true ] || error "No password found for service: $service"
}

# Function to list all services
list_services() {
    [ -f "$PASSFILE" ] || error "No password file found"

    # Reset GPG agent to force passphrase prompt
    echo RELOADAGENT | gpg-connect-agent > /dev/null 2>&1 || error "Failed to reset GPG agent"

    echo "Stored services:"
    gpg --use-agent --decrypt "$PASSFILE" 2>/dev/null | while IFS=':' read -r svc user pass; do
        echo "$svc"
    done | sort | uniq || error "Failed to list services"
}

# Function to delete a password
delete_password() {
    local service="$1"

    [ -f "$PASSFILE" ] || error "No password file found"

    # Create temporary files
    touch "$TEMP_FILE" || error "Failed to create temporary file"

    # Reset GPG agent to force passphrase prompt
    echo RELOADAGENT | gpg-connect-agent > /dev/null 2>&1 || error "Failed to reset GPG agent"

    # Decrypt existing file
    gpg --use-agent --decrypt "$PASSFILE" > "$TEMP_FILE" 2>/dev/null || error "Failed to decrypt password file"

    # Remove matching entries
    grep -v "^$service:" "$TEMP_FILE" > "$TEMP_FILE.new" || error "Failed to process password file"

    # Encrypt and save
    local recipient
    recipient=$(gpg --list-secret-keys --keyid-format LONG | grep ^sec | cut -d'/' -f2 | cut -d' ' -f1) || error "Failed to get GPG key"
    gpg --yes --encrypt --recipient "$recipient" --output "$PASSFILE" "$TEMP_FILE.new" || error "Failed to encrypt password file"

    # Clean up
    shred -u "$TEMP_FILE" "$TEMP_FILE.new" 2>/dev/null || error "Failed to securely delete temporary files"
    echo "Password(s) for $service deleted successfully!"
}

# Main script
check_dependencies
init_gpg

case "$1" in
    "add")
        [ "$#" -eq 3 ] || error "Usage: $0 add <service> <username>"
        add_password "$2" "$3"
        ;;
    "get")
        [ "$#" -eq 2 ] || error "Usage: $0 get <service>"
        get_password "$2"
        ;;
    "list")
        list_services
        ;;
    "delete")
        [ "$#" -eq 2 ] || error "Usage: $0 delete <service>"
        delete_password "$2"
        ;;
    *)
        echo "Password Manager Usage:"
        echo "  $0 add <service> <username> - Add a new password"
        echo "  $0 get <service> - Get password for a service"
        echo "  $0 list - List all stored services"
        echo "  $0 delete <service> - Delete password for a service"
        ;;
esac
