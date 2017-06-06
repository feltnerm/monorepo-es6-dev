NPM_BIN = $(shell npm bin)
TRANSPILER = $(NPM_BIN)/babel
TRANSPILER_OPTS =
LINTER = $(NPM_BIN)/standard
LINTER_OPTS = --cache
LESS_LINTER = $(NPM_BIN)/lesshint
LESS_LINTER_OPTS =

# Directories
PKGS_ROOT := packages
PKGS_SRCDIR := src
PKGS_OUTDIR := lib
PKGS_TESTDIR := test

# Expands to the source directory for the specified package
pkg-srcdir = $(PKGS_ROOT)/$1/$(PKGS_SRCDIR)
# Expands to the output directory for the specified package
pkg-libdir = $(PKGS_ROOT)/$1/$(PKGS_OUTDIR)
# Expands to the test directory for the specified package
pkg-testdir = $(PKGS_ROOT)/$1/$(PKGS_TESTDIR)
# Expands to all output targets for the specified package
pkg-libs-js = $(addprefix $(call pkg-libdir,$1)/,$(patsubst %.jsx,%.js,$(notdir $(wildcard $(call pkg-srcdir,$1)/*.js*))))
pkg-libs-css = $(addprefix $(call pkg-libdir,$1)/,$(notdir $(wildcard $(call pkg-srcdir,$1)/*.less)))

# Defines the following rules for the specified package:
define pkg-rules

# build rule for .js(x) files
$(call pkg-libdir,$1)/%.js: $(call pkg-srcdir,$1)/%.js* | $(call pkg-libdir,$1)
	$(TRANSPILER) $(TRANSPILER_OPTS) --out-file $$@ $$^

# build rule for .less files
$(call pkg-libdir,$1)/%.less: $(call pkg-srcdir,$1)/%.less | $(call pkg-libdir,$1)
	cp $$^ $$@

# rule to create the output directory if missing
$(call pkg-libdir,$1):
	@mkdir $$@

# package rule to build all outputs
$1: install install-$1 $(call pkg-libs-js,$1) $(call pkg-libs-css,$1)

# test-package rule
test-$1: install install-$1 $1
	npm run test -- $(call pkg-testdir,$1)

# lesslint-package rule
lesslint-$1: install install-$1 $1
	$(LESS_LINTER) $(LESS_LINTER_OPTS) $(call pkg-srcdir,$1)

# lint-package rule
lint-$1: install install-$1 $1
	$(LINTER) $(LINTER_OPTS) $(call pkg-srcdir,$1) $(call pkg-testdir,$1)

# test-and-lint-package rule
check-$1: install install-$1 $1 lint-$1 lesslint-$1 test-$1

$(call pkg-srcdir,$1)/../node_modules:
	cd $(call pkg-srcdir,$1)/.. && npm install

# install-package rule to install
install-$1: $(call pkg-srcdir,$1)/../node_modules

# clean-package rule to remove the output directory
clean-$1:
	rm -rf $(call pkg-libdir,$1) $(call pkg-srcdir,$1)/../node_modules

# link-package rule to link the output directory
link-$1: $1
	cd $(call pkg-libdir,$1)/.. && npm link

# unlink-package rule to link the output directory
unlink-$1:
	cd $(call pkg-libdir,$1)/.. && npm link

# version-package rule to increment package version
# usage: make VERSION=major|minor|patch verison-<package-name>
# ex: make VERSION=patch version-foo
version-$1:
	bash scripts/version.sh $1 ${VERSION}

# publish-package rule to publish a package
publish-$1:
	cd $(call pkg-libdir,$1)/.. && npm publish

# release-package rule to release a new package
# usage: make VERSION=major|minor|patch release-<package-name>
# ex: make VERSION=patch release-foo
release-$1: clean-$1 $1 check-$1 version-$1 publish-$1

prerelease-$1: clean-$1 $1 check-$1 version-$1
	cd $(call pkg-libdir,$1)/.. && npm publish --tag beta

check-packages: check-$1
clean-packages: clean-$1
install-packages: install-$1
lesslint-packages: lesslint-$1
link-packages: link-$1
lint-packages: lint-$1
test-packages: test-$1

packages: install install-packages $1

.PHONY: $1 clean-$1 clean-packages check-packages
endef

# Creates rules for the specified package
add-pkg = $(eval $(call pkg-rules,$1))

# Create rules for all packages
PKGS := $(notdir $(wildcard $(PKGS_ROOT)/*))
$(foreach p,$(PKGS),$(call add-pkg,$p))

lint: install
	npm run lint

lesslint: install
	npm run lesshint

# test all the things!
test: install install-packages
	npm run test

# test-watch all the things!
test-watch: install install-packages packages
	npm run test -- --watch

check: install install-packages packages lint lesslint test

# watch packages for changes and re-run make
watch: install
	ls packages/*/src/* | entr -d $(MAKE) packages

# delete the node_modules
clean-node_modules:
	rm -rf node_modules

# cleanup everything (node_modules, transpiled packages, ...)
clean: clean-packages clean-node_modules

# install node_modules for packages
install: node_modules

# install node_modules for working on packages
node_modules: package.json
	npm install

# setup all the things!
all: install packages

# Will be filled in by pkg-rules
.PHONY: all clean clean-node_modules check

.DEFAULT_GOAL := all
