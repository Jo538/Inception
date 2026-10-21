# **************************************************************************** #
#                                                                              #
#                                                         :::      ::::::::    #
#    Makefile                                           :+:      :+:    :+:    #
#                                                     +:+ +:+         +:+      #
#    By: jchartie <jchartie@student.42.fr>          +#+  +:+       +#+         #
#                                                 +#+#+#+#+#+   +#+            #
#    Created: 2026/10/16 17:49:53 by admin             #+#    #+#              #
#    Updated: 2026/10/21 11:19:48 by jchartie         ###   ########.fr        #
#                                                                              #
# **************************************************************************** #

COMPOSE=docker compose -f srcs/docker-compose.yml

up:
	@mkdir -p /home/jchartie/data/wordpress
	@mkdir -p /home/jchartie/data/mariadb
	@$(COMPOSE) up --build -d

down:
	@$(COMPOSE) down

stop:
	@$(COMPOSE) stop

start:
	@$(COMPOSE) start

strict_down:
	@$(COMPOSE) down -v --rmi all
	@rm -rf /home/jchartie/data/wordpress/*
	@rm -rf /home/jchartie/data/mariadb/*

ps:
	@$(COMPOSE) ps $(option)

logs:
	@$(COMPOSE) logs $(name)

exec:
	@$(COMPOSE) exec $(name) $(cmd)
