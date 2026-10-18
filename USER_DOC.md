# User documentation

This guide explains how to use the Inception stack: what it provides, how to start and stop it, how to reach the website, where the credentials are, and how to check that everything works.

All commands are run from the root of the repository.

## 1. What the stack provides

The stack runs a WordPress website at **https://jchartie.42.fr**, made of three services, each in its own container:

| Service     | Container name        | Role |
|-------------|-----------------------|------|
| `nginx`     | `container_nginx`     | The only entrypoint. Accepts HTTPS on port 443 (TLSv1.2 / TLSv1.3 only) and passes PHP requests to WordPress. |
| `wordpress` | `container_wordpress` | Runs WordPress with PHP-FPM. Generates the pages. |
| `mariadb`   | `container_mariadb`   | The database holding the site's content, settings and users. |

The website's files and the database are stored on the host in `/home/jchartie/data/`, so they survive restarts.

## 2. Start and stop the project

| Command            | What it does |
|--------------------|--------------|
| `make`             | Builds the images (if needed) and starts all containers in the background. |
| `make stop`        | Stops the containers. Nothing is deleted. |
| `make start`       | Starts containers that were stopped with `make stop`. |
| `make down`        | Stops and removes the containers and the network. **The website and its data are kept.** |
| `make strict_down` | Removes containers, images and volumes, **and deletes all website data on the host**. The next `make` reinstalls WordPress from scratch. |

The first start takes longer: WordPress is downloaded and installed, and the database is created.

## 3. Access the website and the administration panel

- **Website:** https://jchartie.42.fr
- **Administration panel:** https://jchartie.42.fr/wp-admin

The certificate is self-signed, so the browser shows a security warning the first time. Accept it to continue (e.g. *Advanced → Proceed*).

If the domain does not resolve, check that `/etc/hosts` contains:

```
127.0.0.1   jchartie.42.fr
```

## 4. Credentials

There are two WordPress accounts: an **administrator** and a **regular user**.

| What                          | Where to find it |
|-------------------------------|------------------|
| Administrator user name / e-mail | `srcs/.env` → `WP_ADMIN_USER`, `WP_ADMIN_EMAIL` |
| Administrator password        | `secrets/wp_admin_password.txt` |
| Regular user name / e-mail    | `srcs/.env` → `WP_OTHER_USER`, `WP_USER_EMAIL` |
| Regular user password         | `secrets/wp_user_password.txt` |
| Database name / user          | `srcs/.env` → `DB_NAME`, `DB_USER` |
| Database user password        | `secrets/db_password.txt` |

`srcs/.env` and `secrets/` are **never committed to git**. Keep them private.

**Changing a password:** the files are only read the first time the stack is installed. Editing them afterwards does not change an existing account.
- For a WordPress account, change the password from the administration panel (*Users → Profile*).
- To apply new values from `srcs/.env` and `secrets/` everywhere, reinstall with `make strict_down` then `make` (this deletes the site's data).

## 5. Check that the services are running

**Container status** — all three should be `Up` (or `Up (healthy)` for MariaDB):

```
make ps
```

**Logs of one service** (`nginx`, `wordpress` or `mariadb`):

```
make logs name=wordpress
```

A healthy start ends with `Starting PHP-FPM8.2` for WordPress and `Starting MariaDBD daemon server` for MariaDB.

**The website answers over HTTPS:**

```
curl -k -I https://jchartie.42.fr
```

You should get an HTTP response (e.g. `200` or a redirect).

**Only TLSv1.2 / TLSv1.3 are accepted** — this command must fail:

```
openssl s_client -connect jchartie.42.fr:443 -tls1_1 </dev/null
```

**The database answers:**

```
make exec name=mariadb cmd="mariadb-admin ping"
```

Expected output: `mysqld is alive`.

**Both WordPress users exist:**

```
make exec name=wordpress cmd="wp user list --path=/var/www/wordpress --allow-root"
```

If a container keeps restarting, read its logs with `make logs name=<service>`.
