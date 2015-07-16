# ts-gremlin-test/Makefile

default: test o/documentation.lastran

install: o/all-installed.lastran

o/all-installed.lastran: o/maven-installed.lastran o/npm-installed.lastran o/tsd-installed.lastran
	touch $@

clean: clean-maven clean-npm clean-tsd clean-test clean-typescript clean-ts-java clean-doc clean-bundle
	rm -rf o

.PHONY: default install clean test

JAVAPKGS_MODULE_TS=lib/tsJavaModule.ts

### Maven

JAVA_SRC=$(shell find src -name '*.java')

install-maven: o/maven-installed.lastran

o/maven-installed.lastran: pom.xml $(JAVA_SRC) | o
	mvn -DskipTests=true clean package
	touch $@

clean-maven:
	rm -rf target o/maven-installed.lastran

.PHONY: install-maven clean-maven

### Mocha Unit Tests

UNIT_TESTS=$(filter-out %.d.ts, $(wildcard test/*.ts))
UNIT_TEST_OBJS=$(patsubst %.ts,%.js,$(UNIT_TESTS))
UNIT_TEST_RAN=$(patsubst %.ts,o/%.lastran,$(UNIT_TESTS))

$(UNIT_TEST_RAN): o/%.lastran: %.js o/all-installed.lastran
	node_modules/.bin/mocha --timeout 10s --reporter=spec --ui tdd $<
	mkdir -p $(dir $@) && touch $@

test: $(UNIT_TEST_RAN)

test/tinkerpop-test.js test/tinkerpop-test.js.map : lib/ts-tinkerpop.js $(JAVAPKGS_MODULE_TS)

clean-test:
	rm -f test/*.js test/*.js.map test/*.d.ts

.PHONY: test clean-test

### NPM

install-npm: o/npm-installed.lastran

o/npm-installed.lastran: | o
	npm install
	touch $@

clean-npm:
	rm -rf node_modules o/npm-installed.lastran

.PHONY: install-npm clean-npm

### TSD

TSD=./node_modules/.bin/tsd

install-tsd: o/tsd-installed.lastran

o/tsd-installed.lastran: o/npm-installed.lastran
	$(TSD) reinstall
	touch $@

update-tsd:
	$(TSD) update -o -s

clean-tsd:
	rm -rf typings o/tsd-installed.lastran

.PHONY: install-tsd update-tsd clean-tsd

### Typescript & Lint

TSC=./node_modules/.bin/tsc
TSC_OPTS=--module commonjs --target ES5 --sourceMap --declaration --noEmitOnError --noImplicitAny

LINT=./node_modules/.bin/tslint
LINT_OPTS=--config tslint.json --file

%.js %.js.map %.d.ts: %.ts o/all-installed.lastran $(JAVAPKGS_MODULE_TS)
	($(TSC) $(TSC_OPTS) $<) || (rm -f $*.js* && false)

clean-typescript:
	rm -f lib/*.js lib/*.js.map lib/*.d.ts

.PHONY: clean-typescript

### ts-java

ts-java: $(JAVAPKGS_MODULE_TS)

$(JAVAPKGS_MODULE_TS) : o/all-installed.lastran package.json
	node_modules/.bin/ts-java

clean-ts-java:
	rm -f $(JAVAPKGS_MODULE_TS)

.PHONY: ts-java clean-ts-java

### d.ts bundle

BUNDLE_DTS=lib/index.d.ts

O_BUNDLE_DTS=o/bundle.d.ts

$(O_BUNDLE_DTS): lib/ts-tinkerpop.d.ts devbin/bundle-dts.js
	devbin/bundle-dts.sh

$(BUNDLE_DTS): $(O_BUNDLE_DTS)
	echo '/// <reference path="../typings/java/java.d.ts"/>' > $@
	cat $(O_BUNDLE_DTS) >> $@

test/bundle-test.js: $(BUNDLE_DTS)

clean-bundle:
	rm -f devbin/bundle-dts.d.ts

.PHONY: clean-bundle

### Local d.ts file

# This module needs reference paths to the declaration file that would be generated by TSPI upon install.  We must
# generate this declaration file in our own typings directory.
LOCAL_DTS=typings/ts-tinkerpop/index.d.ts

TSPI=node_modules/.bin/ts-pkg-installer

$(LOCAL_DTS): lib/index.d.ts tspi-local.json
	$(TSPI) --config-file tspi-local.json

test/header-test.js: $(LOCAL_DTS)

### Documentation

documentation : o/documentation.lastran

o/documentation.lastran : o/npm-installed.lastran README.md lib/ts-tinkerpop.ts $(UNIT_TESTS) | o
	node_modules/.bin/groc --except "node_modules/**" --except "o/**" --except "**/*.d.ts" lib/ts-tinkerpop.ts $(UNIT_TESTS) README.md
	touch $@

clean-doc:
	rm -rf doc o/documentation.lastran

.PHONY: documentation clean-doc

### o (output) directory

o :
	mkdir -p o
