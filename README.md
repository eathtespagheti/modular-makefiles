# Modular Makefiles

Collection of docker based makefiles that work out of the box, note that everything follow the GNU Make specifications, so it isn't guaranteed to work on generic POSIX Make

## How to use it

Check [`Makefile`](Makefile) for an example on how to use this setup

## Setup

Every makefile extensions has some variables for setting it up, note that every custom value for those variables should be set **BEFORE** importing

### [common.mk](.makefiles/common.mk)

Contains common basic functions, like the help function that scans for comments in all the targets

### [docker.mk](.makefiles/docker.mk)

This extension [`docker.mk`](.makefiles/docker.mk) suppose you have a webapp service in a `docker-compose.y*ml` file, also it search for a `docker-compose.debug.y*ml` and a `docker-compose.dev*.y*ml` file.

Docker makefile behaviour can be customized with some variables:

* `COMPOSE`: define the executable name for docker compose (default to `docker compose` or `docker-compose`)
* `COMPOSE-FILES`: list of space separated docker-compose files to use, by default automatically finds them via `find`
* `COMPOSE-DEBUG-FILES`: list of space separated docker-compose debugging files, by default automatically finds them via `find`
* `EXTRA-COMPOSE-FILES`: list of extra docker compose files to include
* `WEBAPP-SERVICE`: name of the webapp service, default to `webapp`
* `WEBAPP-CONTAINER-PATH`: path of the webapp source code inside the `WEBAPP-SERVICE` container
* `EXTRA-SERVICES`: list of extra services for which makefile targets should be generated.
* `WEBAPP-DEBUG-SERVICE`: name of the debug service for webapp, defaults to `$(WEBAPP-SERVICE)-debug`
* `SECRETS_FOLDER`: folder where docker secrets should be stored, defaults to empty string
* `SECRETS_LIST`: list of space separated secrets files that should be present in `SECRETS_FOLDER`, defaults to empty string, when defined it automatically generate those files if they are missing (and write inside them a random 32 characters string)

### [django.mk](.makefiles/django.mk)

Setup for django applications.

Import [`docker.mk`](.makefiles/docker.mk) and change `WEBAPP-SERVICE` to `django`

There's an extra configurable variable, named `DB_FILE`, it define a filename where to write dumped data from django dumpdata, by default it's `db.json`

### [node.mk](.makefiles/node.mk)

Setup for node applications.

Import [`docker.mk`](.makefiles/docker.mk) and change `WEBAPP-SERVICE` to `node`, adds some node specific targets

## Write custom extensions

You can obliviously write some custom modules for this makefile setup, be sure to correctly use the comments to show correctly the help command (check it with `make help`).

The comments should be written right after a target requirements, and should start with `##`, check one of the makefiles for example
