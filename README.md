# Modular Makefiles

Collection of docker based makefiles that work out of the box

## How to use it

Check [`Makefile`](Makefile) for an example on how to use this setup

## Setup

### [docker.mk](.makefiles/docker.mk)

By default [`docker.mk`](.makefiles/docker.mk) suppose you have a webapp service in a `docker-compose.y*ml` file, also it search for a `docker-compose.debug.y*ml` file.

Docker makefile behaviour can be customized with some variables:

* `COMPOSE`: define the executable name for docker compose (default to `docker compose` or `docker-compose`)
* `COMPOSE-FILES`: list of space separated docker-compose files to use, by default automatically finds them via `find`
* `COMPOSE-DEBUG-FILES`: list of space separated docker-compose debugging files, by default automatically finds them via `find`
* `WEBAPP-SERVICE`: name of the webapp service, default to `webapp`
* `WEBAPP-CONTAINER-PATH`: path of the webapp source code inside the `WEBAPP-SERVICE` container
* `EXTRA-SERVICES`: list of extra services for which makefile targets should be generated. **This variable should be defines before importing [`docker.mk`](.makefiles/docker.mk)**
* `WEBAPP-DEBUG-SERVICE`: name of the debug service for webapp, defaults to `$(WEBAPP-SERVICE)-debug`
* `SECRETS_FOLDER`: folder where docker secrets should be stored, defaults to empty string
* `SECRETS_LIST`: list of space separated secrets files that should be present in `SECRETS_FOLDER`, defaults to empty string, when defined it automatically generate those files if they are missing (and write inside them a random 32 characters string)

### [django.mk](.makefiles/django.mk)

By default this setup import [`docker.mk`](.makefiles/docker.mk) and change `WEBAPP-SERVICE` to `django`

There's an extra configurable variable, named `DB_FILE`, it define a filename where to write dumped data from django dumpdata, by default it's `db.json`

## Write custom extensions

You can obliviously write some custom modules for this makefile setup, be sure to correctly use the comments to show correctly the help command (check it with `make help`).

The comments should be written right after a target requirements, and should start with `##`, check one of the makefiles for example
