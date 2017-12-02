#!/usr/bin/env bash

. /scripts/inc/apt.sh
. /scripts/inc/common.sh

categories="$1"
passwd_username="$2"

# Add Google Chrome repo
# TODO: This is causing issues, but idk where the other google-chrome repo stuff is coming from, so maybe find out before messing with this...
wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" | sudo tee -a /etc/apt/sources.list.d/google.list > /dev/null

# Add ppa's
# TODO: This isn't working on my desktop (need to change it to explicitly specify the xenial version of the repo...)
ppa klaus-vormweg/awesome
ppa webupd8team/sublime-text-3
ppa noobslab/icons
# TODO: if I care: ppa mozillateam/firefox-next (but we need to specify xenial...)

# Update new repos
sudo apt-get update


# Drivers
install ubuntu-drivers-common
# - Install the recommended driver packages (ie. nvidia, intel-microcode)
install `ubuntu-drivers list`


# xorg
install xorg

# terminals
install xterm
install rxvt-unicode


# Awesome
install awesome awesome-extra compton

# Lxdm
install lxdm

# Network Manager
install network-manager network-manager-gnome

# Redshift
install redshift-gtk

# Themes
install lxappearance
install numix-blue-gtk-theme
install oxygen-cursor-theme oxygen-cursor-theme-extra
# TODO: I've mainly used AwOken in the past, but this will do for now... also consider arc-icons
install linux-dark-icons


# Sublime
install sublime-text-installer

# Google Chrome
install google-chrome-stable

# Firefox
install firefox

# Deluge
install deluge

# Keepass
install keepass2 keepassx kpcli

# File viewers
install gpicview
install fbreader
install evince
install vlc
install libreoffice-writer libreoffice-calc

# Mount Samba Shares
install cifs-utils

# Dropbox
install nautilus-dropbox python-gpgme

# Fonts
install fonts-dejavu fonts-liberation ttf-mscorefonts-installer fonts-roboto fonts-symbola xfonts-terminus

# Pulse Audio
install pulseaudio pulseaudio-utils pavucontrol
# TODO: Do I really need to: usermod -aG pulse,pulse-access "$passwd_username"
# TODO: Consider installing rtkit

# xdg open
install xdg-utils libfile-mimeinfo-perl gvfs-bin

# X utilities
install feh
install xdotool
install wmctrl
install suckless-tools
install xbindkeys
install xcalib
install xkbset
install xkeycaps
install xsel
install xorg-xev


# Libinput
install libinput-tools libinput10 xserver-xorg-input-libinput


# Misc
install scrot
install graphicsmagick graphicsmagick-imagemagick-compat
install speedcrunch
install spacefm-gtk3 udisks2
install gparted
install gksu
install gcolor2
install baobab
install ntfs-3g
install zenity
install youtube-dl
install gucharmap
install leafpad
install nethogs
install rfkill
install iftop
install iotop
install pinta
install inotify-tools
install hardinfo
install powertop
install libnotify-bin
install bleachbit

# TODO: Still undecided
install seahorse


# Configure libinput
cp /data/61-libinput-options.conf /usr/share/X11/xorg.conf.d/61-libinput-options.conf

# TODO: Might also need this...
# .icons/default/index.theme
# 	# This file is written by LXAppearance. Do not edit.
# 	[Icon Theme]
# 	Name=Default
# 	Comment=Default Cursor Theme
# 	Inherits=oxy-obsidian-hc

# For Network Manager access
usermod -a -G "netdev" "$passwd_username"

su "$passwd_username" <<"EOF"

# Default applications
sh /scripts/default-applications.sh

# Configs
cp /data/user-dirs.dirs ~/.config/user-dirs.dirs
cp /data/compton.conf ~/.config/compton.conf
cp /data/redshift.conf ~/.config/redshift.conf

# Gtk
cp /data/gtk3.css ~/.config/gtk-3.0/gtk.css
cp /data/gtk3-settings.ini ~/.config/gtk-3.0/settings.ini
sed 's:REPLACE_USER_HOME:'"$HOME"':' /data/gtk2-settings.rc > ~/.gtkrc-2.0

# X Configs
cp /data/xinitrc ~/.xinitrc
chmod +x ~/.xinitrc
cp /data/xbindkeysrc ~/.xbindkeysrc
cp /data/Xmodmap ~/.Xmodmap
# TODO: ...
cp /data/xsession ~/.xsession
cp /data/xsessionrc ~/.xsessionrc
cp /data/Xresources ~/.Xresources
cat /data/Xresources-* >> ~/.Xresources

# TODO: Should probably rely on includes for hidpi xresources...
# #include ".Xresources.d/hidpi"

# Insert home directory when creating dmrc
sed 's:REPLACE_USER_HOME:'"$HOME"':' /data/dmrc > ~/.dmrc

# Install my awesome config
# TODO: This and dotfiles should be cloned with ssh OR cloned like this and changed to ssh after (if necessary)
git clone https://github.com/ciiqr/awesome.git ~/.config/awesome


# pa-server
mkdir -p ~/.config/systemd/user
sed 's:REPLACE_USER_HOME:'"$HOME"':' /data/pa-server.service > ~/.config/systemd/user/pa-server.service
cp /data/pa-server.py ~/.local/bin/pa-server.py
# TODO: Do I even need the reload in this case?...
systemctl --user daemon-reload
systemctl --user enable pa-server.service


EOF

# Spacefm
cp /data/spacefm-as-root "/etc/spacefm/${passwd_username}-as-root"

# sysctl
cp /data/sysctl.conf /etc/sysctl.d/100-sysctl.conf

# lxdm
# TODO: May want to provide the whole file eventually, but for now this is all I need...
if contains_option hidpi "$categories"; then
	LXDM_DPI="-dpi 192"
fi
# TODO: I probably want to pull the value of this from the file, then append my options (or if not in file provide defaults...) then append or replace with the comment remover
sed -i 's@[# ]*arg=\(.*\)@arg=\1 '"$LXDM_DPI"'@' /etc/lxdm/lxdm.conf


# logind.conf
replace_or_append /etc/systemd/logind.conf '[# ]*HandlePowerKey=' 'HandlePowerKey=hibernate'
replace_or_append /etc/systemd/logind.conf '[# ]*HandleLidSwitch=' 'HandleLidSwitch=ignore'
replace_or_append /etc/systemd/logind.conf '[# ]*IdleAction=' 'IdleAction=hybrid-sleep'
replace_or_append /etc/systemd/logind.conf '[# ]*IdleActionSec=' 'IdleActionSec=80min'
replace_or_append /etc/systemd/logind.conf '[# ]*HandleSuspendKey=' 'HandleSuspendKey=hybrid-sleep'



# pa-server
install python-pip python-wheel libpython-all-dev python-dbus
pip install --user procname
# for pa-server (and any other services I create for my user that need dbus...)
mkdir -p '/etc/systemd/system/user@.service.d/'
cp "/data/systemd-user@.service.d-dbus.conf" "/etc/systemd/system/user@.service.d/dbus.conf"
