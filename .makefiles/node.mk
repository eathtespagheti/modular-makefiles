include .makefiles/docker.mk

WEBAPP-SERVICE ?= node

app/node_modules: app/package.json
	@$(DOCKER-RUN) $(WEBAPP-SERVICE) npm install
	@rm -f app/node_modules/.modified
	@touch -m app/node_modules/.modified

install: app/node_modules ## Install node modules

start: ## Start node app
	@$(DOCKER-RUN) $(WEBAPP-SERVICE) npm start

test: install ## Test node app
	@$(DOCKER-RUN) $(WEBAPP-SERVICE) npm test

test-watch: install ## Test node app and watch for changes
	@$(DOCKER-RUN) $(WEBAPP-SERVICE) npm run test-watch

compile: ## Compile typescript
	@$(DOCKER-RUN) $(WEBAPP-SERVICE) npm compile

watch: ## Compile with tsc in watch mode
	@$(DOCKER-RUN) $(WEBAPP-SERVICE) npm watch

setup: ## Setup environment from scratch
	@$(MAKE) build
	@$(MAKE) install

debug: ## Start node app but listen and wait for debugger
	@-$(DOCKER-RUN) -d -p 9229:9229 $(WEBAPP-SERVICE) npm run debug

debug-stop: ## Stop all debugging containers
	@$(MAKE) down-$(WEBAPP-SERVICE)


.PHONY: install start test compile watch setup test-watch debug debug-stop
