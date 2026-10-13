FROM debian:bookworm
RUN apt-get update && apt-get install -y mariadb-server
COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh
EXPOSE 3306
CMD ["/usr/local/bin/entrypoint.sh"]
