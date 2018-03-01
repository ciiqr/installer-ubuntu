#!/usr/bin/env sh

echo "===================== ran late.sh ====================="

# Get the list of categories
. /cdrom/scripts/inc/setup-categories.sh

# TODO: For now this is fine, but it would be nice if we had an easy way of sending any number of values... Maybe we simply want to generate a shell file with variable declarations, or even associative array assignments, then source it from target.sh
passwd_username="`debconf-get passwd/username`"

# Copy all (target) scripts to target
cp -r /cdrom/scripts/target /target/scripts

# Make all scripts executable (TODO: Likely unnecessary)
in-target chmod -R 0777 /scripts

# Copy data over... (all categories data folder get merged into 1, so you can override the category file of a previous category)
target_dir="/target/data"
mkdir -p "$target_dir"
for category in $categories; do
	category_data_path="/cdrom/data/$category/."
	if [ -d "$category_data_path" ]; then
		cp -rf "$category_data_path" "$target_dir"
	fi
done || true

# Run any category specific late scripts
for category in $categories; do
	category_script_path="/cdrom/scripts/late-$category.sh"
	[ -f "$category_script_path" ] && sh "$category_script_path"
done || true

# Run target late_command
in-target bash /scripts/target.sh "$categories" "$passwd_username"
