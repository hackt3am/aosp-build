device = ${DEVICE}
userid = $(shell id -u)
groupid = $(shell id -g)

.DEFAULT_GOAL := default

contain := \
	docker run -it -h "android" \
		-v $(PWD):/home/build \
		-u $(userid):$(userid) \
		-e DEVICE=$(device) \
		hashbang/os

default: build

image:
	@docker build \
		--build-arg UID=$(userid) \
		--build-arg GID=$(groupid) \
		-t hashbang/os:latest .

manifest: image
	$(contain) manifest

config: manifest
	$(contain) config

fetch:
	@$(contain) fetch

tools: fetch
	@$(contain) tools

keys: tools
	@$(contain) keys

build: tools
	@$(contain) build

kernel: tools
	@$(contain) build-kernel

vendor: tools
	@$(contain) build-vendor

chromium: tools
	@$(contain) build-chromium

release: tools
	@$(contain) release

compare:
	@rm -rf compare && \
	mkdir -p compare && \
	$(contain) clean && \
	$(contain) build && \
	$(contain) release && \
	mv release/$(device)/* compare/a && \
	$(contain) clean && \
	$(contain) build && \
	$(contain) release && \
	mv release/$(device)/* compare/b && \
	$(contain) diffoscope \
		--text compare/diff.txt \
		--markdown compare/diff.md \
		--json compare/diff.json \
		compare/a/*factory*.zip \
		compare/b/*factory*.zip

shell:
	@$(contain) shell

diff:
	@$(contain) bash -c "cd base; repo diff -u"

clean: image
	@$(contain) clean

install: tools
	@scripts/flash

.PHONY: image build shell diff install update flash clean tools default
