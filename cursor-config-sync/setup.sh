#!/bin/bash

# Cursor Configuration Sync - Setup Script
# Initial setup and configuration

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/config.yaml"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Function to check prerequisites
check_prerequisites() {
    log_step "Checking prerequisites..."
    
    # Check if we're on macOS
    if [[ "$(uname)" != "Darwin" ]]; then
        log_warn "This setup is optimized for macOS. Other platforms may need manual configuration."
    fi
    
    # Check if Cursor is installed
    if [[ ! -d "$HOME/Library/Application Support/Cursor" ]]; then
        log_error "Cursor not found. Please install Cursor first:"
        log_info "  Download from: https://cursor.sh"
        log_info "  Or install via Homebrew: brew install --cask cursor"
        exit 1
    fi
    
    log_info "✓ Cursor is installed"
    
    # Check if git is available
    if ! command -v git &> /dev/null; then
        log_error "Git is not installed. Please install git first:"
        log_info "  Install via Homebrew: brew install git"
        log_info "  Or download from: https://git-scm.com/"
        exit 1
    fi
    
    log_info "✓ Git is available"
    
    # Check if jq is available
    if ! command -v jq &> /dev/null; then
        log_warn "jq is not installed. Installing via Homebrew..."
        if command -v brew &> /dev/null; then
            brew install jq
        else
            log_error "Please install jq manually: https://stedolan.github.io/jq/download/"
            exit 1
        fi
    fi
    
    log_info "✓ jq is available"
}

# Function to configure GitHub repository
configure_github() {
    log_step "Configuring GitHub repository..."
    
    echo ""
    log_info "You'll need a GitHub repository to store your Cursor configurations."
    log_info "If you don't have one, create it at: https://github.com/new"
    echo ""
    
    read -p "Enter your GitHub username: " github_username
    read -p "Enter your GitHub repository name: " github_repo_name
    
    if [[ -z "$github_username" ]] || [[ -z "$github_repo_name" ]]; then
        log_error "GitHub username and repository name are required."
        exit 1
    fi
    
    GITHUB_REPO="$github_username/$github_repo_name"
    
    # Test if repository exists
    log_info "Testing repository access..."
    if curl -s "https://api.github.com/repos/$GITHUB_REPO" | grep -q "Not Found"; then
        log_error "Repository not found: $GITHUB_REPO"
        log_info "Please create the repository first at: https://github.com/new"
        exit 1
    fi
    
    log_info "✓ Repository found: $GITHUB_REPO"
}

# Function to configure GitHub token
configure_github_token() {
    log_step "Configuring GitHub authentication..."
    
    echo ""
    log_info "You'll need a GitHub Personal Access Token for authentication."
    log_info "Create one at: https://github.com/settings/tokens"
    log_info "Required scopes: repo, workflow"
    echo ""
    
    read -s -p "Enter your GitHub Personal Access Token: " github_token
    echo ""
    
    if [[ -z "$github_token" ]]; then
        log_error "GitHub token is required."
        exit 1
    fi
    
    # Test token
    log_info "Testing GitHub token..."
    local response=$(curl -s -H "Authorization: token $github_token" \
        "https://api.github.com/user" 2>/dev/null)
    
    if [[ "$response" == *"Bad credentials"* ]] || [[ "$response" == *"Not Found"* ]]; then
        log_error "Invalid GitHub token. Please check your token."
        exit 1
    fi
    
    local username=$(echo "$response" | jq -r '.login' 2>/dev/null)
    log_info "✓ Token validated for user: $username"
    
    # Save token to environment file
    cat > "$SCRIPT_DIR/.env" << EOF
# GitHub Personal Access Token
# Get one from: https://github.com/settings/tokens
GITHUB_TOKEN=$github_token
EOF
    
    log_info "✓ GitHub token saved to .env file"
}

# Function to update configuration file
update_config_file() {
    log_step "Updating configuration file..."
    
    # Backup original config
    if [[ -f "$CONFIG_FILE" ]]; then
        cp "$CONFIG_FILE" "$CONFIG_FILE.backup"
        log_info "✓ Backed up original config.yaml"
    fi
    
    # Update GitHub repository in config
    sed -i.bak "s/repo: \"yourusername\/cursor-config-sync\"/repo: \"$GITHUB_REPO\"/" "$CONFIG_FILE"
    
    log_info "✓ Updated config.yaml with GitHub repository"
}

# Function to create necessary directories
create_directories() {
    log_step "Creating necessary directories..."
    
    mkdir -p "$SCRIPT_DIR/captured-configs"
    mkdir -p "$SCRIPT_DIR/logs"
    
    log_info "✓ Created captured-configs directory"
    log_info "✓ Created logs directory"
}

# Function to make scripts executable
make_executable() {
    log_step "Making scripts executable..."
    
    chmod +x "$SCRIPT_DIR"/*.sh
    log_info "✓ Made all scripts executable"
}

# Function to setup auto-sync
setup_auto_sync() {
    log_step "Setting up auto-sync..."
    
    echo ""
    log_info "Auto-sync options:"
    log_info "  1. startup - Sync when Cursor starts"
    log_info "  2. hourly  - Sync every hour"
    log_info "  3. daily   - Sync once per day"
    log_info "  4. never   - Manual sync only"
    echo ""
    
    read -p "Choose auto-sync frequency (1-4): " sync_choice
    
    case "$sync_choice" in
        1) sync_frequency="startup" ;;
        2) sync_frequency="hourly" ;;
        3) sync_frequency="daily" ;;
        4) sync_frequency="never" ;;
        *) 
            log_warn "Invalid choice, defaulting to startup"
            sync_frequency="startup"
            ;;
    esac
    
    if [[ "$sync_frequency" != "never" ]]; then
        log_info "Setting up auto-sync: $sync_frequency"
        "$SCRIPT_DIR/sync.sh" "auto-sync" "$sync_frequency"
    else
        log_info "Auto-sync disabled. Use ./sync.sh manually when needed."
    fi
}

# Function to test setup
test_setup() {
    log_step "Testing setup..."
    
    # Test configuration loading
    if [[ ! -f "$CONFIG_FILE" ]]; then
        log_error "Configuration file not found"
        return 1
    fi
    
    # Test GitHub token
    if [[ ! -f "$SCRIPT_DIR/.env" ]]; then
        log_error "Environment file not found"
        return 1
    fi
    
    # Test if we can access GitHub
    source "$SCRIPT_DIR/.env"
    if [[ -z "$GITHUB_TOKEN" ]]; then
        log_error "GitHub token not loaded"
        return 1
    fi
    
    log_info "✓ Setup test passed"
    return 0
}

# Function to show next steps
show_next_steps() {
    log_info "✅ Setup completed successfully!"
    echo ""
    log_info "Next steps:"
    log_info "  1. Capture your current Cursor configuration:"
    log_info "     ./capture.sh"
    echo ""
    log_info "  2. Sync to GitHub:"
    log_info "     ./sync.sh"
    echo ""
    log_info "  3. After reinstalling Cursor, restore your config:"
    log_info "     ./restore.sh"
    echo ""
    log_info "  4. Check sync status anytime:"
    log_info "     ./sync.sh status"
    echo ""
    log_info "📚 For more information, see README.md"
}

# Main setup function
main() {
    log_info "🚀 Cursor Configuration Sync - Setup"
    log_info "====================================="
    echo ""
    
    # Check prerequisites
    check_prerequisites
    
    # Configure GitHub
    configure_github
    
    # Configure GitHub token
    configure_github_token
    
    # Update configuration file
    update_config_file
    
    # Create directories
    create_directories
    
    # Make scripts executable
    make_executable
    
    # Setup auto-sync
    setup_auto_sync
    
    # Test setup
    if test_setup; then
        show_next_steps
    else
        log_error "Setup test failed. Please check the configuration."
        exit 1
    fi
}

# Run main function
main "$@"
