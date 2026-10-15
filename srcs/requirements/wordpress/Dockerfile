FROM debian:bookworm
RUN apt-get update && apt-get install -y php-fpm php-mysql curl
RUN curl -fO https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && chmod +x wp-cli.phar && mv wp-cli.phar /usr/local/bin/wp
COPY conf/www.conf /etc/php/8.2/fpm/pool.d/www.conf
COPY tools/script.sh /usr/local/bin/script.sh
EXPOSE 9000
CMD ["/usr/local/bin/script.sh"]