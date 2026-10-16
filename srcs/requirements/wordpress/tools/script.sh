#!/bin/bash

set -e

DB_PASSWORD=$(cat /run/secrets/db_password)
WP_ADMIN_PASSWORD=$(cat /run/secrets/wp_admin_password)
WP_USER_PASSWORD=$(cat /run/secrets/wp_user_password)

if [ ! -f /var/www/wordpress/index.php ]; then
	echo "------Installing WordPress file system------"
	echo "--> Downloading WordPress file system compressed archive from the web"
	curl -fsSL -o /tmp/wordpress.tar.gz https://wordpress.org/latest.tar.gz
	echo "--> Extracting WordPress file system from local archive"
	mkdir -p /var/www && tar -xzf /tmp/wordpress.tar.gz -C /var/www
	echo "--> Change WordPress file system owner from root to www-data:www-data user and group"
	chown -R www-data:www-data /var/www/wordpress/
	rm -f /tmp/wordpress.tar.gz
else 
	echo "------WordPress file system already installed------"
fi

if [ ! -f /var/www/wordpress/wp-config.php ]; then
	echo "------Configuring wp-config.php file------"
	runuser -u www-data -- wp config create --path=/var/www/wordpress/ --dbname=$DB_NAME --dbuser=$DB_USER "--dbpass=$DB_PASSWORD" --dbhost=mariadb:3306
else
	echo "------wp-config.php file already configured------"
fi

if ! runuser -u www-data -- wp core is-installed --path=/var/www/wordpress/; then
	echo "------Parsing WordPress credentials to access MariaDB database------"
	runuser -u www-data -- wp core install --path=/var/www/wordpress/ --url=$WP_URL "--title=$WP_TITLE" --admin_user=$WP_ADMIN_USER --admin_email=$WP_ADMIN_EMAIL "--admin_password=$WP_ADMIN_PASSWORD"
	runuser -u www-data -- wp user create --path=/var/www/wordpress/ $WP_OTHER_USER $WP_USER_EMAIL "--user_pass=$WP_USER_PASSWORD"
else
	echo "------WordPress credentials to access MariaDB database already parsed------"
fi

echo "------Starting PHP-FPM8.2------"
exec php-fpm8.2 -F