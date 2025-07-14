#!/bin/bash

# Backup current system configuration
BACKUP_DIR=~/.config/mackeys/backup/$(date +%Y%m%d_%H%M%S)
mkdir -p $BACKUP_DIR

echo "INFO: Backing up current system configuration to $BACKUP_DIR"

# Backup current config.yml if it exists
if [ -f ~/.config/mackeys/config.yml ]; then
    cp ~/.config/mackeys/config.yml $BACKUP_DIR/config.yml.backup
    echo "INFO: Backed up config.yml"
fi

# Backup current GNOME settings
echo "INFO: Backing up GNOME settings..."

# Window manager keybindings
gsettings list-recursively org.gnome.desktop.wm.keybindings > $BACKUP_DIR/wm-keybindings.txt

# Shell keybindings
gsettings list-recursively org.gnome.shell.keybindings > $BACKUP_DIR/shell-keybindings.txt

# Mutter settings
gsettings list-recursively org.gnome.mutter > $BACKUP_DIR/mutter-settings.txt

# Input sources
gsettings list-recursively org.gnome.desktop.input-sources > $BACKUP_DIR/input-sources.txt

# Media keys
gsettings list-recursively org.gnome.settings-daemon.plugins.media-keys > $BACKUP_DIR/media-keys.txt

# Terminal keybindings (if GNOME Terminal is installed)
if command -v gnome-terminal &> /dev/null ; then
    gsettings list-recursively org.gnome.Terminal.Legacy.Keybindings:/org/gnome/terminal/legacy/keybindings/ > $BACKUP_DIR/terminal-keybindings.txt
fi

# System info
echo "XDG_SESSION_TYPE=$XDG_SESSION_TYPE" > $BACKUP_DIR/system-info.txt
echo "ARCH=$(uname -m)" >> $BACKUP_DIR/system-info.txt
echo "xremap version: $(xremap --version 2>/dev/null || echo 'not installed')" >> $BACKUP_DIR/system-info.txt

echo "INFO: Configuration backup completed in $BACKUP_DIR"
echo "INFO: To restore, run: ./restore-config.sh $BACKUP_DIR"
