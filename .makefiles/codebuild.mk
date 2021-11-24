include .makefiles/docker.mk

ECR_REGION ?= eu-west-1
ECR ?= 123456789.dkr.ecr.$(ECR_REGION).amazonaws.com
CODEBUILD_ENVIRONMENT ?= public.ecr.aws/codebuild/amazonlinux2-x86_64-standard:3.0
CODEBUILD_ARTIFACTS ?= .aws/artifacts
CODEBUILD_SCRIPT ?= .aws/codebuild_build.sh
CODEBUILD_ENV ?= .aws/.env
BUILDSPEC_FILE ?= $(shell find . -name "buildspec.y*ml" | head -n 1)
MFA_TOKEN_GENERATOR ?= .aws/generateAWStoken.sh

.PHONY: ecr-docker-login
ecr-docker-login: ## Login to ECR via docker
	@aws ecr get-login-password --region $(ECR_REGION) | docker login --username AWS --password-stdin $(ECR)

$(CODEBUILD_SCRIPT): ## Install the codebuild build tool
	@curl -o $@ https://raw.githubusercontent.com/aws/aws-codebuild-docker-images/master/local_builds/codebuild_build.sh
	@chmod +x $@

$(CODEBUILD_ENV): $(shell find .git -type f)
	@echo CODEBUILD_RESOLVED_SOURCE_VERSION="$$(git rev-parse --short HEAD)" > $@

.PHONY: codebuild
codebuild: $(CODEBUILD_SCRIPT) $(CODEBUILD_ENV) ## Run aws codebuild
	./$(CODEBUILD_SCRIPT) -i $(CODEBUILD_ENVIRONMENT) -a $(CODEBUILD_ARTIFACTS) -b $(BUILDSPEC_FILE) -e $(CODEBUILD_ENV) -c

imagedefinitions.json: $(ALL-COMPOSE-FILES) ## Generate the image definitions
	@$(DOCKER-RUN) -d $(WEBAPP-SERVICE) sleep 5
	@DOCKER_IMAGE="$$($(COMPOSE-ALL-PRESET) images | head -n 2 | tail -n +2 | awk '{print $$2}')" && [ -z "$$DOCKER_TAG" ] && DOCKER_TAG="$$($(COMPOSE-ALL-PRESET) images | head -n 2 | tail -n +2 | awk '{print $$3}')"; \
	printf '[{"name":"%s","imageUri":"%s"}]' "$(WEBAPP-SERVICE)" "$$DOCKER_IMAGE:$$DOCKER_TAG" > imagedefinitions.json

$(MFA_TOKEN_GENERATOR):
	@curl -o $@ https://raw.githubusercontent.com/ofcourseme/aws-cli-mfa-helper/development/generateAWStoken.sh
	@chmod +x $@

.PHONY: aws-cli-mfa-token-generator
aws-cli-mfa-token-generator: $(MFA_TOKEN_GENERATOR) ## Automatically generate MFA tokens for aws-cli, based on https://github.com/ofcourseme/aws-cli-mfa-token-generator
	@$(MFA_TOKEN_GENERATOR)