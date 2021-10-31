include .makefiles/docker.mk

DB_FILE ?= db.json
WEBAPP-SERVICE ?= django

migrations: ## Make Django migrations
	@$(DOCKER-EXEC) -u 0 $(WEBAPP-SERVICE) django-admin makemigrations
	@$(fix-ownership-project)

migrate: ## Apply migrations 
	@$(DOCKER-EXEC) $(WEBAPP-SERVICE) django-admin migrate

loaddata: ## Load fixtures in webapp from db.json
	@$(DOCKER-EXEC) $(WEBAPP-SERVICE) django-admin loaddata $(DB_FILE)

dumpdata: ## Dump webapp database ad fixtures in db.json 
	@$(DOCKER-EXEC) $(WEBAPP-SERVICE) sh -c "django-admin dumpdata --natural-primary --natural-foreign > $(DB_FILE)"
	@$(call fix-ownership-of,$(DB_FILE))

collectstatic: ## Launch collectstatic in Django webapp 
	@$(DOCKER-EXEC) $(WEBAPP-SERVICE) rm -rf /static/hemport/stylesheets/hemport.css
	@$(DOCKER-EXEC) $(WEBAPP-SERVICE) django-admin collectstatic --noinput

first-setup: up ## Get up the containers, setup database and load fixtures
	@echo Waiting for containers to be ready...
	@sleep 3
	@$(DOCKER-EXEC) $(WEBAPP-SERVICE) django-admin migrate
	@$(DOCKER-EXEC) $(WEBAPP-SERVICE) django-admin loaddata $(DB_FILE)
	@$(DOCKER-EXEC) $(WEBAPP-SERVICE) django-admin collectstatic --noinput

test: ## Launch tests for webapp
	@$(DOCKER-EXEC) $(WEBAPP-SERVICE) django-admin test


.PHONY: collectstatic dumpdata first-setup loaddata migrate migrations test
