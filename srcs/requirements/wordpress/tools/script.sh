#!/bin/bash

set -e

DB_PASSWORD=$(cat /run/secrets/db_password)

if [ ! -f /var/www/wordpress/index.php ]; then
	echo "Installing WordPress"
	curl -fsSL -o /tmp/wordpress.tar.gz https://wordpress.org/latest.tar.gz
	mkdir -p /var/www && tar -xzf /tmp/wordpress.tar.gz -C /var/www
	chown -R www-data:www-data /var/www/wordpress/
	rm -f /tmp/wordpress.tar.gz
else 
	echo "WordPress already installed"
fi

if [ ! -f /var/www/wordpress/wp-config.php ]; then
	until runuser -u www-data -- wp config create --path=/var/www/wordpress/ --dbname=wordpress --dbuser=wpuser "--dbpass=$DB_PASSWORD" --dbhost=mariadb:3306; do
		sleep 1
	done
fi

echo "Starting PHP-FPM8.2"
exec php-fpm8.2 -F