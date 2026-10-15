FROM debian:bookworm
RUN apt-get update && apt-get install -y mariadb-server
EXPOSE 3306
COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh
COPY conf/51-bind-address.cnf /etc/mysql/mariadb.conf.d/51-bind-address.cnf
CMD ["/usr/local/bin/entrypoint.sh"]
