include .makefiles/common.mk

# Docker compose realted
COMPOSE ?= DOCKER_BUILDKIT=1 ${shell docker compose > /dev/null 2>&1 && echo "docker compose" || echo "docker-compose"}
COMPOSE-FILES ?= $(shell find . -name "docker-compose.y*ml")
COMPOSE-DEBUG-FILES ?= $(shell find . -name "docker-compose.debug*.y*ml")
COMPOSE-DEVELOP-FILES ?= $(shell find . -name "docker-compose.dev*.y*ml")
EXTRA-COMPOSE-FILES ?= 
ALL-COMPOSE-FILES = $(COMPOSE-FILES) $(COMPOSE-DEBUG-FILES) $(COMPOSE-DEVELOP-FILES) $(EXTRA-COMPOSE-FILES)
COMPOSE-BASE-PRESET = $(COMPOSE) $(COMPOSE-FILES:%=-f %)
COMPOSE-DEVELOP-PRESET = $(COMPOSE-BASE-PRESET) $(COMPOSE-DEVELOP-FILES:%=-f %)
COMPOSE-DEBUG-PRESET = $(COMPOSE-BASE-PRESET) $(COMPOSE-DEBUG-FILES:%=-f %)
COMPOSE-ALL-PRESET = $(COMPOSE) $(ALL-COMPOSE-FILES:%=-f %)

# Other Docker commands
DOCKER-EXEC = $(COMPOSE-ALL-PRESET) exec
DOCKER-RUN = $(COMPOSE-ALL-PRESET) run
DOCKER-LOGS = $(COMPOSE-ALL-PRESET) logs -f

# Functions
getUID = $(shell id -u)
getGID = $(shell id -g)
getUIDandGID = $(getUID):$(getGID)
fix-ownership-of = $(DOCKER-EXEC) -u 0 $(WEBAPP-SERVICE) chown -R $(getUIDandGID) $(1)
fix-ownership-project = $(call fix-ownership-of,$(WEBAPP-CONTAINER-PATH))
generate-random-string = tr -dc A-Za-z0-9 </dev/urandom | head -c

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
.PHONY: build
build: ## Build all needed images from docker compose
	@$(COMPOSE-BASE-PRESET) build

.PHONY: up
up: secrets ## Docker compose up on all project files
	@$(COMPOSE-DEVELOP-PRESET) up -d

.PHONY: up-servicename
up-servicename: ## Up the service named servicename

__COMPILED_UP_PREFIX := $(addprefix $(up-prefix), $(SERVICES))
.PHONY: $(__COMPILED_UP_PREFIX)
$(__COMPILED_UP_PREFIX): $(up-prefix)%:
	@$(COMPOSE-ALL-PRESET) up -d $*

.PHONY: down
down: ## Docker compose down on all project files
	@$(COMPOSE-ALL-PRESET) down

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

.PHONY: push
push: ## Push all builded docker images in project
	@$(COMPOSE-BASE-PRESET) push

# Webapp container targets
.PHONY: fix-ownership
fix-ownership: ## Change ownership to user for all project files
	@$(fix-ownership-project)


# Services targets
.PHONY: list-services
list-services: ## List all declared docker compose services
	@echo $(SERVICES)

.PHONY: start-servicename
start-servicename: ## Start service named servicename

__COMPILED_START_PREFIX := $(addprefix $(start-prefix), $(SERVICES))
.PHONY: $(__COMPILED_START_PREFIX)
$(__COMPILED_START_PREFIX): $(start-prefix)%:
	@$(COMPOSE-ALL-PRESET) start $*

.PHONY: restart-servicename
restart-servicename: ## Restart service named servicename

__COMPILED_RESTART_PREFIX := $(addprefix $(restart-prefix), $(SERVICES))
.PHONY: $(__COMPILED_RESTART_PREFIX)
$(__COMPILED_RESTART_PREFIX): $(restart-prefix)%:
	@$(COMPOSE-ALL-PRESET) restart $*

.PHONY: stop-servicename
stop-servicename: ## Stop service named servicename

__COMPILED_STOP_PREFIX := $(addprefix $(stop-prefix), $(SERVICES))
.PHONY: $(__COMPILED_STOP_PREFIX)
$(__COMPILED_STOP_PREFIX): $(stop-prefix)%:
	@$(COMPOSE-ALL-PRESET) stop $*

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
