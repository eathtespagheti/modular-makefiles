.DEFAULT_GOAL ?= help
from-dist-to-file = cp $(1).dist $(1)
DIST-FILES ?= $(shell find . -name "*.dist")

.PHONY: help
help: ## Print this message
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | cut -d ':' -f 2-100 | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

__DIST_FILES_NO_EXTENSION := $(DIST-FILES:.dist=)
.PHONY: $(__DIST_FILES_NO_EXTENSION)
$(__DIST_FILES_NO_EXTENSION):
	@$(call from-dist-to-file,$(@))

.PHONY: generate-from-dist
generate-from-dist: $(__DIST_FILES_NO_EXTENSION) ## Generate default files from .dist files

.PHONY: clean-dist-files
clean-dist-files: ## Remove all files that could be regenrated form dist files
	@-rm $(__DIST_FILES_NO_EXTENSION)

.PHONY: nuke-git
nuke-git: ## Remove all files in gitignore and reset the git repo
	@-rm -rf $(shell for file in $$(find . -type f -name ".gitignore"); do dir="$$(dirname "$$file")"; grep -v "^#" "$$file" | grep -v "^$$" | sed "s#.*#$$dir/&#"; done)
	@git reset --hard
	@git clean -fd
