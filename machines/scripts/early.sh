#!/usr/bin/env sh

echo "===================== ran early.sh ====================="

# Get the list of categories
. /cdrom/scripts/inc/setup-categories.sh

# Run any category specific early scripts
for category in $categories; do
	category_script_path="/cdrom/scripts/early-$category.sh"
	[ -f "$category_script_path" ] && sh "$category_script_path"
done || true
