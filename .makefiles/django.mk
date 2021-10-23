include .makefiles/docker.mk

# Webapp variables
WEBAPP-SERVICE ::= django
dbfile ::= db.json

migrations: ## Make Django migrations
	@$(DOCKER-EXEC) -u 0 $(WEBAPP-SERVICE) django-admin makemigrations
	@$(fix-ownership-project)

migrate: ## Apply migrations 
	@$(DOCKER-EXEC) $(WEBAPP-SERVICE) django-admin migrate

loaddata: ## Load fixtures in webapp from db.json
	@$(DOCKER-EXEC) $(WEBAPP-SERVICE) django-admin loaddata $(dbfile)

dumpdata: ## Dump webapp database ad fixtures in db.json 
	@$(DOCKER-EXEC) $(WEBAPP-SERVICE) sh -c "django-admin dumpdata --natural-primary --natural-foreign > $(dbfile)"
	@$(call fix-ownership-of,$(dbfile))

collectstatic: ## Launch collectstatic in Django webapp 
	@$(DOCKER-EXEC) $(WEBAPP-SERVICE) django-admin collectstatic --noinput

first-setup: up ## Get up the containers, setup database and load fixtures
	@echo Waiting for containers to be ready...
	@sleep 3
	@$(DOCKER-EXEC) $(WEBAPP-SERVICE) django-admin migrate
	@$(DOCKER-EXEC) $(WEBAPP-SERVICE) django-admin loaddata $(dbfile)
	@$(DOCKER-EXEC) $(WEBAPP-SERVICE) django-admin collectstatic --noinput

test: ## Launch tests for webapp
	@$(DOCKER-EXEC) $(WEBAPP-SERVICE) django-admin test


# Other targets
all: first-setup


.PHONY: all collectstatic dumpdata first-setup loaddata migrate migrations test
