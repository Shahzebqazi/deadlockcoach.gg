#!/bin/bash

# Cursor Configuration Capture Script
# Automatically captures your current Cursor IDE configuration

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/config.yaml"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
CAPTURE_DIR="$SCRIPT_DIR/captured-configs/$TIMESTAMP"

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
        log_info "✓ Found Cursor on Windows: $CURSOR_CONFIG_DIR"
        return 0
    fi
    
    log_error "Cursor not found. Please install Cursor first."
    exit 1
}

# Function to create backup
create_backup() {
    log_step "Creating backup of current configuration..."
    
    BACKUP_DIR="$HOME/.cursor-config-backups/$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    
    if [[ -d "$CURSOR_CONFIG_DIR" ]]; then
        cp -r "$CURSOR_CONFIG_DIR"/* "$BACKUP_DIR/" 2>/dev/null || true
        log_info "✓ Backup created at: $BACKUP_DIR"
    fi
}

# Function to capture core configuration files
capture_core_files() {
    log_step "Capturing core configuration files..."
    
    mkdir -p "$CAPTURE_DIR"
    
    # Capture main settings and keybindings
    if [[ -f "$CURSOR_CONFIG_DIR/settings.json" ]]; then
        cp "$CURSOR_CONFIG_DIR/settings.json" "$CAPTURE_DIR/"
        log_info "✓ Captured settings.json"
    fi
    
    if [[ -f "$CURSOR_CONFIG_DIR/keybindings.json" ]]; then
        cp "$CURSOR_CONFIG_DIR/keybindings.json" "$CAPTURE_DIR/"
        log_info "✓ Captured keybindings.json"
    fi
    
    # Capture snippets
    if [[ -d "$CURSOR_CONFIG_DIR/snippets" ]]; then
        cp -r "$CURSOR_CONFIG_DIR/snippets" "$CAPTURE_DIR/"
        log_info "✓ Captured snippets"
    fi
}

# Function to capture extensions
capture_extensions() {
    log_step "Capturing installed extensions..."
    
    # Check if cursor CLI is available
    if command -v cursor &> /dev/null; then
        cursor --list-extensions > "$CAPTURE_DIR/extensions.txt" 2>/dev/null || {
            log_warn "Could not list extensions via CLI, trying alternative method"
            # Alternative: look for extensions in profile
            if [[ -d "$CURSOR_CONFIG_DIR/profiles" ]]; then
                find "$CURSOR_CONFIG_DIR/profiles" -name "extensions.json" -exec cp {} "$CAPTURE_DIR/" \;
                log_info "✓ Captured extensions.json from profiles"
            fi
        }
    else
        log_warn "Cursor CLI not available, capturing extensions from profiles"
        if [[ -d "$CURSOR_CONFIG_DIR/profiles" ]]; then
            find "$CURSOR_CONFIG_DIR/profiles" -name "extensions.json" -exec cp {} "$CAPTURE_DIR/" \;
            log_info "✓ Captured extensions.json from profiles"
        fi
    fi
}

# Function to capture profiles
capture_profiles() {
    log_step "Capturing user profiles..."
    
    if [[ -d "$CURSOR_CONFIG_DIR/profiles" ]]; then
        mkdir -p "$CAPTURE_DIR/profiles"
        
        # Find all profile directories
        find "$CURSOR_CONFIG_DIR/profiles" -maxdepth 1 -type d -name "*" | while read profile_dir; do
            if [[ "$profile_dir" != "$CURSOR_CONFIG_DIR/profiles" ]]; then
                profile_name=$(basename "$profile_dir")
                mkdir -p "$CAPTURE_DIR/profiles/$profile_name"
                
                # Copy profile files
                if [[ -f "$profile_dir/settings.json" ]]; then
                    cp "$profile_dir/settings.json" "$CAPTURE_DIR/profiles/$profile_name/"
                fi
                
                if [[ -d "$profile_dir/snippets" ]]; then
                    cp -r "$profile_dir/snippets" "$CAPTURE_DIR/profiles/$profile_name/"
                fi
                
                log_info "✓ Captured profile: $profile_name"
            fi
        done
    fi
}

# Function to capture workspace storage (selective)
capture_workspace_storage() {
    log_step "Capturing workspace storage (selective)..."
    
    if [[ -d "$CURSOR_CONFIG_DIR/workspaceStorage" ]]; then
        mkdir -p "$CAPTURE_DIR/workspaceStorage"
        
        # Only capture workspace.json files that are not too large or too many
        find "$CURSOR_CONFIG_DIR/workspaceStorage" -name "workspace.json" -size -10k | head -20 | while read ws_file; do
            rel_path=$(realpath --relative-to="$CURSOR_CONFIG_DIR/workspaceStorage" "$ws_file")
            mkdir -p "$CAPTURE_DIR/workspaceStorage/$(dirname "$rel_path")"
            cp "$ws_file" "$CAPTURE_DIR/workspaceStorage/$rel_path"
        done
        
        log_info "✓ Captured selective workspace storage"
    fi
}

# Function to create metadata
create_metadata() {
    log_step "Creating capture metadata..."
    
    cat > "$CAPTURE_DIR/metadata.json" << EOF
{
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "cursor_version": "$(get_cursor_version)",
  "os": "$(uname -s)",
  "os_version": "$(uname -r)",
  "user": "$(whoami)",
  "hostname": "$(hostname)",
  "capture_version": "1.0.0"
}
EOF
    
    log_info "✓ Created metadata.json"
}

# Function to get Cursor version
get_cursor_version() {
    if command -v cursor &> /dev/null; then
        cursor --version 2>/dev/null | head -1 || echo "unknown"
    else
        echo "unknown"
    fi
}

# Function to create summary
create_summary() {
    log_step "Creating capture summary..."
    
    echo "📁 Cursor Configuration Capture Summary" > "$CAPTURE_DIR/SUMMARY.md"
    echo "=====================================" >> "$CAPTURE_DIR/SUMMARY.md"
    echo "" >> "$CAPTURE_DIR/SUMMARY.md"
    echo "**Timestamp:** $(date)" >> "$CAPTURE_DIR/SUMMARY.md"
    echo "**OS:** $(uname -s) $(uname -r)" >> "$CAPTURE_DIR/SUMMARY.md"
    echo "**User:** $(whoami)" >> "$CAPTURE_DIR/SUMMARY.md"
    echo "" >> "$CAPTURE_DIR/SUMMARY.md"
    
    echo "**Files Captured:**" >> "$CAPTURE_DIR/SUMMARY.md"
    find "$CAPTURE_DIR" -type f | sort | while read file; do
        rel_path=$(realpath --relative-to="$CAPTURE_DIR" "$file")
        size=$(du -h "$file" | cut -f1)
        echo "- $rel_path ($size)" >> "$CAPTURE_DIR/SUMMARY.md"
    done
    
    log_info "✓ Created SUMMARY.md"
}

# Main capture function
main() {
    log_info "Starting Cursor configuration capture..."
    
    # Check if config file exists
    if [[ ! -f "$CONFIG_FILE" ]]; then
        log_error "Configuration file not found: $CONFIG_FILE"
        log_info "Please run ./setup.sh first"
        exit 1
    fi
    
    # Detect Cursor installation
    detect_cursor
    
    # Create backup if enabled
    if [[ "$1" != "--no-backup" ]]; then
        create_backup
    fi
    
    # Create capture directory
    mkdir -p "$CAPTURE_DIR"
    
    # Capture different components
    capture_core_files
    capture_extensions
    capture_profiles
    capture_workspace_storage
    
    # Create metadata and summary
    create_metadata
    create_summary
    
    # Show final summary
    log_info "✅ Configuration capture completed!"
    log_info "📁 Captured to: $CAPTURE_DIR"
    log_info "📊 Total size: $(du -sh "$CAPTURE_DIR" | cut -f1)"
    
    # Ask if user wants to sync to GitHub
    read -p "Would you like to sync this capture to GitHub? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log_info "Running sync..."
        "$SCRIPT_DIR/sync.sh" "$CAPTURE_DIR"
    fi
}

# Run main function
main "$@"
