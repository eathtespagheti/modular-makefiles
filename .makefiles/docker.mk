include .makefiles/common.mk

# Docker compose realted
COMPOSE ?= DOCKER_BUILDKIT=1 ${shell docker compose > /dev/null 2>&1 && echo "docker compose" || echo "docker-compose"}
COMPOSE-FILES ?= $(shell find . -name "docker-compose.y*ml")
COMPOSE-DEBUG-FILES ?= $(shell find . -name "docker-compose.debug*.y*ml")
COMPOSE-DEVELOP-FILES ?= $(shell find . -name "docker-compose.dev*.y*ml")
EXTRA-COMPOSE-FILES ?= 
COMPOSE-BASE-PRESET = $(COMPOSE) $(COMPOSE-FILES:%=-f %)
COMPOSE-DEVELOP-PRESET = $(COMPOSE-BASE-PRESET) $(COMPOSE-DEVELOP-FILES:%=-f %)
COMPOSE-DEBUG-PRESET = $(COMPOSE-BASE-PRESET) $(COMPOSE-DEBUG-FILES:%=-f %)
COMPOSE-ALL-PRESET = $(COMPOSE-BASE-PRESET) $(COMPOSE-DEVELOP-FILES:%=-f %) $(COMPOSE-DEBUG-FILES:%=-f %) $(EXTRA-COMPOSE-FILES:%=-f %)

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
SERVICES = $(WEBAPP-SERVICE) $(EXTRA-SERVICES)
WEBAPP-DEBUG-SERVICE = $(WEBAPP-SERVICE)-debug

# Prefixes
logs-prefix ?= logs-
restart-prefix ?= restart-
stop-prefix ?= stop-
up-prefix ?= up-
down-prefix ?= down-
shell-prefix ?= shell-
start-prefix ?= start-

# Other variables
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
build: ## Build all needed images from docker compose
	@$(COMPOSE-BASE-PRESET) build

up: secrets ## Docker compose up on all project files
	@$(COMPOSE-DEVELOP-PRESET) up -d

up-servicename: ## Up the service named servicename

$(addprefix $(up-prefix), $(SERVICES)): $(up-prefix)%:
	@$(COMPOSE-ALL-PRESET) up -d $*

down: ## Docker compose down on all project files
	@$(COMPOSE-ALL-PRESET) down

$(addprefix $(down-prefix), $(SERVICES)): $(down-prefix)%:
	@$(COMPOSE-ALL-PRESET) rm -s -v -f $*

down-servicename: ## Down the service named servicename

clean: ## Docker compose up on all project files, also delete all the volumes
	@$(COMPOSE-ALL-PRESET) down --remove-orphans -v
	@rm -rf $(SECRETS_FOLDER)

ps: ## List docker containers
	@$(COMPOSE-ALL-PRESET) ps

push: ## Push all builded docker images in project
	@$(COMPOSE-BASE-PRESET) push

# Webapp container targets
fix-ownership: ## Change ownership to user for all project files
	@$(fix-ownership-project)


# Services targets
list-services: ## List all declared docker compose services
	@echo $(SERVICES)

start-servicename: ## Start service named servicename

$(addprefix $(start-prefix), $(SERVICES)): $(start-prefix)%:
	@$(COMPOSE-ALL-PRESET) start $*

restart-servicename: ## Restart service named servicename

$(addprefix $(restart-prefix), $(SERVICES)): $(restart-prefix)%:
	@$(COMPOSE-ALL-PRESET) restart $*

stop-servicename: ## Stop service named servicename

$(addprefix $(stop-prefix), $(SERVICES)): $(stop-prefix)%:
	@$(COMPOSE-ALL-PRESET) stop $*

shell-servicename: ## Open shell for service named servicename

$(addprefix $(shell-prefix), $(SERVICES)): $(shell-prefix)%:
	@$(DOCKER-EXEC) $* sh || $(DOCKER-RUN) $* sh


# Logging targets
logs: ## Show all containers logs
	@$(DOCKER-LOGS)

logs-servicename: ## Show logs for service named servicename

$(addprefix $(logs-prefix), $(SERVICES)): $(logs-prefix)%:
	@$(DOCKER-LOGS) $*


.PHONY: secrets build up up-servicename $(addprefix $(up-prefix), $(SERVICES)) down down-servicename $(addprefix $(down-prefix), $(SERVICES)) clean fix-ownership list-services start-servicename $(addprefix $(start-prefix), $(SERVICES)) restart-servicename $(addprefix $(restart-prefix), $(SERVICES)) stop-servicename $(addprefix $(stop-prefix), $(SERVICES)) shell-servicename $(addprefix $(shell-prefix), $(SERVICES)) logs logs-servicename $(addprefix $(logs-prefix), $(SERVICES)) ps push
