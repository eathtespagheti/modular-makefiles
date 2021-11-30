.PHONY: nuke-git
nuke-git: ## Remove all files in gitignore and reset the git repo
	@-rm -rf $(shell for file in $$(find . -type f -name ".gitignore"); do dir="$$(dirname "$$file")"; grep -v "^#" "$$file" | grep -v "^$$" | sed "s#.*#$$dir/&#"; done)
	@git reset --hard
	@git clean -fd

.PHONY: update-submodules
update-submodules: ## Update all submodules
	@git pull --recurse-submodules --jobs=10

.PHONY: init-submodules
init-submodules: ## Initialize all submodules
	@git submodule update --init --recursive