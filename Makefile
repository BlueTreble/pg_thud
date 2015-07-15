EXTENSION = $(shell grep -m 1 '"name":' META.json | \
sed -e 's/[[:space:]]*"name":[[:space:]]*"\([^"]*\)",/\1/')
EXTVERSION = $(shell grep -m 1 '"version":' META.json | \
sed -e 's/[[:space:]]*"version":[[:space:]]*"\([^"]*\)",\{0,1\}/\1/')

DATA         = $(filter-out $(wildcard sql/*--*.sql),$(wildcard sql/*.sql))
DOCS         = $(wildcard doc/*.md)
TESTS        = $(wildcard test/sql/*.sql)
REGRESS      = $(patsubst test/sql/%.sql,%,$(TESTS))
REGRESS_OPTS = --inputdir=test --load-language=plpgsql
#
# Uncoment the MODULES line if you are adding C files
# to your extention.
#
#MODULES      = $(patsubst %.c,%,$(wildcard src/*.c))
PG_CONFIG    = pg_config
PG91         = $(shell $(PG_CONFIG) --version | grep -qE " 8\.| 9\.0" && echo no || echo yes)

EXTRA_CLEAN  = $(wildcard $(EXTENSION)-*.zip) sql/$(EXTENSION)--$(EXTVERSION).sql sql/$(EXTENSION).sql

sql/$(EXTENSION).sql: sql/tables.sql sql/footer.sql sql/functions/_tf.schema__getsert.sql sql/functions/_tf.test_factory__get.sql sql/functions/_tf.data_table_name.sql sql/functions/tf.register.sql sql/functions/tf.get.sql
	cat sql/tables.sql sql/functions/_tf.schema__getsert.sql sql/functions/_tf.test_factory__get.sql sql/functions/_tf.data_table_name.sql sql/functions/tf.register.sql sql/functions/tf.get.sql sql/footer.sql > sql/$(EXTENSION).sql

ifeq ($(PG91),yes)
all: sql/$(EXTENSION)--$(EXTVERSION).sql

sql/$(EXTENSION)--$(EXTVERSION).sql: sql/$(EXTENSION).sql
	cp $< $@

DATA = $(wildcard sql/*--*.sql) sql/$(EXTENSION)--$(EXTVERSION).sql
endif

PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)

# Don't have installcheck bomb on error
.IGNORE: installcheck

.PHONY: test
test: clean install installcheck
	@if [ -r regression.diffs ]; then cat regression.diffs; fi

.PHONY: results
results: test
	rsync -rlpgovP results/ test/expected

rmtag:
	@test -z "$$(git branch --list $(EXTVERSION))" || git branch -d $(EXTVERSION)

tag:
	@test -z "$$(git status --porcelain)" || (echo 'Untracked changes!'; echo; git status; exit 1)
	git branch $(EXTVERSION)
	git push --set-upstream origin $(EXTVERSION)

.PHONY: forcetag
forcetag: rmtag tag

dist: tag
	git archive --prefix=$(EXTENSION)-$(EXTVERSION)/ -o ../$(EXTENSION)-$(EXTVERSION).zip $(EXTVERSION)

.PHONY: forcedist
forcedist: forcetag dist

# To use this, do make print-VARIABLE_NAME
print-%  : ; @echo $* = $($*)
