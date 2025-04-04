# mackeys2

This project is a fork of https://github.com/petrstepanov/gnome-macos-remap-wayland and supersedes https://github.com/davidkellis/mackeys.

This set of keybindings is built upon [Xremap](https://github.com/k0kubun/xremap) and works with Wayland and Xorg.

## Prerequisites

- git
- ability to install gnome extensions
  - Ubuntu 24.04 - `sudo apt install gnome-browser-connector`


## Installation
1. Make sure you are running **Wayland** display server. Logout from your session. On the GNOME login screen click ⚙ icon on the bottom right. Select `GNOME` (defaults to Wayland). Log in.
2. Check out this repository run `install.sh` script in Terminal. Script will ask for administrator password.

```
cd ~/Downloads
git clone https://github.com/davidkellis/mackeys2
cd mackeys2
chmod +x ./install.sh
./install.sh
```

3. Install and enable [the Xremap GNOME extension](https://extensions.gnome.org/extension/5060/xremap/).
4. Restart your computer.


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
