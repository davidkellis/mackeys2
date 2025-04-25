#!/usr/bin/env bash

set -e

# install OS upgrades
sudo apt update
sudo apt upgrade -y
sudo apt dist-upgrade -y
sudo apt autoremove -y
sudo apt autoclean -y

if [ ! -f "$HOME/restore1phase1.txt" ]; then
  touch $HOME/restore1phase1.txt
  echo "reboot phase 1"
  sudo reboot
  exit 0
fi

# Check if a reboot is required by apt and reboot if necessary
if [ -f /var/run/reboot-required ]; then
  echo "Reboot required by OS updates. Rebooting..."
  sudo reboot
  exit 0
fi

if [ ! -f "$HOME/restore1phase2.txt" ]; then
  touch $HOME/restore1phase2.txt

  echo "Installing mackeys2"

  sudo apt install build-essential vim curl git -y

  # gnome software extensions so that mackeys2 will work
  sudo apt install gnome-browser-connector -y

  # install homebrew
  echo "Installing homebrew"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  echo >> /home/david/.bashrc
  echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> /home/david/.bashrc
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

  # install mackeys2
  cd ~/Downloads
  
  git clone https://github.com/xremap/xremap-gnome ~/.local/share/gnome-shell/extensions/xremap@k0kubun.com
  # Reload your GNOME Shell session, and then enable "Xremap" using:
  gnome-extensions-app
  
  git clone https://github.com/davidkellis/mackeys2.git
  cd mackeys2
  chmod +x ./install.sh
  echo "installing mackeys2 with the install.sh script. this may fail early due to the service not being able to start, so you should reboot before proceeding"
  ./install.sh
  #cd ..
  #rm -rf mackeys2
  cd $HOME
  

  # restart mackeys
  systemctl --user restart mackeys; systemctl --user status mackeys

  echo "manually install https://extensions.gnome.org/extension/5282/alttab-scroll-workaround/"
  echo "then run this script again"
  exit 0
fi

if [ ! -f "$HOME/restore1phase3.txt" ]; then
  touch $HOME/restore1phase3.txt

  cd $HOME

  # install autorestic
  brew install restic autorestic

  # restore from backup if needed
  if [ ! -d "$HOME/sync" ]; then

    # restore from backup
    cat <<EOF > $HOME/.autorestic.yml
global:
  forget:
    keep-last: 5 # always keep at least 5 snapshots
    # keep-hourly: 3 # keep 3 last hourly snapshots
    # keep-daily: 4 # keep 4 last daily snapshots
    # keep-weekly: 1 # keep 1 last weekly snapshots
    keep-monthly: 12 # keep 12 last monthly snapshots
    # keep-yearly: 7 # keep 7 last yearly snapshots
    # keep-within: '14d' # keep snapshots from the last 14 days
backends:
  synology:
    type: sftp
    path: david@synology.locallan.network:/david/backup/restic/davidlinux
    key: 7qJkBpICLDgm2rSsHGRaLehW2b9Dzdx7qGjTYVg2oI9gxxaDMjY4PqkhjIIJYHGAS5fwYb0fk6WrwHx9tvaUWA
    env: {}
    rest:
      user: ""
      password: ""
    options: {}
locations:
  sync:
    from: sync
    to: synology
version: 2
EOF

    autorestic restore -l sync --to syncrestore


    mv syncrestore/home/david/sync/ .
    rmdir syncrestore

    ln -s sync/applications/ Applications
    rmdir Documents
    ln -s sync/documents/ Documents
    rm -rf Downloads
    ln -s sync/downloads/ Downloads
    rmdir Music
    ln -s sync/music/ Music
    rmdir Pictures
    ln -s sync/pictures/ Pictures
    rmdir Videos
    ln -s sync/videos/ Videos
    rm .autorestic.yml
    ln -s sync/dotfiles/.autorestic.yml
    rm -rf .bashrc
    ln -s sync/dotfiles/.bashrc
    ln -s sync/dotfiles/.gitconfig
    rm -rf .profile
    ln -s sync/dotfiles/.profile
    ln -s sync/.secrets/
    rm -rf .ssh
    ln -s sync/.ssh/
    rm -rf .zprofile
    ln -s sync/dotfiles/.zprofile
    rm -rf .zshrc
    ln -s sync/dotfiles/.zshrc
  fi

  # install zsh and make it the default shell
  sudo apt install zsh -y
  chsh -s $(which zsh)

  echo "reboot phase 3"
  sudo reboot
  exit 0
fi


if [ ! -f "$HOME/restore1phase4.txt" ]; then
  touch $HOME/restore1phase4.txt

  # install flatpak
  sudo apt install libfuse2 -y
  sudo apt install flatpak -y
  flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
  flatpak update -y

  sudo apt install gnome-software-plugin-flatpak -y

  # install refind as boot manager
  # sudo apt install refind -y

  # install appimaged per https://github.com/probonopd/go-appimage/blob/master/src/appimaged/README.md
  # Clear cache
  rm "$HOME"/.local/share/applications/appimage*
  # Download
  mkdir -p $HOME/Applications
  wget -c https://github.com/$(wget -q https://github.com/probonopd/go-appimage/releases/expanded_assets/continuous -O - | grep "appimaged-.*-x86_64.AppImage" | head -n 1 | cut -d '"' -f 2) -P $HOME/Applications/
  chmod +x $HOME/Applications/appimaged-*.AppImage
  # Launch
  $HOME/Applications/appimaged-*.AppImage

  # In ubuntu 24.04, appimage doesn’t work, so we have to do the following work-around
  # see https://github.com/electron/electron/issues/42510
  # see https://askubuntu.com/questions/1513001/why-am-i-getting-this-flatpak-error-ldconfig-failed-exit-status-256-with-ever
  # see https://bugs.launchpad.net/ubuntu/+source/apparmor/+bug/2064672
  sudo sysctl -w kernel.apparmor_restrict_unprivileged_unconfined=0
  sudo sysctl -w kernel.apparmor_restrict_unprivileged_userns=0

  # set hostname
  hostnamectl set-hostname davidlinux

  echo "reboot phase 4"
  sudo reboot
  exit 0
fi

if [ ! -f "$HOME/restore1phase5.txt" ]; then
  touch $HOME/restore1phase5.txt

  # install signal per https://signal.org/download/linux/
  # NOTE: These instructions only work for 64-bit Debian-based
  # Linux distributions such as Ubuntu, Mint etc.

  # 1. Install our official public software signing key:
  wget -O- https://updates.signal.org/desktop/apt/keys.asc | gpg --dearmor > signal-desktop-keyring.gpg
  cat signal-desktop-keyring.gpg | sudo tee /usr/share/keyrings/signal-desktop-keyring.gpg > /dev/null

  # 2. Add our repository to your list of repositories:
  echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/signal-desktop-keyring.gpg] https://updates.signal.org/desktop/apt xenial main' |\
    sudo tee /etc/apt/sources.list.d/signal-xenial.list

  # 3. Update your package database and install Signal:
  sudo apt update && sudo apt install signal-desktop



  # install brave browser
  curl -fsS https://dl.brave.com/install.sh | sh


  sudo apt install gnome-sushi -y
  sudo apt install copyq -y
  sudo apt install flameshot -y

  brew install mise

  brew install starship

  brew install zoxide

  echo "Install oh-my-zsh"
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

  brew install delta
  brew install ripgrep

  echo 'install rbw (bitwarden cli)'
  brew install pinentry
  brew install rbw
  rbw config set base_url https://vaultwarden.locallan.network
  rbw config set email david@conquerthelawn.com
  # rbw sync

  # install yq
  brew install yq

  # install jaq (yq clone)
  brew install jaq

  # install ripgrep
  brew install ripgrep

  # install rq
  cargo install record-query

  # install bat (better cat)
  brew install bat


  sudo apt install cifs-utils -y

  # synology SMB shares
  mkdir -p $HOME/mnt/synology_david
  mkdir -p $HOME/mnt/synology_multimedia
  sudo tee -a /etc/fstab <<EOF
//synology.locallan.network/david /home/david/mnt/synology_david cifs credentials=/home/david/.secrets/.smbcredentials,iocharset=utf8,uid=david,gid=david 0 0
//synology.locallan.network/multimedia /home/david/mnt/synology_multimedia cifs credentials=/home/david/.secrets/.smbcredentials,iocharset=utf8,uid=david,gid=david 0 0
EOF
  sudo mount -a
  sudo systemctl daemon-reload

  # set up usb rules for connecting to circuitpython board at /dev/ttyACM0
  # ❯ ls -al /dev/ttyACM*
  # crw-rw---- 1 root dialout 166, 0 Aug 20 22:02 /dev/ttyACM0
  sudo adduser david dialout	# add david user to dialout group

  echo "reboot phase 5"
  sudo reboot
  exit 0
fi

if [ ! -f "$HOME/restore1phase6.txt" ]; then
  touch $HOME/restore1phase6.txt

  echo "Select the Emoji tab -> Change Unicode code point keyboard shortcut to Control+Shift+u"
  ibus-setup

  echo "Download https://www.nerdfonts.com/font-downloads and unzip into $HOME/Downloads/FiraCode"
  sudo apt install font-manager -y
  font-manager -i $HOME/Downloads/FiraCode/*.ttf

fi

echo '- Log into Bitwarden CLI and sync'
echo '> rbw login'
echo '> rbw sync'

echo "- Set NVidia PRIME profile to Performance Mode to bump up refresh rate on external monitor"
echo 'Run NVIDIA X Server Settings -> Select the PRIME Profiles select list item -> Select the NVIDIA (Performance Mode) radio button -> Click Quit button'
