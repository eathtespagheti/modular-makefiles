.DEFAULT_GOAL ?= help
from-dist-to-file = cp $(1).dist $(1)
DIST-FILES ?= $(shell find . -name "*.dist")

help: ## Print this message
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | cut -d ':' -f 2-100 | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

$(DIST-FILES:.dist=):
	@$(call from-dist-to-file,$(@))

generate-from-dist: $(DIST-FILES:.dist=) ## Generate default files from .dist files

clean-dist-files: ## Remove all files that could be regenrated form dist files
	@-rm $(DIST-FILES:.dist=)

nuke-git: ##
	@git reset --hard
	@git clean -fd

.PHONY: help generate-from-dist clean-dist-files