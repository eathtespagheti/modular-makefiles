include .makefiles/composer.mk

WEBAPP-SERVICE ?= symfony
SYMFONY-RUN = $(DOCKER-RUN) $(WEBAPP-SERVICE)

.PHONY: assets-install
assets-install: ## Run assets:install
	@$(SYMFONY-RUN) bin/console --no-interaction assets:install

.PHONY: doctrine-migrations-migrate
doctrine-migrations-migrate: ## Run doctrine migrations
	@$(SYMFONY-RUN) bin/console --no-interaction doctrine:migrations:migrate

.vscode/commands: $(shell find symfony/src -iname *.php -type f)
	@$(SYMFONY-RUN) sh -c "bin/console list | tail -n +21 | cut -d ' ' -f 3 | grep -o \"[A-z]*:[A-z:]*\"" > $@

.PHONY: symfony-setup-test-envinronment
symfony-setup-test-envinronment: ## Recreate test db from scratch
	@-$(SYMFONY-RUN) doctrine:database:drop --no-interaction --force --env=test
	@$(SYMFONY-RUN) doctrine:database:create --no-interaction --env=test
	@$(SYMFONY-RUN) doctrine:migrations:migrate --no-interaction --env=test
	@-$(SYMFONY-RUN) doctrine:fixtures:load --no-interaction --env=test

.PHONY: debug-tests
debug-tests: symfony-setup-test-envinronment ## Start a symfony container running tests and listening to a Debugger
	@$(SYMFONY-DEBUG) bin/phpunit

.PHONY: test
test: symfony-setup-test-envinronment ## Launch a symfony container running tests
	@$(SYMFONY-RUN) bin/phpunit

.PHONY: symfony-php
symfony-php: ## Run a php command in the symfony container, command should be definend in the COMMAND env variable
	@$(SYMFONY-RUN) sh -c "php $(COMMAND)"

.PHONY: symfony-console
symfony-console: ## Run a console command in the symfony container, command should be definend in the COMMAND env variable
	@$(SYMFONY-RUN) sh -c "bin/console $(COMMAND)"

.PHONY: first-setup
first-setup: ## Run first setup
	@$(MAKE) up
	@$(MAKE) composer-install
	@$(MAKE) assets-install
	@$(MAKE) doctrine-migrations-migrate

.PHONY: debug
debug: ## Run a debug container executing the command defined in the COMMAND env variable
	@$(SYMFONY-DEBUG) sh -c "$(COMMAND)"

.PHONY: debug-stop
debug-stop: ## Stop debug container
	@$(MAKE) stop-$(WEBAPP-DEBUG-SERVICE)
