# **************************************************************************** #
#                                                                              #
#                                                         :::      ::::::::    #
#    Makefile                                           :+:      :+:    :+:    #
#                                                     +:+ +:+         +:+      #
#    By: admin <admin@student.42.fr>                +#+  +:+       +#+         #
#                                                 +#+#+#+#+#+   +#+            #
#    Created: 2026/10/16 17:49:53 by admin             #+#    #+#              #
#    Updated: 2026/10/16 18:27:48 by admin            ###   ########.fr        #
#                                                                              #
# **************************************************************************** #

COMPOSE=docker compose -f srcs/docker-compose.yml

up:
	@mkdir -p /Users/admin/Documents/42/inception/test/wordpress   # /home/jchartie/data/wordpress
	@mkdir -p /Users/admin/Documents/42/inception/test/mariadb     # /home/jchartie/data/mariadb
	@$(COMPOSE) up --build -d

down:
	@$(COMPOSE) down

stop:
	@$(COMPOSE) stop

start:
	@$(COMPOSE) start

strict_down:
	@$(COMPOSE) down -v
	@rm -rf /Users/admin/Documents/42/inception/test/wordpress     # /home/jchartie/data/wordpress/*
	@rm -rf /Users/admin/Documents/42/inception/test/mariadb    # /home/jchartie/data/mariadb/*

ps:
	@$(COMPOSE) ps

logs:
	@$(COMPOSE) logs $(name)

exec:
	@$(COMPOSE) exec $(name) $(cmd)
