include .makefiles/common.mk

COMPOSE ::= DOCKER_BUILDKIT=1 ${shell docker compose > /dev/null 2>&1 && echo "docker compose" || echo "docker-compose"}
COMPOSE-FILES ::= $(shell find -name "docker-compose.y*ml")
COMPOSE-DEBUG-FILES ::= $(shell find -name "docker-compose.debug.y*ml")
COMPOSE-PRESET = $(COMPOSE) $(COMPOSE-FILES:%=-f %)
COMPOSE-DEBUG-PRESET = $(COMPOSE-PRESET) $(COMPOSE-DEBUG-FILES:%=-f %)
DOCKER-EXEC = $(COMPOSE-DEBUG-PRESET) exec
WEBAPP-CONTAINER-PATH ::= /webapp
DOCKER-LOGS = $(COMPOSE-DEBUG-PRESET) logs -f

# Functions
getUID = $(shell id -u)
getGID = $(shell id -g)
getUIDandGID = $(getUID):$(getGID)
fix-ownership-of = $(DOCKER-EXEC) -u 0 $(WEBAPP-SERVICE) chown -R $(getUIDandGID) $(1)
fix-ownership-project = $(call fix-ownership-of,$(WEBAPP-CONTAINER-PATH))
generate-random-string = tr -dc A-Za-z0-9 </dev/urandom | head -c

# Services
WEBAPP-SERVICE ::= webapp
SERVICES = $(WEBAPP-SERVICE) $(EXTRA-SERVICES)
WEBAPP-DEBUG-SERVICE = $(WEBAPP-SERVICE)-debug

# Prefixes
logs-prefix ::= logs-
restart-prefix ::= restart-
stop-prefix ::= stop-
up-prefix ::= up-
down-prefix ::= down-
shell-prefix ::= shell-
start-prefix ::= start-

# Secrets
$(SECRETS_FOLDER):
	@mkdir -p $(@)

$(SECRETS_FOLDER)/%: $(SECRETS_FOLDER)
	@$(generate-random-string) 32 > $(@)

secrets: $(shell for secret in $(SECRETS_LIST); do printf "$(SECRETS_FOLDER)/$$secret "; done)  ## Generate random values for docker secrets


# Docker compose targets
build: ## Build all needed images from docker compose
	@$(COMPOSE-PRESET) build

up: secrets ## Docker compose up on all project files
	@$(COMPOSE-PRESET) up -d

up-servicename: ## Up the service named servicename

$(addprefix $(up-prefix), $(SERVICES)): $(up-prefix)%:
	@$(COMPOSE-DEBUG-PRESET) up -d $*

down: ## Docker compose down on all project files
	@$(COMPOSE-DEBUG-PRESET) down

$(addprefix $(down-prefix), $(SERVICES)): $(down-prefix)%:
	@$(COMPOSE-DEBUG-PRESET) up -d $*

down-servicename: ## Down the service named servicename

clean: ## Docker compose up on all project files, also delete all the volumes
	@$(COMPOSE-DEBUG-PRESET) down -v
	@rm -rf $(SECRETS_FOLDER)


# Webapp container targets
fix-ownership: ## Change ownership to user for all project files
	@$(fix-ownership-project)


# Services targets
list-services: ## List all declared docker compose services
	@echo $(SERVICES)

start-servicename: ## Start service named servicename

$(addprefix $(start-prefix), $(SERVICES)): $(start-prefix)%:
	@$(COMPOSE-DEBUG-PRESET) start $*

restart-servicename: ## restart service named servicename

$(addprefix $(restart-prefix), $(SERVICES)): $(restart-prefix)%:
	@$(COMPOSE-DEBUG-PRESET) restart $*

stop-servicename: ## Stop service named servicename

$(addprefix $(stop-prefix), $(SERVICES)): $(stop-prefix)%:
	@$(COMPOSE-DEBUG-PRESET) stop $*

shell-servicename: ## Open shell for service named servicename

$(addprefix $(shell-prefix), $(SERVICES)): $(shell-prefix)%:
	@$(DOCKER-EXEC) $* sh


# Logging targets
logs: ## Show all containers logs
	@$(DOCKER-LOGS)

logs-servicename: ## Show logs for service named servicename

$(addprefix $(logs-prefix), $(SERVICES)): $(logs-prefix)%:
	@$(DOCKER-LOGS) $*


.PHONY: secrets build up $(addprefix $(up-prefix), $(SERVICES)) down $(addprefix $(down-prefix), $(SERVICES)) clean fix-ownership list-services $(addprefix $(start-prefix), $(SERVICES)) $(addprefix $(restart-prefix), $(SERVICES)) $(addprefix $(stop-prefix), $(SERVICES)) $(addprefix $(shell-prefix), $(SERVICES)) log $(addprefix $(logs-prefix), $(SERVICES))
