#!/bin/bash

if [ $# -eq 0 ]; then
    echo "ERROR: Please provide backup directory path"
    echo "Usage: $0 <backup_directory>"
    exit 1
fi

BACKUP_DIR=$1

if [ ! -d "$BACKUP_DIR" ]; then
    echo "ERROR: Backup directory $BACKUP_DIR does not exist"
    exit 1
fi

echo "INFO: Restoring configuration from $BACKUP_DIR"

# Restore config.yml if backup exists
if [ -f "$BACKUP_DIR/config.yml.backup" ]; then
    cp "$BACKUP_DIR/config.yml.backup" ~/.config/mackeys/config.yml
    echo "INFO: Restored config.yml"
fi

# Restore GNOME settings from backup files
# Note: This is a simplified restore - in practice you might want to parse the backup files
# and apply specific settings rather than trying to restore everything

echo "INFO: Please manually review and restore GNOME settings from:"
echo "      $BACKUP_DIR/wm-keybindings.txt"
echo "      $BACKUP_DIR/shell-keybindings.txt"
echo "      $BACKUP_DIR/mutter-settings.txt"
echo "      $BACKUP_DIR/input-sources.txt"
echo "      $BACKUP_DIR/media-keys.txt"
echo "      $BACKUP_DIR/terminal-keybindings.txt"

echo "INFO: Configuration restore completed"
