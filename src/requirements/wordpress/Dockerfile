FROM debian:bookworm
RUN apt-get update && apt-get install -y php-fpm curl
RUN curl -o /tmp/wordpress.tar.gz https://wordpress.org/latest.tar.gz 
EXPOSE 9000
CMD ["nginx", "-g", "daemon off;"]