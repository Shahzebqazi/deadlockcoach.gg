# 🔄 Cursor Configuration Sync

A tool to automatically capture, backup, and restore your Cursor IDE configuration. Perfect for when you need to reinstall Cursor or want to sync your settings across multiple machines.

## ✨ What This Tool Does

- **🔄 Auto-capture** your current Cursor configuration
- **💾 Backup** to GitHub repository
- **🚀 One-click restore** after reinstalling Cursor
- **📱 Sync** across multiple machines
- **🛡️ Safe** - never overwrites without backup

## 🚀 Quick Start

```bash
# Clone this repo
git clone https://github.com/yourusername/cursor-config-sync.git
cd cursor-config-sync

# First time setup
./setup.sh

# Capture your current config
./capture.sh

# Restore your config (after reinstalling Cursor)
./restore.sh
```

## 📁 What Gets Captured

- **Settings**: `settings.json` (editor preferences, themes, etc.)
- **Keybindings**: `keybindings.json` (custom shortcuts)
- **Extensions**: List of installed extensions with versions
- **Snippets**: Custom code snippets
- **Profiles**: User profiles and their configurations
- **Workspace Storage**: Project-specific settings

## 🔧 Configuration

Edit `config.yaml` to customize:
- GitHub repository details
- What to capture/ignore
- Backup frequency
- Auto-sync settings

## 📋 Commands

| Command | Description |
|---------|-------------|
| `./capture.sh` | Capture current Cursor config |
| `./restore.sh` | Restore config from backup |
| `./sync.sh` | Sync with GitHub repository |
| `./setup.sh` | Initial setup and configuration |
| `./status.sh` | Check sync status |

## 🛡️ Safety Features

- **Automatic backups** before any changes
- **Conflict detection** and resolution
- **Rollback capability** if something goes wrong
- **Validation** of configuration files

## 🔄 Auto-Sync

Set up automatic syncing:
```bash
# Enable auto-sync every hour
./setup-auto-sync.sh hourly

# Or sync on Cursor startup
./setup-auto-sync.sh startup
```

## 📱 Multi-Machine Sync

1. **Machine A**: Run `./capture.sh` to save config
2. **Machine B**: Run `./restore.sh` to get the same config
3. **Both machines**: Use `./sync.sh` to keep in sync

## 🚨 Troubleshooting

- **Check logs**: `./logs.sh` to view recent activity
- **Reset**: `./reset.sh` to start fresh
- **Manual backup**: `./backup-manual.sh` for emergency backups

## 📄 License

MIT License - feel free to modify and distribute!
