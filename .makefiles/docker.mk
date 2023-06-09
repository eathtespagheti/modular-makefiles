# Docker compose realted
COMPOSE ?= DOCKER_BUILDKIT=1 ${shell docker compose > /dev/null 2>&1 && echo "docker compose" || echo "docker-compose"}
COMPOSE-FILES ?= $(shell find . -name "docker-compose.y*ml")
COMPOSE-DEVELOPMENT-FILES ?= $(shell find . -name "docker-compose.dev*.y*ml")
COMPOSE-TEST-FILES ?= $(shell find . -name "docker-compose.test*.y*ml")
EXTRA-COMPOSE-FILES ?= 
ALL-COMPOSE-FILES = $(COMPOSE-FILES) $(COMPOSE-DEVELOPMENT-FILES) $(COMPOSE-TEST-FILES) $(EXTRA-COMPOSE-FILES)
COMPOSE-BASE-PRESET = $(COMPOSE) $(COMPOSE-FILES:%=-f %)
COMPOSE-DEVELOPMENT-PRESET = $(COMPOSE-BASE-PRESET) $(COMPOSE-DEVELOPMENT-FILES:%=-f %)
COMPOSE-TEST-PRESET = $(COMPOSE-BASE-PRESET) $(COMPOSE-TEST-FILES:%=-f %)
COMPOSE-ALL-PRESET = $(COMPOSE) $(ALL-COMPOSE-FILES:%=-f %)

# Other Docker commands
DOCKER-EXEC = $(COMPOSE-DEVELOPMENT-PRESET) exec
DOCKER-RUN = $(COMPOSE-DEVELOPMENT-PRESET) run --rm
DOCKER-LOGS = $(COMPOSE-DEVELOPMENT-PRESET) logs -f

# Functions
executeAsSuperuser = docker run --rm -u 0 -v "$(shell pwd)":/src alpine sh -c "$(1)"
fixOwnershipOf = $(call executeAsSuperuser,chown -R $(getUIDandGID) /src/$(1))
fixOwnershipProject = $(call fixOwnershipOf,.)
generate-random-string = tr -dc A-Za-z0-9 </dev/urandom | head -c
checkForDoNotPush = if [ -z "$$DO_NOT_PUSH" ]; then $(1) push; else printf "DO_NOT_PUSH it's set to %s\nSkipping push...\n" "$$DO_NOT_PUSH"; fi

# Services
WEBAPP-DEBUG-SERVICE = $(WEBAPP-SERVICE)-debug
SERVICES = $(WEBAPP-SERVICE) $(EXTRA-SERVICES) $(WEBAPP-DEBUG-SERVICE)

# Prefixes
logs-prefix ?= logs-
restart-prefix ?= restart-
stop-prefix ?= stop-
up-prefix ?= up-
down-prefix ?= down-
shell-prefix ?= shell-
start-prefix ?= start-
run-prefix ?= run-

# Other variables
WEBAPP-SERVICE ?= webapp
WEBAPP-CONTAINER-PATH ?= /webapp
SECRETS_FOLDER ?= secrets
SECRETS_LIST ?=

# Secrets
$(SECRETS_FOLDER):
	@mkdir -p $(@)

$(SECRETS_FOLDER)/%: $(SECRETS_FOLDER)
	@$(generate-random-string) 32 > $(@)

secrets: $(shell for secret in $(SECRETS_LIST); do printf "$(SECRETS_FOLDER)/$$secret "; done)  ## Generate random values for docker secrets


# Docker compose targets
.PHONY: build-base
build-base: ## Build only the image in the docker-compose.y*ml files
	@$(COMPOSE-BASE-PRESET) build

.PHONY: build-development
build-development: ## Build only the image in the docker-compose.dev*.y*ml files
	@$(COMPOSE-DEVELOPMENT-PRESET) build

.PHONY: build-test
build-test: ## Build only the image in the docker-compose.test*.y*ml files
	@$(COMPOSE-TEST-PRESET) build

.PHONY: build
build: build-base build-development build-test ## Build all needed images from docker compose

.PHONY: up
up: secrets ## Docker compose up on all project files
	@$(COMPOSE-DEVELOPMENT-PRESET) up -d

.PHONY: up-servicename
up-servicename: ## Up the service named servicename

__COMPILED_UP_PREFIX := $(addprefix $(up-prefix), $(SERVICES))
.PHONY: $(__COMPILED_UP_PREFIX)
$(__COMPILED_UP_PREFIX): $(up-prefix)%:
	@$(COMPOSE-DEVELOPMENT-PRESET) up -d $*

.PHONY: down
down: ## Docker compose down on all project files
	@$(COMPOSE-ALL-PRESET) down

.PHONY: down-with-volumes
down-with-volumes: ## Docker compose down on all project files and remove all named volumes
	@$(COMPOSE-ALL-PRESET) down -v

__COMPILED_DOWN_PREFIX := $(addprefix $(down-prefix), $(SERVICES))
.PHONY: $(__COMPILED_DOWN_PREFIX)
$(__COMPILED_DOWN_PREFIX): $(down-prefix)%:
	@$(COMPOSE-ALL-PRESET) rm -s -v -f $*

.PHONY: down-servicename
down-servicename: ## Down the service named servicename

.PHONY: clean-docker
clean-docker: ## Docker compose down on all project compose files, also delete all the volumes
	@$(COMPOSE-ALL-PRESET) down --remove-orphans -v
	@-rm -rf $(SECRETS_FOLDER)

.PHONY: nuke-docker
nuke-docker: ## Nuke everything related to docker in this project
	@-docker image rm -f $(shell grep -oh "image: .*" $(ALL-COMPOSE-FILES) | cut -d ' ' -f 2 | tr '\n' ' ')

.PHONY: ps
ps: ## List docker containers
	@$(COMPOSE-ALL-PRESET) ps

.PHONY: push-base
push-base: ## Push only the image in the docker-compose.y*ml files
	@$(call checkForDoNotPush,$(COMPOSE-BASE-PRESET))

.PHONY: push-development
push-development: ## Push only the image in the docker-compose.dev*.y*ml files
	@$(call checkForDoNotPush,$(COMPOSE-DEVELOPMENT-PRESET))

.PHONY: push-test
push-test: ## Push only the image in the docker-compose.test*.y*ml files
	@$(call checkForDoNotPush,$(COMPOSE-TEST-PRESET))

.PHONY: push
push: push-base push-development push-test ## Push all needed images from docker compose

# Webapp container targets
.PHONY: fix-ownership
fix-ownership: ## Change ownership to user for all project files
	@$(fixOwnershipProject)


# Services targets
.PHONY: list-services
list-services: ## List all declared docker compose services
	@echo $(SERVICES)

.PHONY: start-servicename
start-servicename: ## Start service named servicename

__COMPILED_START_PREFIX := $(addprefix $(start-prefix), $(SERVICES))
.PHONY: $(__COMPILED_START_PREFIX)
$(__COMPILED_START_PREFIX): $(start-prefix)%:
	@$(COMPOSE-DEVELOPMENT-PRESET) start $*

.PHONY: run-servicename
run-servicename: ## Run service named servicename

__COMPILED_RUN_PREFIX := $(addprefix $(run-prefix), $(SERVICES))
.PHONY: $(__COMPILED_RUN_PREFIX)
$(__COMPILED_RUN_PREFIX): $(run-prefix)%:
	@$(DOCKER-RUN) $*

.PHONY: restart-servicename
restart-servicename: ## Restart service named servicename

__COMPILED_RESTART_PREFIX := $(addprefix $(restart-prefix), $(SERVICES))
.PHONY: $(__COMPILED_RESTART_PREFIX)
$(__COMPILED_RESTART_PREFIX): $(restart-prefix)%:
	@$(COMPOSE-DEVELOPMENT-PRESET) restart $*

.PHONY: stop-servicename
stop-servicename: ## Stop service named servicename

__COMPILED_STOP_PREFIX := $(addprefix $(stop-prefix), $(SERVICES))
.PHONY: $(__COMPILED_STOP_PREFIX)
$(__COMPILED_STOP_PREFIX): $(stop-prefix)%:
	@$(COMPOSE-DEVELOPMENT-PRESET) stop $*

.PHONY: shell-servicename
shell-servicename: ## Open shell for service named servicename

__COMPILED_SHELL_PREFIX := $(addprefix $(shell-prefix), $(SERVICES))
.PHONY: $(__COMPILED_SHELL_PREFIX)
$(__COMPILED_SHELL_PREFIX): $(shell-prefix)%:
	@$(DOCKER-EXEC) $* sh || $(DOCKER-RUN) $* sh


# Logging targets
.PHONY: logs
logs: ## Show all containers logs
	@$(DOCKER-LOGS)

.PHONY: logs-servicename
logs-servicename: ## Show logs for service named servicename

__COMPILED_LOGS_PREFIX := $(addprefix $(logs-prefix), $(SERVICES))
.PHONY: $(__COMPILED_LOGS_PREFIX)
$(__COMPILED_LOGS_PREFIX): $(logs-prefix)%:
	@$(DOCKER-LOGS) $*
