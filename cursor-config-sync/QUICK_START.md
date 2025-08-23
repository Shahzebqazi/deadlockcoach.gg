# 🚀 Quick Start Guide

Get your Cursor configuration syncing to GitHub in 5 minutes!

## ⚡ Super Quick Setup

```bash
# 1. Clone this repo
git clone https://github.com/yourusername/cursor-config-sync.git
cd cursor-config-sync

# 2. Run setup (configures GitHub automatically)
./setup.sh

# 3. Capture your current Cursor config
./capture.sh

# 4. Sync to GitHub
./sync.sh
```

## 🔄 What Happens Next

After setup, your Cursor configuration will automatically sync to GitHub whenever you:

- **Start Cursor** (if you chose startup sync)
- **Run `./capture.sh`** (manual capture)
- **Run `./sync.sh`** (manual sync)

## 🚀 After Reinstalling Cursor

```bash
# Clone your repo on the new machine
git clone https://github.com/yourusername/cursor-config-sync.git
cd cursor-config-sync

# Restore your configuration
./restore.sh
```

## 📱 Multi-Machine Sync

1. **Machine A**: Run `./capture.sh` and `./sync.sh`
2. **Machine B**: Run `git pull` then `./restore.sh`
3. **Both machines**: Stay in sync automatically!

## 🛠️ Key Commands

| Command | What it does |
|---------|-------------|
| `./setup.sh` | First-time configuration |
| `./capture.sh` | Save current Cursor config |
| `./sync.sh` | Push configs to GitHub |
| `./restore.sh` | Restore config from backup |
| `./sync.sh status` | Check sync status |

## 🆘 Need Help?

- **Demo**: `./demo.sh`
- **Workflow**: `./demo.sh workflow`
- **Examples**: `./demo.sh examples`
- **Troubleshooting**: `./demo.sh troubleshooting`

## 🔐 GitHub Setup Required

You'll need:
1. A GitHub account
2. A repository (created automatically or existing)
3. A Personal Access Token with `repo` scope

The setup script will guide you through all of this!

---

**That's it!** Your Cursor configuration is now safely backed up to GitHub and can be restored anywhere. 🎉
