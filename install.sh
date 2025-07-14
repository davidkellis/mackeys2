#!/bin/bash

# Exit on any error
set -e

# Function to handle errors
error_handler() {
    echo "ERROR: An error occurred during installation."
    echo "Please check the error messages above and try again."
    exit 1
}

# Set error handler
trap error_handler ERR

# Function to check prerequisites
check_prerequisites() {
    echo "INFO: Checking prerequisites..."

    # Check for required commands
    local missing_commands=()

    if ! command -v curl &> /dev/null; then
        missing_commands+=("curl")
    fi

    if ! command -v wget &> /dev/null; then
        missing_commands+=("wget")
    fi

    if ! command -v unzip &> /dev/null; then
        missing_commands+=("unzip")
    fi

    if [ ${#missing_commands[@]} -ne 0 ]; then
        echo "ERROR: Missing required commands: ${missing_commands[*]}"
        echo "Please install them and try again."
        exit 1
    fi

    # Check for sudo access
    if ! sudo -n true 2>/dev/null; then
        echo "INFO: This script requires sudo access for some operations."
        echo "You may be prompted for your password."
    fi

    echo "INFO: Prerequisites check passed."
}

# Check prerequisites
check_prerequisites

# Create temporary install directory
BASE_DIR=`pwd`
mkdir -p ~/Downloads && cd ~/Downloads

# Check if this is a fresh install or update
FRESH_INSTALL=false
if [ ! -f ~/.config/mackeys/config.yml ] && [ ! -f ~/.local/share/systemd/user/mackeys.service ]; then
    FRESH_INSTALL=true
    echo "INFO: Fresh installation detected."
else
    echo "INFO: Existing installation detected. Running in update mode."
fi

# Backup current configuration before making changes (only if not fresh install)
if [ "$FRESH_INSTALL" = false ]; then
    echo "INFO: Backing up current configuration..."
    $BASE_DIR/backup-config.sh
else
    echo "INFO: Skipping backup for fresh installation."
fi

# Clean up any previous download artifacts
if [ -f ./xremap-linux-*.zip ] || [ -f ./xremap ]; then
    echo "INFO: Cleaning up previous download artifacts..."
    rm -rf ./xremap*
fi

# Detect architecture
ARCH=`uname -m`
echo "INFO: Detected ${ARCH} PC architecture."

# Exit if unsupported architecture
if [ "${ARCH}" != "x86_64" ] && [ "${ARCH}" != "aarch64" ]; then
  echo "ERROR: Unsupported architecture. Please compile and install Xremap manually:"
  echo "       https://github.com/k0kubun/xremap"
  exit 1
fi

# Detect compositor type (X11 or Wayland)
if [ "${XDG_SESSION_TYPE}" == "x11" ]; then
  echo "INFO: Detected X11 compositor."
  ARCHIVE_NAME="xremap-linux-${ARCH}-x11.zip"
elif [ "${XDG_SESSION_TYPE}" == "wayland" ]; then
  echo "INFO: Detected Wayland compositor."
  ARCHIVE_NAME="xremap-linux-${ARCH}-gnome.zip"
else
  echo "ERROR: Unsupported compositor."
  exit 1
fi

# Check current xremap version
CURRENT_VERSION=""
if which xremap > /dev/null 2>&1; then
  CURRENT_VERSION=$(xremap --version 2>/dev/null | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' || echo "")
  echo "INFO: xremap is already installed (version: $CURRENT_VERSION)"
fi

# Get latest version from GitHub
LATEST_VERSION=$(curl -s https://api.github.com/repos/xremap/xremap/releases/latest | grep '"tag_name"' | cut -d'"' -f4 | sed 's/v//')
echo "INFO: Latest available xremap version: $LATEST_VERSION"

# Ask user if they want to install/update xremap
if [ -n "$CURRENT_VERSION" ] && [ "$CURRENT_VERSION" = "$LATEST_VERSION" ]; then
  echo "INFO: xremap is already up to date (version $CURRENT_VERSION)."
  XREMAP_INSTALLED=true
else
  echo ""
  if [ -n "$CURRENT_VERSION" ]; then
    echo "Do you want to update xremap from version $CURRENT_VERSION to $LATEST_VERSION?"
  else
    echo "Do you want to install xremap version $LATEST_VERSION?"
  fi
  echo ""
  read -p "Install/update xremap? (Y/n): " -n 1 -r
  echo ""

  if [[ $REPLY =~ ^[Nn]$ ]]; then
    echo "INFO: Skipping xremap installation/update."
    if [ -z "$CURRENT_VERSION" ]; then
      echo "ERROR: xremap is required for mackeys2 to work. Please install it manually."
      exit 1
    else
      XREMAP_INSTALLED=true
    fi
  else
    # Download latest release from GitHub
    echo "INFO: Downloading xremap $LATEST_VERSION..."
    if wget -q --show-progress https://github.com/xremap/xremap/releases/latest/download/$ARCHIVE_NAME; then
      # Extract the archive
      echo "INFO: Extracting the archive..."
      if ! command -v unzip &> /dev/null; then
        echo "ERROR: Command \"unzip\" not found."
        exit 1
      fi
      unzip -o ./xremap-linux-${ARCH}-*.zip

      # Remove old binary (if any)
      if [ -f /usr/local/bin/xremap ]; then
          echo "INFO: Removing old binary..."
          sudo rm -rf /usr/local/bin/xremap
      fi

      # Install new binary
      echo "INFO: Installing the binary..."
      sudo cp ./xremap /usr/local/bin
      sudo chmod +x /usr/local/bin/xremap

      echo "INFO: xremap $LATEST_VERSION installed successfully."
      XREMAP_INSTALLED=true
    else
      echo "ERROR: Failed to download xremap. Please check your internet connection."
      exit 1
    fi
  fi
fi

# Tweaking server access control for X11 (only if xremap is installed)
# https://github.com/k0kubun/xremap#x11
if [ "${XDG_SESSION_TYPE}" == "x11" ] && [ "$XREMAP_INSTALLED" = true ]; then
  echo "INFO: Setting up X11 access control..."
  xhost +SI:localuser:root
fi

# Copy Xremap config file with macOS bindings (only if it doesn't exist)
CONFIG_DIR=~/.config/mackeys/
echo "INFO: Setting up xremap config file..."
mkdir -p $CONFIG_DIR
if [ ! -f $CONFIG_DIR/config.yml ]; then
    echo "INFO: No existing config found, copying default config..."
    cp $BASE_DIR/config.yml $CONFIG_DIR
    echo "INFO: Default config copied to $CONFIG_DIR/config.yml"
else
    echo "INFO: Existing config found at $CONFIG_DIR/config.yml"
    echo "INFO: Your local configuration is preserved."
    echo "INFO: To update to the latest config template, manually copy:"
    echo "      cp $BASE_DIR/config.yml $CONFIG_DIR/config.yml.new"
    echo "      # Then review and merge changes as needed"
fi

# Check if systemd service is already installed
SERVICE_DIR=~/.local/share/systemd/user/
SERVICE_INSTALLED=false
if [ -f $SERVICE_DIR/mackeys.service ]; then
    SERVICE_INSTALLED=true
    echo "INFO: Systemd service is already installed."
fi

# Ask user if they want to install/update systemd service
if [ "$SERVICE_INSTALLED" = true ]; then
    echo ""
    echo "Do you want to update the existing mackeys2 systemd service?"
    echo "This will replace the current service file with the latest version."
    echo ""
    read -p "Update systemd service? (y/N): " -n 1 -r
    echo ""

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        UPDATE_SERVICE=true
    else
        echo "INFO: Keeping existing systemd service."
        UPDATE_SERVICE=false
    fi
else
    echo ""
    echo "Do you want to install the mackeys2 systemd service for automatic startup?"
    echo "This will enable mackeys2 to start automatically when you log in."
    echo ""
    read -p "Install systemd service? (Y/n): " -n 1 -r
    echo ""

    if [[ $REPLY =~ ^[Nn]$ ]]; then
        echo "INFO: Skipping systemd service installation."
        echo "INFO: You can manually start mackeys2 with: xremap ~/.config/mackeys/config.yml"
        UPDATE_SERVICE=false
    else
        UPDATE_SERVICE=true
    fi
fi

if [ "$UPDATE_SERVICE" = true ]; then
    # Copy systemd service file
    echo "INFO: Installing/updating systemd service..."
    mkdir -p $SERVICE_DIR
    cp $BASE_DIR/mackeys.service $SERVICE_DIR

    # Copy bash scripts
    BIN_DIR=~/.local/bin/
    echo "INFO: Copying bash scripts..."
    mkdir -p $BIN_DIR
    cp $BASE_DIR/bin/*.sh $BIN_DIR
    chmod +x $BIN_DIR/*.sh

    # Run Xremap without sudo (only if not already done)
    # https://github.com/xremap/xremap?tab=readme-ov-file#running-xremap-without-sudo
    if ! groups $USER | grep -q input; then
        echo "INFO: Adding user to input group..."
        sudo gpasswd -a ${USER} input
    else
        echo "INFO: User already in input group."
    fi

    if [ ! -f /etc/udev/rules.d/input.rules ]; then
        echo "INFO: Creating udev rules..."
        echo 'KERNEL=="uinput", GROUP="input", TAG+="uaccess"' | sudo tee /etc/udev/rules.d/input.rules
    else
        echo "INFO: Udev rules already exist."
    fi

    # Instantiate the service
    systemctl --user daemon-reload
    systemctl --user enable mackeys

    # Only start if not already running
    if ! systemctl --user is-active --quiet mackeys; then
        systemctl --user start mackeys
        echo "INFO: Systemd service started successfully."
    else
        echo "INFO: Systemd service is already running."
    fi

    echo "INFO: Systemd service installation/update completed."
fi

# Check if GNOME settings have been previously applied
GNOME_SETTINGS_APPLIED=false
if [ -f ~/.config/mackeys/.gnome_settings_applied ]; then
    GNOME_SETTINGS_APPLIED=true
    echo "INFO: GNOME settings have been previously applied."
fi

# Ask user if they want to apply GNOME keyboard shortcut changes
if [ "$GNOME_SETTINGS_APPLIED" = true ]; then
    echo ""
    echo "Do you want to reapply GNOME keyboard shortcut changes?"
    echo "This will update your GNOME settings to match the current system configuration."
    echo "Your current settings have been backed up and can be restored later."
    echo ""
    read -p "Reapply GNOME keyboard shortcut changes? (y/N): " -n 1 -r
    echo ""
else
    echo ""
    echo "Do you want to apply GNOME keyboard shortcut changes to match the current system configuration?"
    echo "This will modify your GNOME settings to ensure compatibility with mackeys2."
    echo "Your current settings have been backed up and can be restored later."
    echo ""
    read -p "Apply GNOME keyboard shortcut changes? (y/N): " -n 1 -r
    echo ""
fi

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "INFO: Applying GNOME and Mutter keybindings to match current system..."

    # Ensure default system xkb-options are not turned on - may interfere
    gsettings reset org.gnome.desktop.input-sources xkb-options

    # Set overlay key to Super_L (current system setting)
    gsettings set org.gnome.mutter overlay-key 'Super_L'

    # Minimize window (current: Primary+Alt+KP_0)
    gsettings set org.gnome.desktop.wm.keybindings minimize "['<Primary><Alt>KP_0']"

    # Show desktop (current: empty array)
    gsettings set org.gnome.desktop.wm.keybindings show-desktop "[]"

    # Switch applications (current: Super+Tab, Alt+Tab)
    gsettings set org.gnome.desktop.wm.keybindings switch-applications "['<Super>Tab', '<Alt>Tab']"
    gsettings set org.gnome.desktop.wm.keybindings switch-applications-backward "['<Shift><Super>Tab', '<Shift><Alt>Tab']"

    # Switch group (current: Super+Above_Tab, Alt+Above_Tab)
    gsettings set org.gnome.desktop.wm.keybindings switch-group "['<Super>Above_Tab', '<Alt>Above_Tab']"
    gsettings set org.gnome.desktop.wm.keybindings switch-group-backward "['<Shift><Super>Above_Tab', '<Shift><Alt>Above_Tab']"

    # Switch workspaces (current: Super+Page_Up/Down, Super+Alt+Left/Right, Control+Alt+Left/Right)
    gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-left "['<Super>Page_Up', '<Super><Alt>Left', '<Control><Alt>Left']"
    gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-right "['<Super>Page_Down', '<Super><Alt>Right', '<Control><Alt>Right']"

    # Workspace 1 and last (current: Super+Home, Super+End)
    gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-1 "['<Super>Home']"
    gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-last "['<Super>End']"

    # Mutter tiling (current: Super+Left/Right)
    gsettings set org.gnome.mutter.keybindings toggle-tiled-left "['<Super>Left']"
    gsettings set org.gnome.mutter.keybindings toggle-tiled-right "['<Super>Right']"

    # Toggle message tray (current: Super+v, Super+m)
    gsettings set org.gnome.shell.keybindings toggle-message-tray "['<Super>v', '<Super>m']"

    # Toggle overview (current: empty array)
    gsettings set org.gnome.shell.keybindings toggle-overview "[]"

    # Toggle application view (current: Super+a)
    gsettings set org.gnome.shell.keybindings toggle-application-view "['<Super>a']"

    # Screenshots (current: Shift+Print, Print, Alt+Print)
    gsettings set org.gnome.shell.keybindings screenshot "['<Shift>Print']"
    gsettings set org.gnome.shell.keybindings show-screenshot-ui "['Print']"
    gsettings set org.gnome.shell.keybindings screenshot-window "['<Alt>Print']"

    # Screensaver (current: Super+l)
    gsettings set org.gnome.settings-daemon.plugins.media-keys screensaver "['<Super>l']"

    # Setting relocatable schema for Terminal (preserve current settings)
    if command -v gnome-terminal &> /dev/null ; then
        echo "INFO: Found GNOME Terminal. Preserving current keybindings..."
        # Current settings are already correct, no changes needed
    fi

    # Mark that GNOME settings have been applied
    touch ~/.config/mackeys/.gnome_settings_applied

    echo "INFO: GNOME keyboard shortcut changes applied successfully."
else
    echo "INFO: Skipping GNOME keyboard shortcut changes."
    echo "INFO: You may need to manually adjust some GNOME settings if you experience conflicts."
fi

# Restart is required in order for the changes in the `/usr/share/dbus-1/session.conf` to take place
# Therefore cannot launch service right away


# Final status and instructions
echo ""
echo "=== Installation Summary ==="
if [ "$XREMAP_INSTALLED" = true ]; then
    echo "✓ xremap: $(xremap --version 2>/dev/null || echo 'installed')"
else
    echo "✗ xremap: not installed"
fi

if [ "$UPDATE_SERVICE" = true ]; then
    if systemctl --user is-active --quiet mackeys; then
        echo "✓ mackeys2 service: running"
    else
        echo "⚠ mackeys2 service: installed but not running"
    fi
else
    echo "✗ mackeys2 service: not installed"
fi

if [ -f ~/.config/mackeys/config.yml ]; then
    echo "✓ config file: present"
else
    echo "✗ config file: missing"
fi

echo ""

# Download and enable Xremap GNOME extension (for Wayland only)
if [ "${XDG_SESSION_TYPE}" == "wayland" ]; then
  # Check if xremap extension is enabled
  if gnome-extensions list | grep -q "xremap@k0kubun.com"; then
    echo "INFO: The xremap extension is already enabled."
  else
    RED=`tput setaf 1`
    RESET=`tput sgr0`
    echo "INFO: ${RED}Action Required${RESET}. Install the xremap extension and restart your PC."
    echo "      https://extensions.gnome.org/extension/5060/xremap/"
  fi
else
  echo "INFO: Running on X11. The xremap GNOME extension is not required."
fi

echo ""
echo "Installation completed successfully!"
echo "You may need to restart your computer for all changes to take effect."

# Cleanup temporary files
echo "INFO: Cleaning up temporary files..."
cd ~/Downloads
rm -rf ./xremap*
cd $BASE_DIR
