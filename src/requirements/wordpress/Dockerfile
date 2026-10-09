FROM debian:bookworm
RUN apt-get update && apt-get install -y php-fpm curl
RUN curl -o /tmp/wordpress.tar.gz https://wordpress.org/latest.tar.gz
RUN mkdir -p /var/www && tar -xzf /tmp/wordpress.tar.gz -C /var/www
COPY conf/www.conf /etc/php/8.2/fpm/pool.d/www.conf
RUN chown -R www-data:www-data /var/www/wordpress
EXPOSE 9000
CMD ["php-fpm8.2", "-F"]