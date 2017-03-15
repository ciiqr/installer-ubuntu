#!/usr/bin/env bash

contains_option()
{
	echo "$2" | egrep -q '\b('"$1"')\b'
}

replace_or_append()
{
	match_line="$2"
	replace_line="$3"
	# TODO: I would like to be able to replace with some matched part... (untested)
	# TODO: May also be good to only replace the first match... if reasonable...
	sed -i '/^'"$match_line"'/{h;s/.*/'"$replace_line"'/};${x;/^$/{s//'"$replace_line"'/;H};x}' "$1"
}

source_priv_conf()
{
	declare priv_conf_dir='/data/private-config'
	[[ -d "$priv_conf_dir" ]] && . "$priv_conf_dir/config.sh" "$@"
}
