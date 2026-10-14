#!/bin/bash

set -e

DB_PASSWORD=$(cat /run/secrets/db_password)

if [ ! -d /var/lib/mysql/wordpress ]; then
	echo "Setting up MariaDB"
	cd /run && mkdir mysqld
	chown -R mysql:mysql /run/mysqld

	exec mariadbd --user=mysql &
	until mariadb-admin ping; do
		sleep 1
	done
	mariadb -e "CREATE DATABASE wordpress;"
	mariadb -e "CREATE USER 'wpuser'@'%' IDENTIFIED BY '$DB_PASSWORD'"
	mariadb -e "GRANT ALL PRIVILEGES ON wordpress.* TO 'wpuser'@'%'"
	mariadb-admin shutdown
fi

exec mariadbd --user=mysql

