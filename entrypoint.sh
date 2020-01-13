#!/bin/bash

echo ". /samba-config.sh /config"
. /samba-config.sh /config

#echo ">>> ALL_AFPD_TEXT"
#echo "$ALL_AFPD_TEXT"

echo "cp /smb.conf /etc/samba/smb.conf"
cp /smb.conf /etc/samba/smb.conf

echo "cp /afp.conf /etc/netatalk/afp.conf"
cp /afp.conf /etc/netatalk/afp.conf

echo "service smbd start"
service smbd start
echo "service nmbd start"
service nmbd start

echo ". /netatalk-config.sh"
. /netatalk-config.sh

# why did my container keep stopping although everything started ok?
J=1
while true; do
    echo "5-min heartbeats #""$J"
    sleep 5m
    J=$((J+1))
done
