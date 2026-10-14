FROM debian:bookworm
RUN apt-get update && apt-get install -y mariadb-server
EXPOSE 3306
COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh
CMD ["/usr/local/bin/entrypoint.sh"]
