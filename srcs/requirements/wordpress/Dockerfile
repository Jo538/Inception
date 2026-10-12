FROM debian:bookworm
RUN apt-get update && apt-get install -y php-fpm curl
COPY conf/www.conf /etc/php/8.2/fpm/pool.d/www.conf
COPY tools/script.sh /usr/local/bin/script.sh
EXPOSE 9000
CMD ["/usr/local/bin/script.sh"]