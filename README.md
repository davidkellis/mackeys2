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
