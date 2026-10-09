FROM debian:bookworm
RUN apt-get update && apt-get install -y nginx openssl
RUN openssl req -x509 -newkey rsa:2048 -nodes -keyout /etc/ssl/private/file.key -out /etc/ssl/certs/certificate.crt -days 365 -subj "/CN=jchartie.42.fr"
COPY index.html /var/www/html/index.html
COPY conf/default.conf /etc/nginx/conf.d/
EXPOSE 443
CMD ["nginx", "-g", "daemon off;"]