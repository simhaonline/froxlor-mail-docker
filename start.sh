#!/bin/bash

# Set timezone
ln -snf "/usr/share/zoneinfo/${TZ}" etc/localtime
echo "${TZ}" > /etc/timezone

# Postifx needs a copy to resolve hostnames and domain names
cp /etc/resolv.conf /var/spool/postfix/etc/

# Get config files
r=()
r+=("$(find /etc -type f -name 'aliases')")
r+=("$(find /etc/postfix -type f -name '*.cf')")
r+=("$(find /etc/dovecot -type f -name '*.conf*')")
r+=("$(find /etc/cron.d -type f -name 'cleanup-*')")

# Replace environment vars
for d in "${r[@]}"
do
	for f in $d
	do
		# Replace only if not mounted as read-only
		if [ -w "$f" ]
		then
			t="$f.tmp"
			mv $f $t
			envsubst < $t > $f
			rm $t
		fi
	done
done

# Update root alias
newaliases

# For mail log, but without capabilities
syslog-ng --no-caps

# To cleanup SPAM and Trash
cron

dovecot

# Delay to prevent SASL authentication method error
sleep 5

postfix start

# Keep container running and show mail log
tail -f /var/log/mail.log
