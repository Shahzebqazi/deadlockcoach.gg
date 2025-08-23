#!/bin/bash

# Utility functions for Cursor Configuration Sync
# This file is sourced by other scripts

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check if running on macOS
is_macos() {
    [[ "$(uname)" == "Darwin" ]]
}

# Function to check if running on Linux
is_linux() {
    [[ "$(uname)" == "Linux" ]]
}

# Function to check if running on Windows (WSL)
is_windows() {
    [[ "$(uname)" == "MINGW"* ]] || [[ "$(uname)" == "MSYS"* ]] || [[ -d "/mnt/c" ]]
}

# Function to get Cursor configuration directory
get_cursor_config_dir() {
    if is_macos; then
        echo "$HOME/Library/Application Support/Cursor/User"
    elif is_linux; then
        echo "$HOME/.config/Cursor/User"
    elif is_windows; then
        echo "/mnt/c/Users/$USER/AppData/Roaming/Cursor/User"
    else
        echo ""
    fi
}

# Function to check if Cursor is installed
cursor_installed() {
    local config_dir=$(get_cursor_config_dir)
    [[ -d "$config_dir" ]]
}

# Function to get Cursor version
get_cursor_version() {
    if command_exists cursor; then
        cursor --version 2>/dev/null | head -1 || echo "unknown"
    else
        echo "unknown"
    fi
}

# Function to create timestamp
get_timestamp() {
    date +%Y%m%d_%H%M%S
}

# Function to create ISO timestamp
get_iso_timestamp() {
    date -u +%Y-%m-%dT%H:%M:%SZ
}

# Function to create backup directory
create_backup_dir() {
    local base_dir="$HOME/.cursor-config-backups"
    local timestamp=$(get_timestamp)
    local backup_dir="$base_dir/$timestamp"
    
    mkdir -p "$backup_dir"
    echo "$backup_dir"
}

# Function to validate JSON file
validate_json() {
    local file="$1"
    
    if [[ ! -f "$file" ]]; then
        return 1
    fi
    
    if command_exists jq; then
        jq empty "$file" >/dev/null 2>&1
        return $?
    else
        # Simple validation without jq
        python3 -m json.tool "$file" >/dev/null 2>&1
        return $?
    fi
}

# Function to parse YAML-like config (simplified)
parse_config_value() {
    local config_file="$1"
    local key="$2"
    
    if [[ ! -f "$config_file" ]]; then
        return 1
    fi
    
    grep "^[[:space:]]*$key:" "$config_file" | head -1 | sed 's/.*:[[:space:]]*"\([^"]*\)".*/\1/'
}

# Function to check if directory is empty
is_dir_empty() {
    local dir="$1"
    [[ -z "$(ls -A "$dir" 2>/dev/null)" ]]
}

# Function to get file size in human readable format
get_file_size() {
    local file="$1"
    
    if [[ -f "$file" ]]; then
        du -h "$file" | cut -f1
    else
        echo "0B"
    fi
}

# Function to get directory size in human readable format
get_dir_size() {
    local dir="$1"
    
    if [[ -d "$dir" ]]; then
        du -sh "$dir" | cut -f1
    else
        echo "0B"
    fi
}

# Function to check if path contains spaces
path_has_spaces() {
    local path="$1"
    [[ "$path" == *" "* ]]
}

# Function to escape path with spaces
escape_path() {
    local path="$1"
    if path_has_spaces "$path"; then
        echo "\"$path\""
    else
        echo "$path"
    fi
}

# Function to show progress bar
show_progress() {
    local current="$1"
    local total="$2"
    local width=50
    
    local percentage=$((current * 100 / total))
    local filled=$((current * width / total))
    local empty=$((width - filled))
    
    printf "\r["
    printf "%${filled}s" | tr ' ' '#'
    printf "%${empty}s" | tr ' ' '-'
    printf "] %d%%" "$percentage"
    
    if [[ "$current" -eq "$total" ]]; then
        echo ""
    fi
}

# Function to check if running in interactive terminal
is_interactive() {
    [[ -t 0 ]]
}

# Function to ask for confirmation
ask_confirmation() {
    local message="$1"
    local default="${2:-N}"
    
    if ! is_interactive; then
        return 0  # Non-interactive, assume yes
    fi
    
    local prompt
    if [[ "$default" == "Y" ]]; then
        prompt="$message (Y/n): "
    else
        prompt="$message (y/N): "
    fi
    
    read -p "$prompt" -n 1 -r
    echo
    
    if [[ "$default" == "Y" ]]; then
        [[ ! $REPLY =~ ^[Nn]$ ]]
    else
        [[ $REPLY =~ ^[Yy]$ ]]
    fi
}

# Function to check if running as root
is_root() {
    [[ $EUID -eq 0 ]]
}

# Function to check if user has sudo privileges
has_sudo() {
    sudo -n true 2>/dev/null
}

# Function to run command with sudo if needed
run_with_sudo() {
    local cmd="$1"
    
    if is_root; then
        eval "$cmd"
    elif has_sudo; then
        sudo eval "$cmd"
    else
        log_error "This operation requires elevated privileges"
        return 1
    fi
}

# Function to create temporary directory
create_temp_dir() {
    local prefix="${1:-cursor-sync}"
    local temp_dir=$(mktemp -d "${TMPDIR:-/tmp}/${prefix}.XXXXXXXXXX")
    echo "$temp_dir"
}

# Function to cleanup temporary directory
cleanup_temp_dir() {
    local temp_dir="$1"
    
    if [[ -d "$temp_dir" ]]; then
        rm -rf "$temp_dir"
    fi
}

# Function to check if file is binary
is_binary() {
    local file="$1"
    
    if [[ ! -f "$file" ]]; then
        return 1
    fi
    
    # Check if file contains null bytes (binary indicator)
    if command_exists file; then
        file "$file" | grep -q "text"
        return $?
    else
        # Simple check for null bytes
        grep -q $'\x00' "$file" 2>/dev/null
        return $?
    fi
}

# Function to get file extension
get_file_extension() {
    local file="$1"
    echo "${file##*.}"
}

# Function to check if file is configuration file
is_config_file() {
    local file="$1"
    local ext=$(get_file_extension "$file")
    
    case "$ext" in
        json|yaml|yml|toml|ini|conf|config)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# Function to create checksum of file
get_file_checksum() {
    local file="$1"
    
    if command_exists sha256sum; then
        sha256sum "$file" | cut -d' ' -f1
    elif command_exists shasum; then
        shasum -a 256 "$file" | cut -d' ' -f1
    else
        echo "checksum_unavailable"
    fi
}

# Function to compare two files
files_identical() {
    local file1="$1"
    local file2="$2"
    
    if [[ ! -f "$file1" ]] || [[ ! -f "$file2" ]]; then
        return 1
    fi
    
    if command_exists cmp; then
        cmp -s "$file1" "$file2"
        return $?
    else
        # Fallback to checksum comparison
        local sum1=$(get_file_checksum "$file1")
        local sum2=$(get_file_checksum "$file2")
        [[ "$sum1" == "$sum2" ]]
    fi
}
