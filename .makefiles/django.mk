DB_FILE ?= db.json
WEBAPP-SERVICE ?= django

.PHONY: migrations
migrations: ## Make Django migrations
	@$(DOCKER-RUN) -u 0 $(WEBAPP-SERVICE) django-admin makemigrations
	@$(fixOwnershipProject)

.PHONY: migrate
migrate: ## Apply migrations 
	@$(DOCKER-RUN) $(WEBAPP-SERVICE) django-admin migrate

.PHONY: loaddata
loaddata: ## Load fixtures in webapp from db.json
	@$(DOCKER-RUN) $(WEBAPP-SERVICE) django-admin loaddata $(DB_FILE)

.PHONY: dumpdata
dumpdata: ## Dump webapp database ad fixtures in db.json 
	@$(DOCKER-RUN) $(WEBAPP-SERVICE) sh -c "django-admin dumpdata --natural-primary --natural-foreign > $(DB_FILE)"
	@$(call fix-ownership-of,$(DB_FILE))

.PHONY: collectstatic
collectstatic: ## Launch collectstatic in Django webapp 
	@$(DOCKER-RUN) $(WEBAPP-SERVICE) django-admin collectstatic --noinput

.PHONY: first-setup
first-setup: up ## Get up the containers, setup database and load fixtures
	@echo Waiting for containers to be ready...
	@sleep 3
	@$(DOCKER-RUN) $(WEBAPP-SERVICE) django-admin migrate
	@$(DOCKER-RUN) $(WEBAPP-SERVICE) django-admin loaddata $(DB_FILE)
	@$(DOCKER-RUN) $(WEBAPP-SERVICE) django-admin collectstatic --noinput

.PHONY: test
test: ## Launch tests for webapp
	@$(DOCKER-RUN) $(WEBAPP-SERVICE) django-admin test
