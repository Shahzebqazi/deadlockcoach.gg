#!/bin/bash

# Cursor Configuration Sync - Demo Script
# Shows how to use the tool step by step

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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

show_demo() {
    clear
    echo "🚀 Cursor Configuration Sync - Demo"
    echo "==================================="
    echo ""
    
    log_info "This demo will show you how to use the Cursor Configuration Sync tool."
    echo ""
    
    log_step "Step 1: Initial Setup"
    echo "  • Run: ./setup.sh"
    echo "  • Configure GitHub repository"
    echo "  • Set up GitHub authentication token"
    echo "  • Choose auto-sync frequency"
    echo ""
    
    log_step "Step 2: Capture Current Configuration"
    echo "  • Run: ./capture.sh"
    echo "  • This captures your current Cursor settings"
    echo "  • Creates timestamped backup"
    echo "  • Saves to captured-configs/ directory"
    echo ""
    
    log_step "Step 3: Sync to GitHub"
    echo "  • Run: ./sync.sh"
    echo "  • Pushes captured configs to GitHub"
    echo "  • Creates git repository if needed"
    echo "  • Commits and pushes changes"
    echo ""
    
    log_step "Step 4: After Reinstalling Cursor"
    echo "  • Run: ./restore.sh"
    echo "  • Choose which configuration to restore"
    echo "  • Automatically restores all settings"
    echo "  • Installs extensions from backup"
    echo ""
    
    log_step "Additional Commands"
    echo "  • ./sync.sh status     - Check sync status"
    echo "  • ./sync.sh capture <dir> - Sync specific capture"
    echo "  • ./capture.sh --no-backup - Capture without backup"
    echo ""
    
    log_info "The tool automatically:"
    echo "  ✓ Creates backups before any changes"
    echo "  ✓ Detects your OS and Cursor installation"
    echo "  ✓ Handles cross-platform compatibility"
    echo "  ✓ Manages GitHub authentication"
    echo "  ✓ Provides conflict resolution"
    echo ""
}

show_workflow() {
    log_step "Typical Workflow:"
    echo ""
    echo "1. 🔧 Setup (one-time):"
    echo "   ./setup.sh"
    echo ""
    echo "2. 📸 Capture your config:"
    echo "   ./capture.sh"
    echo ""
    echo "3. 🔄 Sync to GitHub:"
    echo "   ./sync.sh"
    echo ""
    echo "4. 🚀 After reinstalling Cursor:"
    echo "   ./restore.sh"
    echo ""
    echo "5. 📱 On another machine:"
    echo "   git clone <your-repo>"
    echo "   ./restore.sh"
    echo ""
}

show_examples() {
    log_step "Example Usage Scenarios:"
    echo ""
    
    echo "📱 Scenario 1: New Machine Setup"
    echo "  git clone https://github.com/yourusername/cursor-config-sync.git"
    echo "  cd cursor-config-sync"
    echo "  ./setup.sh"
    echo "  ./restore.sh"
    echo ""
    
    echo "🔄 Scenario 2: Regular Backup"
    echo "  ./capture.sh"
    echo "  ./sync.sh"
    echo ""
    
    echo "🔄 Scenario 3: Check Status"
    echo "  ./sync.sh status"
    echo ""
    
    echo "🔄 Scenario 4: Force Sync"
    echo "  ./sync.sh capture /path/to/capture"
    echo ""
}

show_troubleshooting() {
    log_step "Common Issues & Solutions:"
    echo ""
    
    echo "❌ Issue: 'GitHub token not found'"
    echo "  Solution: Run ./setup.sh again or set GITHUB_TOKEN env var"
    echo ""
    
    echo "❌ Issue: 'Repository not found'"
    echo "  Solution: Create GitHub repo first, then run ./setup.sh"
    echo ""
    
    echo "❌ Issue: 'Cursor not found'"
    echo "  Solution: Install Cursor first from https://cursor.sh"
    echo ""
    
    echo "❌ Issue: 'Permission denied'"
    echo "  Solution: Run chmod +x *.sh to make scripts executable"
    echo ""
    
    echo "❌ Issue: 'jq not found'"
    echo "  Solution: Install jq: brew install jq (macOS) or apt install jq (Linux)"
    echo ""
}

main() {
    case "${1:-}" in
        "workflow")
            show_workflow
            ;;
        "examples")
            show_examples
            ;;
        "troubleshooting")
            show_troubleshooting
            ;;
        *)
            show_demo
            echo ""
            log_info "For more details, run:"
            echo "  ./demo.sh workflow      - Show workflow"
            echo "  ./demo.sh examples      - Show examples"
            echo "  ./demo.sh troubleshooting - Show troubleshooting"
            ;;
    esac
}

# Run main function
main "$@"
