# Developer documentation

This guide explains how to set up the project from scratch, build and run it, manage containers and volumes, and where the data is stored.

All commands are run from the root of the repository.

## 1. Set up the environment from scratch

### Prerequisites

- A Linux virtual machine (the project must run in a VM).
- **Docker Engine** and the **Docker Compose plugin** (`docker compose version` must work).
- **make**.
- Your user in the `docker` group, so Docker works without `sudo`:
  ```
  sudo usermod -aG docker $USER   # then log out and back in
  ```
- The domain pointing to the local machine. Add this line to `/etc/hosts`:
  ```
  127.0.0.1   jchartie.42.fr
  ```

### Project layout

```
.
├── Makefile
├── secrets/                     # passwords (git-ignored)
│   ├── db_password.txt
│   ├── wp_admin_password.txt
│   └── wp_user_password.txt
└── srcs/
    ├── .env                     # configuration (git-ignored)
    ├── .env.example             # template for .env
    ├── docker-compose.yml
    └── requirements/
        ├── mariadb/   Dockerfile  .dockerignore  conf/51-bind-address.cnf  tools/entrypoint.sh
        ├── nginx/     Dockerfile  .dockerignore  conf/default.conf
        └── wordpress/ Dockerfile  .dockerignore  conf/www.conf             tools/script.sh
```

### Configuration file: `srcs/.env`

Copy the template and fill it in:

```
cp srcs/.env.example srcs/.env
```

| Variable         | Used by              | Meaning |
|------------------|----------------------|---------|
| `WP_URL`         | wordpress            | Public URL of the site: `https://jchartie.42.fr` |
| `WP_TITLE`       | wordpress            | Site title |
| `WP_ADMIN_USER`  | wordpress            | Administrator user name — must **not** contain `admin` / `administrator` |
| `WP_ADMIN_EMAIL` | wordpress            | Administrator e-mail |
| `WP_OTHER_USER`  | wordpress            | Second (non-administrator) user name |
| `WP_USER_EMAIL`  | wordpress            | Second user's e-mail |
| `DB_NAME`        | mariadb, wordpress   | Name of the WordPress database |
| `DB_USER`        | mariadb, wordpress   | Database user WordPress connects with |

Never put a password in `.env` or in a Dockerfile.

### Secrets: `secrets/`

Create one file per password at the repository root:

```
mkdir -p secrets
printf '%s' 'your-db-password'    > secrets/db_password.txt
printf '%s' 'your-admin-password' > secrets/wp_admin_password.txt
printf '%s' 'your-user-password'  > secrets/wp_user_password.txt
```

To generate a random password made of hexadecimal characters, you can use the command:

````
openssl rand -hex 32
````

`docker-compose.yml` declares them as Docker secrets. Inside a container that uses a secret, it is available as a read-only file at `/run/secrets/<name>`:

| Secret              | Mounted in          | Read by |
|---------------------|---------------------|---------|
| `db_password`       | mariadb, wordpress  | `entrypoint.sh` (creates the DB user), `script.sh` (writes `wp-config.php`) |
| `wp_admin_password` | wordpress           | `script.sh` (`wp core install`) |
| `wp_user_password`  | wordpress           | `script.sh` (`wp user create`) |

`secrets/` and `srcs/.env` are listed in `.gitignore`. Check with `git status` that they never appear before committing.

## 2. Build and launch

### With the Makefile

| Target                      | Command run |
|-----------------------------|-------------|
| `make` / `make up`          | Creates the host data folders, then `docker compose up --build -d` |
| `make stop`                 | `docker compose stop` |
| `make start`                | `docker compose start` |
| `make down`                 | `docker compose down` (containers + network removed, volumes kept) |
| `make strict_down`          | `docker compose down -v --rmi all`, then deletes the host data folders |
| `make ps [option=-a]`       | `docker compose ps` |
| `make logs name=<service>`  | `docker compose logs <service>` |
| `make exec name=<service> cmd="<command>"` | `docker compose exec <service> <command>` |

### With Docker Compose directly

```
docker compose -f srcs/docker-compose.yml up --build -d      # build + start
docker compose -f srcs/docker-compose.yml build <service>    # rebuild one image
docker compose -f srcs/docker-compose.yml up -d <service>    # recreate one service
docker compose -f srcs/docker-compose.yml logs -f <service>  # follow logs
docker compose -f srcs/docker-compose.yml down               # stop and remove
```

### Start-up sequence

1. **mariadb** starts. On first boot (no `$DB_NAME` directory in `/var/lib/mysql`), `entrypoint.sh` starts a temporary server, creates the database and the `DB_USER` user, shuts it down, then `exec`s `mariadbd` in the foreground.
2. Its healthcheck (`mariadb-admin ping`) becomes healthy.
3. **wordpress** starts (it waits for `service_healthy`). On first boot, `script.sh` downloads WordPress into `/var/www/wordpress`, runs `wp config create`, `wp core install` and `wp user create`, then `exec`s `php-fpm8.2 -F`.
4. **nginx** listens on 443, serves static files from `/var/www/wordpress` and forwards `*.php` to `wordpress:9000`.

Each setup step is skipped if its result already exists on the volume, so it only runs again after the volumes are wiped.

## 3. Manage containers and volumes

### Containers

```
make ps                                   # status of the 3 services
make logs name=mariadb                    # logs of one service
make exec name=wordpress cmd=bash         # shell inside a container
docker inspect container_nginx            # full configuration of a container
docker stats                              # live CPU / memory usage
```

Useful checks inside containers:

```
make exec name=mariadb cmd="mariadb -e 'SHOW DATABASES;'"
make exec name=mariadb cmd="mariadb -e 'SELECT user, host FROM mysql.user;'"
make exec name=wordpress cmd="wp user list --path=/var/www/wordpress --allow-root"
make exec name=nginx cmd="nginx -t"       # validate NGINX configuration
```

After editing a Dockerfile or a file in `conf/` / `tools/`, rebuild and recreate that service:

```
docker compose -f srcs/docker-compose.yml up -d --build <service>
```

Changes to setup scripts only take effect on a fresh install (see below).

### Images and network

```
docker images                 # nginx, wordpress, mariadb
docker network ls             # srcs_inception
docker network inspect srcs_inception
```

Compose prefixes networks and volumes with the project name, which defaults to the folder of the compose file (`srcs`).

### Volumes

```
docker volume ls                              # srcs_wordpress_data, srcs_mariadb_data
docker volume inspect srcs_wordpress_data     # shows the host path in "Options.device"
```

**Full reset** (reruns all first-boot setup, including users and passwords):

```
make strict_down
make
```

## 4. Where the data is stored and how it persists

| Named volume     | Mounted at (in container)                  | Stored on the host              | Content |
|------------------|--------------------------------------------|---------------------------------|---------|
| `wordpress_data` | `/var/www/wordpress` (nginx and wordpress) | `/home/jchartie/data/wordpress` | WordPress PHP files, `wp-config.php`, themes, plugins, uploads |
| `mariadb_data`   | `/var/lib/mysql` (mariadb)                 | `/home/jchartie/data/mariadb`   | MariaDB data files (all databases) |

Both are Docker **named volumes** using the `local` driver with `driver_opts` (`type: none`, `o: bind`, `device: <host path>`), so their data lives in `/home/jchartie/data`. The host folders must exist before the volumes are first used; `make` creates them.

Persistence:

- `make stop` / `make start` / `make down` / container restarts: **data is kept.**
- `docker compose down -v`: removes the Docker volume objects, but the files under `/home/jchartie/data` remain.
- `make strict_down`: removes the volumes **and** deletes the host folders, so all site content and the database are lost.

The NGINX and WordPress containers share `wordpress_data`: WordPress writes the files, NGINX reads them to serve static content.
