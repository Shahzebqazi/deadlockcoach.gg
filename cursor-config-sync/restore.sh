#!/bin/bash

# Cursor Configuration Restore Script
# Restores your Cursor IDE configuration from a captured backup

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/config.yaml"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Source utility functions
source "$SCRIPT_DIR/utils.sh"

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

# Function to detect Cursor installation
detect_cursor() {
    log_step "Detecting Cursor installation..."
    
    # Check macOS
    if [[ -d "$HOME/Library/Application Support/Cursor" ]]; then
        CURSOR_CONFIG_DIR="$HOME/Library/Application Support/Cursor/User"
        log_info "✓ Found Cursor on macOS: $CURSOR_CONFIG_DIR"
        return 0
    fi
    
    # Check Linux
    if [[ -d "$HOME/.config/Cursor" ]]; then
        CURSOR_CONFIG_DIR="$HOME/.config/Cursor/User"
        log_info "✓ Found Cursor on Linux: $CURSOR_CONFIG_DIR"
        return 0
    fi
    
    # Check Windows (if running in WSL)
    if [[ -d "/mnt/c/Users/$USER/AppData/Roaming/Cursor" ]]; then
        CURSOR_CONFIG_DIR="/mnt/c/Users/$USER/AppData/Roaming/Cursor/User"
        log_info "✓ Found Cursor on Linux: $CURSOR_CONFIG_DIR"
        return 0
    fi
    
    log_error "Cursor not found. Please install Cursor first."
    exit 1
}

# Function to list available captures
list_captures() {
    log_step "Available configuration captures:"
    
    if [[ ! -d "$SCRIPT_DIR/captured-configs" ]]; then
        log_error "No captured configurations found."
        log_info "Run ./capture.sh first to capture your current configuration."
        exit 1
    fi
    
    captures=($(ls -1t "$SCRIPT_DIR/captured-configs" 2>/dev/null | head -10))
    
    if [[ ${#captures[@]} -eq 0 ]]; then
        log_error "No captured configurations found."
        exit 1
    fi
    
    echo ""
    for i in "${!captures[@]}"; do
        capture_dir="$SCRIPT_DIR/captured-configs/${captures[$i]}"
        if [[ -f "$capture_dir/metadata.json" ]]; then
            timestamp=$(jq -r '.timestamp' "$capture_dir/metadata.json" 2>/dev/null || echo "Unknown")
            os=$(jq -r '.os' "$capture_dir/metadata.json" 2>/dev/null || echo "Unknown")
            echo "  $((i+1)). ${captures[$i]} ($os - $timestamp)"
        else
            echo "  $((i+1)). ${captures[$i]}"
        fi
    done
    echo ""
}

# Function to select capture
select_capture() {
    if [[ -n "$1" ]]; then
        # Use provided capture directory
        if [[ -d "$1" ]]; then
            SELECTED_CAPTURE="$1"
            log_info "Using provided capture: $SELECTED_CAPTURE"
            return 0
        else
            log_error "Provided capture directory does not exist: $1"
            exit 1
        fi
    fi
    
    # Interactive selection
    list_captures
    
    read -p "Select capture to restore (1-${#captures[@]}): " selection
    
    if [[ ! "$selection" =~ ^[0-9]+$ ]] || [[ "$selection" -lt 1 ]] || [[ "$selection" -gt "${#captures[@]}" ]]; then
        log_error "Invalid selection. Please choose a number between 1 and ${#captures[@]}."
        exit 1
    fi
    
    SELECTED_CAPTURE="$SCRIPT_DIR/captured-configs/${captures[$((selection-1))]}"
    log_info "Selected capture: $SELECTED_CAPTURE"
}

# Function to create backup before restore
create_restore_backup() {
    log_step "Creating backup of current configuration before restore..."
    
    BACKUP_DIR="$HOME/.cursor-config-backups/pre-restore-$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    
    if [[ -d "$CURSOR_CONFIG_DIR" ]]; then
        cp -r "$CURSOR_CONFIG_DIR"/* "$BACKUP_DIR/" 2>/dev/null || true
        log_info "✓ Pre-restore backup created at: $BACKUP_DIR"
    fi
}

# Function to validate capture
validate_capture() {
    log_step "Validating capture integrity..."
    
    local capture_dir="$1"
    
    # Check if essential files exist
    local required_files=("metadata.json")
    local missing_files=()
    
    for file in "${required_files[@]}"; do
        if [[ ! -f "$capture_dir/$file" ]]; then
            missing_files+=("$file")
        fi
    done
    
    if [[ ${#missing_files[@]} -gt 0 ]]; then
        log_warn "Missing files in capture: ${missing_files[*]}"
    fi
    
    # Check metadata
    if [[ -f "$capture_dir/metadata.json" ]]; then
        local os=$(jq -r '.os' "$capture_dir/metadata.json" 2>/dev/null || echo "unknown")
        local current_os=$(uname -s)
        
        if [[ "$os" != "$current_os" ]] && [[ "$os" != "unknown" ]]; then
            log_warn "Capture was made on $os, but you're running on $current_os"
            read -p "Continue anyway? (y/N): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                log_info "Restore cancelled."
                exit 0
            fi
        fi
    fi
    
    log_info "✓ Capture validation completed"
}

# Function to restore core files
restore_core_files() {
    log_step "Restoring core configuration files..."
    
    local capture_dir="$1"
    
    # Restore settings.json
    if [[ -f "$capture_dir/settings.json" ]]; then
        cp "$capture_dir/settings.json" "$CURSOR_CONFIG_DIR/"
        log_info "✓ Restored settings.json"
    fi
    
    # Restore keybindings.json
    if [[ -f "$capture_dir/keybindings.json" ]]; then
        cp "$capture_dir/keybindings.json" "$CURSOR_CONFIG_DIR/"
        log_info "✓ Restored keybindings.json"
    fi
    
    # Restore snippets
    if [[ -d "$capture_dir/snippets" ]]; then
        rm -rf "$CURSOR_CONFIG_DIR/snippets" 2>/dev/null || true
        cp -r "$capture_dir/snippets" "$CURSOR_CONFIG_DIR/"
        log_info "✓ Restored snippets"
    fi
}

# Function to restore profiles
restore_profiles() {
    log_step "Restoring user profiles..."
    
    local capture_dir="$1"
    
    if [[ -d "$capture_dir/profiles" ]]; then
        # Create profiles directory if it doesn't exist
        mkdir -p "$CURSOR_CONFIG_DIR/profiles"
        
        # Restore each profile
        find "$capture_dir/profiles" -maxdepth 1 -type d -name "*" | while read profile_dir; do
            if [[ "$profile_dir" != "$capture_dir/profiles" ]]; then
                profile_name=$(basename "$profile_dir")
                mkdir -p "$CURSOR_CONFIG_DIR/profiles/$profile_name"
                
                # Restore profile files
                if [[ -f "$profile_dir/settings.json" ]]; then
                    cp "$profile_dir/settings.json" "$CURSOR_CONFIG_DIR/profiles/$profile_name/"
                fi
                
                if [[ -d "$profile_dir/snippets" ]]; then
                    rm -rf "$CURSOR_CONFIG_DIR/profiles/$profile_name/snippets" 2>/dev/null || true
                    cp -r "$profile_dir/snippets" "$CURSOR_CONFIG_DIR/profiles/$profile_name/"
                fi
                
                log_info "✓ Restored profile: $profile_name"
            fi
        done
    fi
}

# Function to restore extensions
restore_extensions() {
    log_step "Restoring extensions..."
    
    local capture_dir="$1"
    
    # Check if cursor CLI is available
    if ! command -v cursor &> /dev/null; then
        log_warn "Cursor CLI not available, skipping extension restoration"
        log_info "Please install extensions manually from: $capture_dir/extensions.txt"
        return 0
    fi
    
    # Restore from extensions.txt
    if [[ -f "$capture_dir/extensions.txt" ]]; then
        log_info "Installing extensions from capture..."
        
        # Read extensions and install them
        while IFS= read -r extension; do
            if [[ -n "$extension" ]] && [[ ! "$extension" =~ ^[[:space:]]*# ]]; then
                log_info "Installing: $extension"
                cursor --install-extension "$extension" 2>/dev/null || {
                    log_warn "Failed to install extension: $extension"
                }
            fi
        done < "$capture_dir/extensions.txt"
        
        log_info "✓ Extension restoration completed"
    else
        log_warn "No extensions.txt found, skipping extension restoration"
    fi
}

# Function to show restore summary
show_restore_summary() {
    log_info "✅ Configuration restore completed!"
    log_info "📁 Restored from: $SELECTED_CAPTURE"
    
    if [[ -f "$SELECTED_CAPTURE/SUMMARY.md" ]]; then
        echo ""
        log_info "📋 Restore Summary:"
        cat "$SELECTED_CAPTURE/SUMMARY.md"
    fi
    
    echo ""
    log_info "🔄 Please restart Cursor to apply all changes"
    log_info "💡 If you have issues, check the backup at: $BACKUP_DIR"
}

# Main restore function
main() {
    log_info "Starting Cursor configuration restore..."
    
    # Check if config file exists
    if [[ ! -f "$CONFIG_FILE" ]]; then
        log_error "Configuration file not found: $CONFIG_FILE"
        log_info "Please run ./setup.sh first"
        exit 1
    fi
    
    # Detect Cursor installation
    detect_cursor
    
    # Select capture to restore
    select_capture "$1"
    
    # Validate capture
    validate_capture "$SELECTED_CAPTURE"
    
    # Create backup before restore
    create_restore_backup
    
    # Restore different components
    restore_core_files "$SELECTED_CAPTURE"
    restore_profiles "$SELECTED_CAPTURE"
    restore_extensions "$SELECTED_CAPTURE"
    
    # Show summary
    show_restore_summary
}

# Run main function
main "$@"
