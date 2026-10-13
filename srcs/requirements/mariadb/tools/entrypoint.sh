#!/bin/bash

set -e

if [ ! -d /var/lib/my_sql/wordpress ]; then
	echo "Setting up MariaDB"
	cd /run && mkdir mysqld
	cat > /run/mysqld/mysqld.sock
	chown -R mysql:mysql /run/mysqld
	exec mariadbd --user=mysql &

fi

