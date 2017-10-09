#! /bin/bash
ls -1 /var/cpanel/users | while read user; do
pass=`strings /dev/urandom | tr -dc .~?_A-Za-z0-9 | head -c16 | xargs`
echo “$user $pass” >> new-pass.txt
/scripts/realchpass $user $pass
/scripts/ftpupdate # (this will update ftp passwords as well)
done
