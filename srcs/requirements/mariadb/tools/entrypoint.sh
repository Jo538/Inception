#!/bin/bash

set -e

DB_PASSWORD=$(cat /run/secrets/db_password)

if [ ! -d /var/lib/my_sql/wordpress ]; then
	echo "Setting up MariaDB"
	cd /run && mkdir mysqld
	cat > /run/mysqld/mysqld.sock
	chown -R mysql:mysql /run/mysqld

	exec mariadbd --user=mysql &
	until mariadb-admin ping; do
		sleep 1
	done
	mariadb -e "CREATE DATABASE wordpress;"
	mariadb -e "CREATE USER 'wpuser'@'%' IDENTIFIED BY '$DB_PASSWORD'"
	mariadb-admin shutdown
fi

exec mariadbd --user=mysql

