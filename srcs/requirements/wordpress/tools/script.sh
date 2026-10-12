#!/bin/bash

set -e

if [ ! -f /var/www/wordpress/index.php ]; then
	echo "Installing WordPress"
	curl -fsSL -o /tmp/wordpress.tar.gz https://wordpress.org/latest.tar.gz
	mkdir -p /var/www && tar -xzf /tmp/wordpress.tar.gz -C /var/www
	chown -R www-data:www-data /var/www/wordpress/
	rm -f /tmp/wordpress.tar.gz
else 
	echo "WordPress already installed"
fi

echo "Starting PHP-FPM8.2"
exec php-fpm8.2 -F