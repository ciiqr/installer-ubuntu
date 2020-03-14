#!/usr/bin/env sh

echo "===================== ran late.sh ====================="

# Get the machine and user
. /cdrom/scripts/inc/user-input.sh

# move over config
data_path="/cdrom/data/config/."
if [ -d "$data_path" ]; then
    cp -rf "$data_path" "/target/config"
fi

# move over config-private
data_path="/cdrom/data/config-private/."
if [ -d "$data_path" ]; then
    cp -rf "$data_path" "/target/config-private"
fi

# install config
in-target bash /config/scripts/install --primaryUser "$primaryUser" --machine "$machine" --roles "$roles"
