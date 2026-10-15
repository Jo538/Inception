#!/bin/bash

set -e

DB_PASSWORD=$(cat /run/secrets/db_password)
WP_ADMIN_PASSWORD=$(cat /run/secrets/wp_admin_password)
WP_USER_PASSWORD=$(cat /run/secrets/wp_user_password)

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

if ! runuser -u www-data -- wp core is-installed --path=/var/www/wordpress/; then
	runuser -u www-data -- wp core install --path=/var/www/wordpress/ --url=$WP_URL "--title=$WP_TITLE" --admin_user=$WP_ADMIN_USER --admin_email=$WP_ADMIN_EMAIL "--admin_password=$WP_ADMIN_PASSWORD"
	runuser -u www-data -- wp user create --path=/var/www/wordpress/ $WP_OTHER_USER $WP_USER_EMAIL "--user_pass=$WP_USER_PASSWORD"
fi

echo "Starting PHP-FPM8.2"
exec php-fpm8.2 -F