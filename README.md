
# Inception

## Description

Inception is a system administration project. The goal is to build a small web infrastructure inside a virtual machine using **Docker Compose**, where every service runs in its own container built from a hand-written Dockerfile.

The stack serves a WordPress website over HTTPS at `https://jchartie.42.fr`:

```
              host :443  (only entrypoint, TLSv1.2 / TLSv1.3)
                     │
                 ┌───▼───┐            docker network "inception"
                 │ nginx │────────────────────┐
                 └───┬───┘                    │
                     │ FastCGI :9000          │
            ┌────────▼─────────┐  SQL :3306 ┌─▼───────┐
            │ wordpress        │───────────▶│ mariadb │
            │ + php-fpm        │            └────┬────┘
            └────────┬─────────┘                 │
                     │                           │
        volume wordpress_data           volume mariadb_data
        /home/jchartie/data/wordpress   /home/jchartie/data/mariadb
```

### Use of Docker and sources included

Each service has its own folder under `srcs/requirements/<service>/` containing a `Dockerfile`, a `.dockerignore`, a `conf/` folder (configuration files copied into the image) and, when needed, a `tools/` folder (entrypoint scripts).

| Service     | Base image       | What it contains                                                                 | Key files |
|-------------|------------------|----------------------------------------------------------------------------------|-----------|
| `nginx`     | `debian:bookworm`| NGINX + OpenSSL. Terminates TLS, serves static files, forwards `*.php` to PHP-FPM. | `conf/default.conf` |
| `wordpress` | `debian:bookworm`| PHP-FPM 8.2, the PHP MySQL extension and WP-CLI. No web server.                   | `conf/www.conf`, `tools/script.sh` |
| `mariadb`   | `debian:bookworm`| MariaDB server only.                                                            | `conf/51-bind-address.cnf`, `tools/entrypoint.sh` |

Other files:

- `Makefile` — builds and runs everything through `srcs/docker-compose.yml`.
- `srcs/docker-compose.yml` — declares the three services, the `inception` network, the two named volumes and the secrets.
- `srcs/.env` — non-confidential configuration (domain/URL, site title, user names, e-mails, DB name and user). Not committed; `srcs/.env.example` is the template.
- `secrets/` — one file per password, mounted into containers as Docker secrets. Not committed.

### Main design choices

- **Debian Bookworm** as the base image: it is the penultimate stable Debian release, and its packages (`nginx`, `php-fpm`, `mariadb-server`) are available directly from the official repositories.
- **The daemon is PID 1.** Each container starts the real service in the foreground (`nginx -g "daemon off;"`, `php-fpm8.2 -F`, `mariadbd`), and entrypoint scripts end with `exec` so the shell is replaced by the daemon. No `tail -f`, `sleep infinity` or loops.
- **First-boot setup.** The MariaDB and WordPress scripts check whether the data already exists on their volume (database directory, `index.php`, `wp-config.php`, `wp core is-installed`). Setup only runs when it is missing, so restarting the stack never reinstalls anything.
- **WP-CLI** is used to generate `wp-config.php`, install WordPress and create the two users (one administrator, one regular user) without going through the web installer.
- **Start-up order.** MariaDB has a healthcheck (`mariadb-admin ping`) and WordPress waits for it with `depends_on: condition: service_healthy`, so WordPress never tries to connect to a database that isn't ready.
- **TLS.** A self-signed certificate for `jchartie.42.fr` is generated when the NGINX image is built, and NGINX only accepts `TLSv1.2` and `TLSv1.3`. Port 443 is the only port published on the host.
- **Restart policy.** Every service uses `restart: on-failure`, so a crashed container is restarted automatically.

### Virtual Machines vs Docker

A **virtual machine** emulates a whole computer: it runs its own full operating system with its own kernel on top of a hypervisor. It is strongly isolated but heavy: it takes gigabytes of disk and memory, and minutes to boot.

A **Docker container** is an isolated process running on the **host's kernel**. Linux namespaces give it its own view of processes, network and files, and cgroups limit its resources. Containers start in about a second and their images are a few hundred megabytes, but their isolation is weaker because they share the host's kernel.

In this project both are used together: the VM provides a clean Linux machine, and Docker runs each service inside it in its own container.

### Secrets vs Environment Variables

**Environment variables** (here passed from `srcs/.env`) are easy to use, but they are visible to anyone who can run `docker inspect`, they are inherited by every child process, and they often end up in logs. They are fine for non-confidential settings such as the domain name or a user name.

**Docker secrets** are files mounted read-only at `/run/secrets/<name>` inside only the containers that declare them. They don't appear in `docker inspect` or in the image layers. In this project every password (`db_password`, `wp_admin_password`, `wp_user_password`) is a secret and is read by the entrypoint scripts with `cat /run/secrets/...`. Everything else is an environment variable.

### Docker Network vs Host Network

With **host networking** (`network_mode: host`), a container shares the host's network stack: every port it opens is opened on the host, and there is no isolation between services. It is forbidden by the subject.

With a user-defined **Docker bridge network** (here `inception`), containers get their own private network. Docker provides a built-in DNS, so a container can reach another one by its service name (`wordpress:9000`, `mariadb:3306`). Nothing is reachable from outside unless it is explicitly published. Here only NGINX publishes a port (`443`), so MariaDB and PHP-FPM are only reachable from inside the network.

### Docker Volumes vs Bind Mounts

A **bind mount** maps an existing host path directly into a container. It depends on the host's directory layout, and Docker does not manage it (`docker volume ls` doesn't list it).

A **named volume** is a storage object created and managed by Docker: it has a name, it is listed and inspected with `docker volume` commands, and it is removed with `docker compose down -v`. The subject requires named volumes for the database and the WordPress files. To also store their data under `/home/jchartie/data` on the host, both volumes use the `local` driver with `driver_opts` (`type: none`, `o: bind`, `device: /home/jchartie/data/...`): they are still named volumes managed by Docker, but their data lives in the required folder.

## Instructions

### Prerequisites

- A Linux virtual machine with Docker Engine, the Docker Compose plugin and `make`.
- `jchartie.42.fr` pointing to the local IP, e.g. in `/etc/hosts`:
  ```
  127.0.0.1   jchartie.42.fr
  ```

### Configuration

1. Copy `srcs/.env.example` to `srcs/.env` and fill in the values. The administrator user name must not contain `admin` / `administrator`.
2. Create the `secrets/` folder at the repository root with one password per file:
   ```
   secrets/db_password.txt
   secrets/wp_admin_password.txt
   secrets/wp_user_password.txt
   ```

To generate a random password made of hexadecimal characters, you can use the command:

````
openssl rand -hex 32
````

### Running

```
make            # create data folders, build images, start the stack in the background
make stop       # stop containers without removing them
make start      # restart stopped containers
make down       # stop and remove containers and network (data is kept)
make strict_down  # remove containers, images, volumes AND the data on the host
```

Then open `https://jchartie.42.fr` (accept the self-signed certificate warning). The administration panel is at `https://jchartie.42.fr/wp-admin`.

See [USER_DOC.md](USER_DOC.md) for day-to-day usage and [DEV_DOC.md](DEV_DOC.md) for setting up and working on the project.

## Resources

### References

- [Docker documentation](https://docs.docker.com/) — Dockerfile reference, Compose file reference, networking, volumes, secrets
- [Dockerfile best practices](https://docs.docker.com/build/building/best-practices/)
- [Docker Compose — secrets](https://docs.docker.com/compose/how-tos/use-secrets/)
- [NGINX documentation](https://nginx.org/en/docs/) — `ngx_http_ssl_module`, `ngx_http_fastcgi_module`
- [PHP-FPM configuration](https://www.php.net/manual/en/install.fpm.configuration.php)
- [WP-CLI commands](https://developer.wordpress.org/cli/commands/) — `wp config create`, `wp core install`, `wp user create`
- [MariaDB Knowledge Base](https://mariadb.com/kb/en/) — `CREATE USER`, `GRANT`, server system variables (`bind-address`)
- [Debian releases](https://www.debian.org/releases/)
- `man openssl-req`, `man 5 hosts`

### Use of AI

AI was used to help write the documentation files: REAMDME.md, USER_DOC.md, DEV_DOC.md.
