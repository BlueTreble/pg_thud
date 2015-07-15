EXTENSION    = pg_thud
EXTVERSION   = $(shell grep default_version $(EXTENSION).control | sed -e "s/default_version[[:space:]]*=[[:space:]]*'\([^']*\)'/\1/")

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

ifeq ($(PG91),yes)
all: sql/$(EXTENSION)--$(EXTVERSION).sql

sql/$(EXTENSION)--$(EXTVERSION).sql: sql/$(EXTENSION).sql
	cp $< $@

sql/$(EXTENSION).sql: sql/tables.sql sql/footer.sql sql/functions/_tf.schema__getsert.sql sql/functions/_tf.test_factory__get.sql sql/functions/_tf.data_table_name.sql sql/functions/tf.register.sql sql/functions/tf.get.sql
	cat sql/tables.sql sql/functions/_tf.schema__getsert.sql sql/functions/_tf.test_factory__get.sql sql/functions/_tf.data_table_name.sql sql/functions/tf.register.sql sql/functions/tf.get.sql sql/footer.sql > sql/$(EXTENSION).sql


DATA = $(wildcard sql/*--*.sql) sql/$(EXTENSION)--$(EXTVERSION).sql
EXTRA_CLEAN = sql/$(EXTENSION)--$(EXTVERSION).sql sql/$(EXTENSION).sql
endif

PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)
