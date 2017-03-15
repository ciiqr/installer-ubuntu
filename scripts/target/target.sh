#!/usr/bin/env bash

echo "===================== ran target.sh ====================="

categories="$1"
passwd_username="$2"

# Prevent issues while installing software
unset DEBCONF_REDIR
unset DEBCONF_FRONTEND
unset DEBIAN_HAS_FRONTEND
unset DEBIAN_FRONTEND

# Update apt
apt-get update

# Run any category specific early scripts
for category in $categories; do
	category_script_path="/scripts/early-$category.sh"
	[ -f "$category_script_path" ] && bash "$category_script_path" "$categories" "$passwd_username"
done || true

# TODO: Maybe have a separate step for installing packages (between early and late) (and simply deplay all package installs from early-*sh)

# Run any category specific late scripts
for category in $categories; do
	category_script_path="/scripts/late-$category.sh"
	[ -f "$category_script_path" ] && bash "$category_script_path" "$categories" "$passwd_username"
done || true

# TODO: Install firstboot script... Need to pass along categories...
# http://www.50ply.com/blog/2012/07/16/automating-debian-installs-with-preseed-and-puppet/
# TODO: Maybe delete target /data within the firstboot script...

echo "===================== done target.sh ====================="
