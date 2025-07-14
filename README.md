# mackeys2

This project is a fork of https://github.com/petrstepanov/gnome-macos-remap-wayland and supersedes https://github.com/davidkellis/mackeys.

This set of keybindings is built upon [Xremap](https://github.com/k0kubun/xremap) and works with Wayland and Xorg.

## Prerequisites

- git
- ability to install gnome extensions
  - Ubuntu 24.04 - `sudo apt install gnome-browser-connector`


## Installation
1. Make sure you are running **Wayland** display server. Logout from your session. On the GNOME login screen click ⚙ icon on the bottom right. Select `GNOME` (defaults to Wayland). Log in.
2. Check out this repository and run the `install.sh` script in Terminal. The script will ask for administrator password and provide interactive options.

```
cd ~/Downloads
git clone https://github.com/davidkellis/mackeys2
cd mackeys2
chmod +x ./install.sh
./install.sh
```

The installation script is **idempotent** - it can be run multiple times safely. It will:
- Automatically detect if this is a fresh install or update
- Backup your current system configuration (only on updates)
- Check and install/update xremap to the latest version
- Install or update the systemd service for automatic startup
- Apply GNOME keyboard shortcut changes for compatibility
- Preserve your existing mackeys configuration
- Provide a summary of what was installed/updated

3. Install and enable [the Xremap GNOME extension](https://extensions.gnome.org/extension/5060/xremap/).
4. Restart your computer.

## Configuration Backup and Restore

The install script automatically backs up your current system configuration before making changes. This ensures your local settings are never lost.

### Manual Backup
To manually backup your current configuration:
```bash
./backup-config.sh
```

### Manual Restore
To restore from a backup:
```bash
./restore-config.sh <backup_directory>
```

Backup files are stored in `~/.config/mackeys/backup/` with timestamps.

## Running the Script Multiple Times

The install script is designed to be run multiple times safely:

- **Fresh Install**: If no previous installation is detected, it will install everything from scratch
- **Update Mode**: If an existing installation is found, it will:
  - Skip backup on fresh installs
  - Only update components that need updating
  - Preserve your existing configuration
  - Show what's already installed vs what needs updating

You can run `./install.sh` anytime to:
- Update xremap to the latest version
- Update the systemd service
- Reapply GNOME settings
- Check the status of your installation

## Manual Installation Options

If you prefer to install components manually or skip certain parts of the automated installation:

### Install xremap only
```bash
# Download and install latest xremap manually
ARCH=$(uname -m)
XDG_SESSION_TYPE=$(echo $XDG_SESSION_TYPE)
if [ "${XDG_SESSION_TYPE}" == "x11" ]; then
  ARCHIVE_NAME="xremap-linux-${ARCH}-x11.zip"
elif [ "${XDG_SESSION_TYPE}" == "wayland" ]; then
  ARCHIVE_NAME="xremap-linux-${ARCH}-gnome.zip"
fi
wget https://github.com/xremap/xremap/releases/latest/download/$ARCHIVE_NAME
unzip -o ./xremap-linux-${ARCH}-*.zip
sudo cp ./xremap /usr/local/bin
```

### Install systemd service only
```bash
# Copy service file and enable
mkdir -p ~/.local/share/systemd/user/
cp mackeys.service ~/.local/share/systemd/user/
systemctl --user daemon-reload
systemctl --user enable mackeys
systemctl --user start mackeys
```

### Manual startup (without systemd)
```bash
# Start mackeys2 manually
xremap ~/.config/mackeys/config.yml
```


## To revise key bindings
1. Edit `~/.config/mackeys/config.yml` in an editor and save changes
2. Run `systemctl --user restart mackeys; systemctl --user status mackeys`

For example:
```
❯ systemctl --user restart mackeys; systemctl --user status mackeys
● mackeys.service - mackeys2
     Loaded: loaded (/home/david/.local/share/systemd/user/mackeys.service; enabled; preset: enabled)
     Active: active (running) since Fri 2025-04-04 18:00:48 CDT; 3ms ago
   Main PID: 23977 (xremap)
      Tasks: 1 (limit: 76684)
     Memory: 752.0K (peak: 776.0K)
        CPU: 1ms
     CGroup: /user.slice/user-1000.slice/user@1000.service/app.slice/mackeys.service
             └─23977 xremap /home/david/.config/mackeys/config.yml --watch

Apr 04 18:00:48 davidlinux xremap[23977]: /dev/input/event25: HDA Intel PCH HDMI/DP,pcm=9
Apr 04 18:00:48 davidlinux xremap[23977]: /dev/input/event3 : Power Button
Apr 04 18:00:48 davidlinux xremap[23977]: /dev/input/event4 : Power Button
Apr 04 18:00:48 davidlinux xremap[23977]: /dev/input/event5 : AT Translated Set 2 keyboard
Apr 04 18:00:48 davidlinux xremap[23977]: /dev/input/event6 : PNP0C50:01 04F3:30D8 Mouse
Apr 04 18:00:48 davidlinux xremap[23977]: /dev/input/event7 : PNP0C50:01 04F3:30D8 Touchpad
Apr 04 18:00:48 davidlinux xremap[23977]: /dev/input/event8 : GIGABYTE USB-HID Keyboard
Apr 04 18:00:48 davidlinux xremap[23977]: /dev/input/event9 : GIGABYTE USB-HID Keyboard Mouse
Apr 04 18:00:48 davidlinux xremap[23977]: ------------------------------------------------------------------------------
Apr 04 18:00:48 davidlinux xremap[23977]: Selected keyboards automatically since --device options weren't specified:
```


## How to uninstall

1. If repository was removed, check it out again. Navigate into the program directory in Terminal and run:
```
cd ~/Downloads
git clone https://github.com/davidkellis/mackeys2
cd mackeys2
chmod +x ./uninstall.sh
./uninstall.sh
```

2. Restart your computer.

## Changelog

`2025-04-04` - Forked https://github.com/petrstepanov/gnome-macos-remap-wayland and improved macos key bindings
