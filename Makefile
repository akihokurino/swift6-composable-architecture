MAKEFLAGS=--no-builtin-rules --no-builtin-variables --always-make
ROOT := $(realpath $(dir $(lastword $(MAKEFILE_LIST))))

vendor:
	yarn install

download-gql-schema:
	./node_modules/.bin/get-graphql-schema https://polog-315401.an.r.appspot.com/graphql > ./graphql/schema.graphqls

apollo-generate:
	./apollo-ios-cli generate

config-generate:
	@ENV_PATH=$(ROOT)/.env; \
	. $$ENV_PATH; \
	export $$(cut -d= -f1 $$ENV_PATH); \
	envsubst < template.xcconfig > Polog/Config.xcconfig