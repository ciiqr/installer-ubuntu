
# Get machine file...
machine_file="`debconf-get preseed/file`"
machine="`basename $machine_file`"
# Remove prefix and suffix on the filename
machine="${machine#preseed-}"
machine="${machine%.cfg}"

# Categories
case "$machine" in
	desktop) categories="base linux partition bootloader frontend linux-frontend sublime quick-launch personal development desktop";;
	laptop) categories="base linux partition bootloader frontend linux-frontend sublime quick-launch personal development hidpi c51 laptop";;
	server-data) categories="base linux partition bootloader server personal server-data";;
	*)
		echo "Unknown machine: $machine"
		echo "Must add this machine to the scripts..."
		false
		;;
esac

# machine name
case "$machine" in
	desktop) config_machine="desktop-william";;
	laptop) config_machine="laptop-william";;
	server-data) config_machine="server-data";;
	*)
		echo "Unknown machine: $machine"
		echo "Must add this machine to the scripts..."
		false
		;;
esac

unset machine_file
unset machine
