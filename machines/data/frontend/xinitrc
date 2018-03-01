#!/usr/bin/env bash

# xterm theme & possibly other things
[[ -f ~/.Xresources ]] && xrdb -merge ~/.Xresources

# Start PulseAudio
start-pulseaudio-x11 &

# Keybindings
xmodmap ~/.Xmodmap

# 
xbindkeys

# Key Repeat Rate
xset r rate 400 20

# Xdg-Open (NO More Firefox)
export DE=gnome

# ## Gnome-Keyring ##
# # Start GNOME Keyring
# eval $(/usr/bin/gnome-keyring-daemon --start --components=gpg,pkcs11,secrets,ssh)
# # You probably need to do this too
# export GNOME_KEYRING_CONTROL GNOME_KEYRING_PID GPG_AGENT_INFO SSH_AUTH_SOCK


exec awesome
