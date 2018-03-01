#!/usr/bin/env bash

. /scripts/inc/apt.sh
. /scripts/inc/common.sh

categories="$1"
passwd_username="$2"
source_priv_conf priv_conf categories

# Get usernames
if [ ${priv_conf[@]+isset} ]; then
	deluge_username="`array_get_first_set priv_conf deluge_username common_username || echo "$passwd_username"`"
	samba_username="`array_get_first_set priv_conf samba_username common_username || echo "$passwd_username"`"
	nfs_username="`array_get_first_set priv_conf nfs_username common_username || echo "$passwd_username"`"
	dlna_username="`array_get_first_set priv_conf dlna_username common_username || echo "$passwd_username"`"
else
	deluge_username="$passwd_username"
	samba_username="$passwd_username"
	nfs_username="$passwd_username"
	dlna_username="$passwd_username"
fi

# Create group
common_group=media
groupadd -r "$common_group"

# Add users to group
unique_users="`echo -n "${deluge_username}\n${samba_username}\n${nfs_username}" | sort | uniq`"
for u in "$unique_users"; do
	usermod -a -G "$common_group" "$u"
done

# deluged (Based on http://www.havetheknowhow.com/Install-the-software/Install-Deluge-Headless.html)
# TODO: maybe I should check for sha1sum, then openssl (TODO: Create a function for it...)
if [ ${priv_conf[@]+isset} ]; then
	deluge_password="${priv_conf[deluge_password]}"
else
	deluge_password="password"
fi
deluge_localclient_password="`openssl rand -hex 20`"
deluge_user_password="$deluge_password"
deluge_web_pwd_salt="`openssl rand -hex 20`"
deluge_web_pwd_sha1="`openssl sha1 <(echo -n "${deluge_web_pwd_salt}${deluge_password}")`"
deluge_web_pwd_sha1="${deluge_web_pwd_sha1#*= }"

# Deluge - User
adduser --disabled-password --system --home /srv/deluge --gecos "Deluge service" --group deluge
usermod -a -G "$common_group" deluge

# Deluge - Log files
touch /var/log/deluged.log
touch /var/log/deluge-web.log
chown deluge:deluge /var/log/deluge*

# Deluge - Install
install deluged deluge-web

# Deluge - Allow python (and as such, deluge) to use port 80
find /usr/bin -name "python*" -type f -exec setcap 'cap_net_bind_service=+ep' {} \;

# Deluge - Service files
cp /data/deluge/deluged.service /data/deluge/deluged-web.service /etc/systemd/system/
systemctl enable deluged deluged-web

# Deluge - Configs
su -s /bin/bash --login deluge <<EOF

# Make config dir
mkdir -p ~/.config/deluge

# Generate auth file
cat > ~/.config/deluge/auth << EOL
localclient:$deluge_localclient_password:10
$deluge_username:$deluge_user_password:10
EOL

# Replace web.conf into deluge config dir
sed 's/REPLACE_PWD_SHA1/'"${deluge_web_pwd_sha1}"'/;s/REPLACE_PWD_SALT/'"${deluge_web_pwd_salt}"'/' /data/deluge/web.conf > ~/.config/deluge/web.conf

# Copy configs
cp /data/deluge/{core,label,scheduler}.conf ~/.config/deluge

EOF



# samba
install samba

if [ ${priv_conf[@]+isset} ]; then
	samba_password="${priv_conf[samba_password]}"
else
	samba_password="password"
fi

sed 's:REPLACE_SAMBA_USERNAME:'"$samba_username"':;s:REPLACE_SAMBA_GROUP:'"$common_group"':;' /data/smb.conf > /etc/samba/smb.conf
echo "${samba_password}\n${samba_password}" | smbpasswd -a -s "$samba_username"



# nfs
install nfs-kernel-server

nfs_uid="`id -u "$nfs_username"`"
nfs_gid="`getent group "$common_group" | cut -d: -f3`"
tee "/etc/exports" > /dev/null <<EOF

/srv  *(rw,async,all_squash,anonuid=$nfs_uid,anongid=$nfs_gid,subtree_check)

EOF



# dlna
install minidlna

replace_or_append /etc/default/minidlna '[# ]*USER=' 'USER="'"$dlna_username"'"'
replace_or_append /etc/default/minidlna '[# ]*GROUP=' 'GROUP="'"$common_group"'"'

dlna_user_home="`eval echo "~$dlna_username"`"
replace_or_append /etc/minidlna.conf '[# ]*db_dir=' 'db_dir='"`echo "$dlna_user_home"'/.config/minidlna/cache' | escape_for_sed`"
replace_or_append /etc/minidlna.conf '[# ]*log_dir=' 'log_dir='"`echo "$dlna_user_home"'/.config/minidlna' | escape_for_sed`"

sed -i 's:^media_dir=\(.*\):# media_dir=\1:' /etc/minidlna.conf
tee -a /etc/minidlna.conf > /dev/null <<EOF

media_dir=V,/srv/media/Movies
media_dir=V,/srv/media/Shows

media_dir=A,/srv/media/Music
media_dir=A,/srv/media/Sorted-Music
media_dir=A,/srv/media/UMusic

media_dir=/srv/deluge/Downloads
media_dir=/srv/deluge/Incomplete

EOF


# sysctl
cp /data/sysctl.conf /etc/sysctl.d/100-sysctl.conf
