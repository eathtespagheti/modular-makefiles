include .makefiles/docker.mk

WEBAPP-SERVICE ?= php
COMPOSER = $(DOCKER-RUN) composer --no-interaction

.PHONY: composer-update
composer-update: ## Run composer update
	@$(COMPOSER) update

.PHONY: composer-install
composer-install: ## Run composer install
	@$(COMPOSER) install

.PHONY: composer-dump-autoload
composer-dump-autoload: ## Run composer dump-autoload
	@$(COMPOSER) dump-autoload
