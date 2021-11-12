include .makefiles/aws.mk

WEBAPP-SERVICE ?= node
NODE-FILES-TO-CLEAN ?= $(shell find . -type d -name node_modules) $(shell find . -type f -name package-lock.json)

app/node_modules: app/package.json
	@$(DOCKER-RUN) $(WEBAPP-SERVICE) npm install
	@rm -f app/node_modules/.modified
	@touch -m app/node_modules/.modified

.PHONY: install
install: app/node_modules ## Install node modules

.PHONY: start
start: generate-from-dist ## Start node app
	@$(DOCKER-RUN) $(WEBAPP-SERVICE) npm start

.PHONY: test
test: install generate-from-dist ## Test node app
	@$(DOCKER-RUN) $(WEBAPP-SERVICE) npm test

.PHONY: test-watch
test-watch: install generate-from-dist ## Test node app and watch for changes
	@$(DOCKER-RUN) $(WEBAPP-SERVICE) npm run test-watch

.PHONY: compile
compile: generate-from-dist ## Compile typescript
	@$(DOCKER-RUN) $(WEBAPP-SERVICE) npm compile

.PHONY: watch
watch: generate-from-dist ## Compile with tsc in watch mode
	@$(DOCKER-RUN) $(WEBAPP-SERVICE) npm watch

.PHONY: generate-from-dist
setup: generate-from-dist ## Setup environment from scratch
	@$(MAKE) build
	@$(MAKE) install

.PHONY: debug
debug: generate-from-dist ## Start node app but listen and wait for debugger
	@-$(DOCKER-RUN) -d -p 9229:9229 $(WEBAPP-SERVICE) npm run debug

.PHONY: debug-tests
debug-tests: generate-from-dist ## Start tests but listen and wait for debugger
	@-$(DOCKER-RUN) -d -p 9229:9229 $(WEBAPP-SERVICE) npm run debug-tests

.PHONY: debug-stop
debug-stop: ## Stop all debugging containers
	@$(MAKE) stop-$(WEBAPP-SERVICE)

.PHONY: nuke-node
nuke-node:
	@-rm -rf $(NODE-FILES-TO-CLEAN)
