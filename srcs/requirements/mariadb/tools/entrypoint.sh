#!/bin/bash

set -e

DB_PASSWORD=$(cat /run/secrets/db_password)

if [ ! -d /run/mysqld ]; then
	echo "------ Create /run/mysqld directory for mariadb socket file ------"
	cd /run && mkdir mysqld
	echo "-->Changing /run/mysqld directory owner to mysql:mysql"
	chown -R mysql:mysql /run/mysqld
else
	echo "------ /run/mysqld directory for mariadb socket file already exists ------"
fi

if [ ! -d /var/lib/mysql/$DB_NAME ]; then
	echo "------Setting up MariaDB------"
	echo "-->Starting temporary mariadbd daemon in the background"
	exec mariadbd --user=mysql &
	until mariadb-admin ping; do
		sleep 1
	done

	echo "-->Setting up MariaDB wordpress database"
	mariadb -e "CREATE DATABASE $DB_NAME;"
	mariadb -e "CREATE USER '$DB_USER'@'%' IDENTIFIED BY '$DB_PASSWORD'"
	mariadb -e "GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'%'"

	echo "-->Shutting down temporary MariaDB daemon"
	mariadb-admin shutdown
else
	echo "------MariaDB already set up------"
fi

echo "------Starting MariaDBD daemon server------"
exec mariadbd --user=mysql

