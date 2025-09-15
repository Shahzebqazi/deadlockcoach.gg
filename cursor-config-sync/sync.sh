#!/bin/bash

# Cursor Configuration Sync Script
# Syncs captured configurations to GitHub repository

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/config.yaml"
GITHUB_TOKEN="${GITHUB_TOKEN:-}"

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

# Function to check dependencies
check_dependencies() {
    log_step "Checking dependencies..."
    
    # Check if git is available
    if ! command -v git &> /dev/null; then
        log_error "Git is not installed. Please install git first."
        exit 1
    fi
    
    # Check if jq is available (for JSON parsing)
    if ! command -v jq &> /dev/null; then
        log_warn "jq is not installed. Installing via Homebrew..."
        if command -v brew &> /dev/null; then
            brew install jq
        else
            log_error "Please install jq manually: https://stedolan.github.io/jq/download/"
            exit 1
        fi
    fi
    
    # Check if curl is available
    if ! command -v curl &> /dev/null; then
        log_error "curl is not installed. Please install curl first."
        exit 1
    fi
    
    log_info "✓ All dependencies are available"
}

# Function to load configuration
load_config() {
    log_step "Loading configuration..."
    
    if [[ ! -f "$CONFIG_FILE" ]]; then
        log_error "Configuration file not found: $CONFIG_FILE"
        log_info "Please run ./setup.sh first"
        exit 1
    fi
    
    # Parse YAML-like config (simplified)
    GITHUB_REPO=$(grep "repo:" "$CONFIG_FILE" | head -1 | sed 's/.*repo: *"\([^"]*\)".*/\1/')
    GITHUB_BRANCH=$(grep "branch:" "$CONFIG_FILE" | head -1 | sed 's/.*branch: *"\([^"]*\)".*/\1/')
    
    if [[ -z "$GITHUB_REPO" ]]; then
        log_error "GitHub repository not configured in config.yaml"
        exit 1
    fi
    
    log_info "✓ GitHub repo: $GITHUB_REPO"
    log_info "✓ Branch: ${GITHUB_BRANCH:-main}"
}

# Function to check GitHub token
check_github_token() {
    log_step "Checking GitHub authentication..."
    
    if [[ -z "$GITHUB_TOKEN" ]]; then
        log_error "GitHub token not found. Please set GITHUB_TOKEN environment variable."
        log_info "You can get a token from: https://github.com/settings/tokens"
        log_info "Or run: export GITHUB_TOKEN=your_token_here"
        exit 1
    fi
    
    # Test token validity
    local response=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
        "https://api.github.com/user" 2>/dev/null)
    
    if [[ "$response" == *"Bad credentials"* ]] || [[ "$response" == *"Not Found"* ]]; then
        log_error "Invalid GitHub token. Please check your token."
        exit 1
    fi
    
    local username=$(echo "$response" | jq -r '.login' 2>/dev/null)
    log_info "✓ Authenticated as: $username"
}

# Function to initialize git repository
init_git_repo() {
    log_step "Initializing git repository..."
    
    if [[ ! -d ".git" ]]; then
        git init
        git remote add origin "https://github.com/$GITHUB_REPO.git"
        log_info "✓ Git repository initialized"
    else
        # Check if remote is correct
        local current_remote=$(git remote get-url origin 2>/dev/null || echo "")
        if [[ "$current_remote" != "https://github.com/$GITHUB_REPO.git" ]]; then
            git remote set-url origin "https://github.com/$GITHUB_REPO.git"
            log_info "✓ Updated git remote to: $GITHUB_REPO"
        fi
    fi
    
    # Create .gitignore if it doesn't exist
    if [[ ! -f ".gitignore" ]]; then
        cat > .gitignore << EOF
# Cursor Configuration Sync
*.log
.DS_Store
.env
*.tmp
backups/
EOF
        log_info "✓ Created .gitignore"
    fi
}

# Function to sync captured configurations
sync_captures() {
    log_step "Syncing captured configurations..."
    
    if [[ ! -d "captured-configs" ]]; then
        log_warn "No captured configurations to sync"
        return 0
    fi
    
    # Add all captured configs
    git add captured-configs/
    
    # Check if there are changes to commit
    if git diff --cached --quiet; then
        log_info "✓ No changes to sync"
        return 0
    fi
    
    # Create commit
    local commit_message="🔄 Sync Cursor configurations - $(date '+%Y-%m-%d %H:%M:%S')"
    git commit -m "$commit_message"
    
    # Push to GitHub
    log_info "Pushing to GitHub..."
    if git push origin "${GITHUB_BRANCH:-main}"; then
        log_info "✓ Successfully synced to GitHub"
    else
        log_error "Failed to push to GitHub"
        return 1
    fi
}

# Function to sync specific capture
sync_specific_capture() {
    local capture_dir="$1"
    
    if [[ ! -d "$capture_dir" ]]; then
        log_error "Capture directory not found: $capture_dir"
        exit 1
    fi
    
    log_step "Syncing specific capture: $capture_dir"
    
    # Copy capture to captured-configs directory
    local capture_name=$(basename "$capture_dir")
    local target_dir="captured-configs/$capture_name"
    
    mkdir -p "captured-configs"
    if [[ -d "$target_dir" ]]; then
        rm -rf "$target_dir"
    fi
    
    cp -r "$capture_dir" "$target_dir"
    log_info "✓ Copied capture to: $target_dir"
    
    # Sync to GitHub
    sync_captures
}

# Function to pull latest changes
pull_latest() {
    log_step "Pulling latest changes from GitHub..."
    
    if git pull origin "${GITHUB_BRANCH:-main}"; then
        log_info "✓ Successfully pulled latest changes"
    else
        log_warn "Failed to pull latest changes (this is normal for new repos)"
    fi
}

# Function to show sync status
show_sync_status() {
    log_step "Sync status:"
    
    # Check if we're up to date with remote
    git fetch origin "${GITHUB_BRANCH:-main}" 2>/dev/null || true
    
    local local_commit=$(git rev-parse HEAD 2>/dev/null || echo "none")
    local remote_commit=$(git rev-parse origin/"${GITHUB_BRANCH:-main}" 2>/dev/null || echo "none")
    
    if [[ "$local_commit" == "$remote_commit" ]]; then
        log_info "✓ Local repository is up to date with GitHub"
    else
        log_warn "⚠ Local repository is behind GitHub"
        log_info "Run 'git pull' to get latest changes"
    fi
    
    # Show recent commits
    echo ""
    log_info "Recent commits:"
    git log --oneline -5 2>/dev/null || echo "No commits yet"
}

# Function to setup auto-sync
setup_auto_sync() {
    local frequency="$1"
    
    log_step "Setting up auto-sync: $frequency"
    
    case "$frequency" in
        "startup")
            # Create launch agent for startup sync
            local launch_agent_dir="$HOME/Library/LaunchAgents"
            local launch_agent_file="$launch_agent_dir/com.cursor.config-sync.plist"
            
            mkdir -p "$launch_agent_dir"
            
            cat > "$launch_agent_file" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.cursor.config-sync</string>
    <key>ProgramArguments</key>
    <array>
        <string>$SCRIPT_DIR/sync.sh</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>StandardOutPath</key>
    <string>$SCRIPT_DIR/sync.log</string>
    <key>StandardErrorPath</key>
    <string>$SCRIPT_DIR/sync-error.log</string>
</dict>
</plist>
EOF
            
            launchctl load "$launch_agent_file"
            log_info "✓ Auto-sync on startup enabled"
            ;;
            
        "hourly"|"daily")
            # Create cron job
            local cron_schedule
            if [[ "$frequency" == "hourly" ]]; then
                cron_schedule="0 * * * *"
            else
                cron_schedule="0 0 * * *"
            fi
            
            # Add to crontab
            (crontab -l 2>/dev/null; echo "$cron_schedule cd $SCRIPT_DIR && ./sync.sh >> sync.log 2>&1") | crontab -
            log_info "✓ Auto-sync $frequency enabled"
            ;;
            
        *)
            log_error "Invalid frequency: $frequency. Use: startup, hourly, or daily"
            exit 1
            ;;
    esac
}

# Main sync function
main() {
    log_info "Starting Cursor configuration sync..."
    
    # Check dependencies
    check_dependencies
    
    # Load configuration
    load_config
    
    # Check GitHub token
    check_github_token
    
    # Initialize git repository
    init_git_repo
    
    # Pull latest changes
    pull_latest
    
    # Handle different sync modes
    case "${1:-}" in
        "status")
            show_sync_status
            ;;
        "auto-sync")
            setup_auto_sync "$2"
            ;;
        "capture")
            if [[ -n "$2" ]]; then
                sync_specific_capture "$2"
            else
                log_error "Please specify capture directory"
                exit 1
            fi
            ;;
        *)
            # Default: sync all captures
            sync_captures
            show_sync_status
            ;;
    esac
    
    log_info "✅ Sync completed successfully!"
}

# Run main function
main "$@"
