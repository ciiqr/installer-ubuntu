#!/usr/bin/env bash

. /scripts/inc/apt.sh
. /scripts/inc/common.sh

categories="$1"
source_priv_conf priv_conf categories

# sshd
install openssh-server
# TODO: Maybe just provide the sshd_config file as part of the iso...
# Change sshd configuration
# TODO: priv_conf: Port... or just don't change it...
replace_or_append /etc/ssh/sshd_config '[# ]*Port' 'Port 57251'
# TODO: Consider: enable only internal network by password
# PasswordAuthentication no
# ChallengeResponseAuthentication no
# Match Address 10.0.0.0/8,172.16.0.0/12,192.168.0.0/16
#     PasswordAuthentication yes

# ddclient (if the config exists when installed, it won't prompt for all the dumb options we don't care about)
# Replace the different options in the ddclient.conf and copy to the target location
# TODO: Split this onto multiple lines with a variable & +=
sed 's/REPLACE_CF_ZONE/'"${priv_conf[ddclient_cf_zone]}"'/;s/REPLACE_CF_LOGIN/'"${priv_conf[ddclient_cf_login]}"'/;s/REPLACE_CF_PASSWORD/'"${priv_conf[ddclient_cf_password]}"'/;s/REPLACE_CF_DOMAIN/'"${priv_conf[ddclient_cf_domain]}"'/' /data/ddclient.conf > /etc/ddclient.conf

install ddclient libio-socket-ssl-perl libjson-any-perl

# TODO: Install: fail2ban
# https://www.digitalocean.com/community/tutorials/how-to-protect-ssh-with-fail2ban-on-ubuntu-14-04

# TODO: Install: logrotate
# https://www.digitalocean.com/community/tutorials/how-to-manage-log-files-with-logrotate-on-ubuntu-12-10

# TODO: Install ufw
# https://www.digitalocean.com/community/tutorials/additional-recommended-steps-for-new-ubuntu-14-04-servers#configuring-a-basic-firewall
