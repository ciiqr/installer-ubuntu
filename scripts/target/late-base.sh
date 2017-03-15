#!/usr/bin/env bash

categories="$1"
passwd_username="$2"

# this didn't like me when doing it in the below
if [[ -d "/data/private-config" ]]; then
	dotfiles_priv_conf_arg="--private-config ~/.private-config"
fi

su "$passwd_username" <<EOF

# Just in case...
mkdir -p ~/.config

cp /data/profile ~/.profile

if [[ -d "/data/private-config" ]]; then
	cp -r /data/private-config ~/.private-config
fi

# Install dotfiles
git clone https://github.com/ciiqr/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./install.sh --categories "$categories" --no-auto-categories $dotfiles_priv_conf_arg

# TODO: Maybe handle this better... or even from within install.sh itself... (Maybe put in backup...)
echo './install.sh --categories "$categories" --no-auto-categories $dotfiles_priv_conf_arg' > ~/.rerun-dotfiles.sh

EOF
