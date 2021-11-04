include .makefiles/aws.mk

WEBAPP-SERVICE ?= node
NODE-FILES-TO-CLEAN ?= $(shell find . -type d -name node_modules) $(shell find . -type f -name package-lock.json)

app/node_modules: app/package.json
	@$(DOCKER-RUN) $(WEBAPP-SERVICE) npm install
	@rm -f app/node_modules/.modified
	@touch -m app/node_modules/.modified

install: app/node_modules ## Install node modules

start: generate-from-dist ## Start node app
	@$(DOCKER-RUN) $(WEBAPP-SERVICE) npm start

test: install generate-from-dist ## Test node app
	@$(DOCKER-RUN) $(WEBAPP-SERVICE) npm test

test-watch: install generate-from-dist ## Test node app and watch for changes
	@$(DOCKER-RUN) $(WEBAPP-SERVICE) npm run test-watch

compile: generate-from-dist ## Compile typescript
	@$(DOCKER-RUN) $(WEBAPP-SERVICE) npm compile

watch: generate-from-dist ## Compile with tsc in watch mode
	@$(DOCKER-RUN) $(WEBAPP-SERVICE) npm watch

setup: generate-from-dist ## Setup environment from scratch
	@$(MAKE) build
	@$(MAKE) install

debug: generate-from-dist ## Start node app but listen and wait for debugger
	@-$(DOCKER-RUN) -d -p 9229:9229 $(WEBAPP-SERVICE) npm run debug

debug-tests: generate-from-dist ## Start tests but listen and wait for debugger
	@-$(DOCKER-RUN) -d -p 9229:9229 $(WEBAPP-SERVICE) npm run debug-tests

debug-stop: ## Stop all debugging containers
	@$(MAKE) down-$(WEBAPP-SERVICE)

nuke-node:
	@-rm -rf $(NODE-FILES-TO-CLEAN)

.PHONY: install start test compile watch setup test-watch debug debug-stop nuke-node