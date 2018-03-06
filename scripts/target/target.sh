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
	echo "===================== run target early $category ====================="
	declare category_script_path="/scripts/early-$category.sh"
	[[ -f "$category_script_path" ]] && bash "$category_script_path" "$categories" "$passwd_username"
done || true

echo "===================== done target.sh ====================="
