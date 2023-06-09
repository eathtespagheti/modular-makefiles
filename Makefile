include .makefiles/common.mk
include .makefiles/git.mk
include .makefiles/docker.mk
include .makefiles/codebuild.mk

.PHONY: clean
clean: ## Launch all the clean targets
	@$(MAKE) clean-dist-files
	@$(MAKE) clean-docker

.PHONY: nuke-force
nuke-force:
	@-$(MAKE) fix-ownership
	@-$(MAKE) clean
	@-$(MAKE) nuke-docker
	@-$(MAKE) nuke-git

.PHONY: nuke
nuke: ## Launch all the nuke targets
	@read -p "Type 'yes' to continue: " response; \
	[ "$$response" = "yes" ] && make nuke-force || echo "Nuke aborted"
