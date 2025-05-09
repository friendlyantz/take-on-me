.DEFAULT_GOAL := usage

# user and repo
USER        = $$(whoami)
CURRENT_DIR = $(notdir $(shell pwd))

# terminal colours
RED     = \033[0;31m
GREEN   = \033[0;32m
YELLOW  = \033[0;33m
NC      = \033[0m
# versions
APP_REVISION    = $(shell git rev-parse HEAD)

.PHONY: install
install:
	bundle install

	docker run --name friendly-postgres-container \
	-e POSTGRES_USER=friendlyantz \
	-e POSTGRES_PASSWORD=password \
	-e POSTGRES_DB=take_on_me_development \
	-p 5432:5432 \
	-d postgres

.PHONY: test
test:
	bundle exec rspec

.PHONY: deploy
deploy:
	kamal deploy

.PHONY: server
server:
	bundle exec rails server

.PHONY: lint
lint:
	rake standard:fix

.PHONY: lint-unsafe
lint-unsafe:
	rake standard:fix_unsafely

.PHONY: lint-checkonly
lint-checkonly:
	rake standard

# .PHONY: audit-dependencies
# audit-dependencies:
# 	bundle exec bundle-audit

# .PHONY: ci
# ci: lint-checkonly audit-dependencies test

.PHONY: usage
usage:
	@echo
	@echo "Hi ${GREEN}${USER}!${NC} Welcome to ${RED}${CURRENT_DIR}${NC}"
	@echo
	@echo "Getting started"
	@echo
	@echo "${YELLOW}make install${NC}                  install dependencies"
	@echo "${YELLOW}make test${NC}                     run tests"
	@echo "${YELLOW}make deploy${NC}                   deploy"
	@echo "${YELLOW}make run${NC}                      launch app"
	@echo "${YELLOW}make lint${NC}                     lint app"
	@echo "${YELLOW}make lint-unsafe${NC}              lint app(UNSAFE)"
	@echo "${YELLOW}make lint-checkonly${NC}           check lintintg"
	@echo "${YELLOW}make audit-dependencies${NC}       security audit of dependencies"
	@echo "${YELLOW}make ci${NC}                       ci to check linting and run tests"
	@echo
