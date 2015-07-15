/*
 * Author: info@bluetreble.com
 * Created at: 2015-07-14 21:19:38 -0500
 *
 */

--
-- This is a example code genereted automaticaly
-- by pgxn-utils.

SET client_min_messages = warning;

CREATE SCHEMA tap;
GRANT USAGE ON SCHEMA tap TO public;
CREATE EXTENSION pgtap SCHEMA tap;
SET search_path = "$user", public, tap;

CREATE ROLE test_factory__owner;
CREATE SCHEMA tf AUTHORIZATION test_factory__owner;
COMMENT ON SCHEMA tf IS $$Test factory. Tools for maintaining test data.$$;
GRANT USAGE ON SCHEMA tf TO public;

CREATE SCHEMA _tf AUTHORIZATION test_factory__owner;

SET ROLE test_factory__owner;

CREATE TYPE tf.test_set AS (
	set_name		text
	, insert_sql	text
);

CREATE TABLE _tf.test_factory(
	factory_id		SERIAL		NOT NULL PRIMARY KEY
	, table_oid		oid			NOT NULL -- Can't do a FK to a catalog
-- TODO: shouldn't the next to columns be one column using the test_set type?
	, set_name		text		NOT NULL
	, insert_sql	text		NOT NULL
	, UNIQUE( table_oid, set_name )
);

-- Need to be SU
SET ROLE = DEFAULT;

CREATE OR REPLACE FUNCTION _tf.schema__getsert(
) RETURNS name SECURITY DEFINER LANGUAGE plpgsql AS $body$
BEGIN
  IF NOT EXISTS( SELECT 1 FROM pg_namespace WHERE nspname = '_test_data' ) THEN
    CREATE SCHEMA _test_data AUTHORIZATION test_factory__owner;
  END IF;

  RETURN '_test_data';
END
$body$;

SET ROLE test_factory__owner;

-- vi: expandtab ts=2 sw=2

CREATE OR REPLACE FUNCTION _tf.test_factory__get(
  table_name text
  , set_name _tf.test_factory.set_name%TYPE
) RETURNS _tf.test_factory LANGUAGE plpgsql AS $body$
<<f>>
DECLARE
  c_table_oid CONSTANT regclass := table_name;

  v_test_factory _tf.test_factory;
BEGIN
  SELECT * INTO STRICT v_test_factory
    FROM _tf.test_factory tf
    WHERE table_oid = c_table_oid
      AND tf.set_name = test_factory__get.set_name
  ;

  RETURN v_test_factory;
EXCEPTION
  WHEN no_data_found THEN
    RAISE 'No factory found for table "%", set name "%"', table_name, set_name;
END
$body$;

-- vi: expandtab ts=2 sw=2
CREATE OR REPLACE FUNCTION _tf.data_table_name(
  table_name text
  , set_name _tf.test_factory.set_name%TYPE
) RETURNS name LANGUAGE plpgsql AS $body$
DECLARE
  v_factory_id_text text;
  v_table_name name;

  v_name name;
BEGIN
  SELECT
      -- Get a fixed-width representation of ID. btrim shouldn't be necessary but it is
      '_' || btrim( to_char(
        factory_id
        -- Get a string of 0's long enough to hold a max-sized int
        , repeat( '0', length( (2^31-1)::int::text ) )
      ) )
      , c.relname
    INTO v_factory_id_text, v_table_name
    FROM _tf.test_factory__get( table_name, set_name ) f
      JOIN pg_class c ON c.oid = f.table_oid
      JOIN pg_namespace n ON n.oid = c.relnamespace
  ;

  v_name := v_table_name || v_factory_id_text;

  -- Was the name truncated?
  IF v_name <> (v_table_name || v_factory_id_text) THEN
    v_name := substring( v_table_name, length(v_name) - length(v_factory_id_text ) )
                || v_factory_id_text
    ;
  END IF;

  RETURN v_name;
END
$body$;

-- vi: expandtab ts=2 sw=2
CREATE OR REPLACE FUNCTION tf.register(
  table_name text
  , test_sets tf.test_set[]
) RETURNS void SECURITY DEFINER LANGUAGE plpgsql AS $body$
DECLARE
  c_table_oid CONSTANT regclass := table_name;
  v_set tf.test_set;
BEGIN
  FOREACH v_set IN ARRAY test_sets LOOP
    UPDATE _tf.test_factory
      SET insert_sql = v_set.insert_sql
      WHERE table_oid = c_table_oid
        AND set_name = v_set.set_name
    ;
    /*
     * There shouldn't be concurrency conflicts here. If there are I think it's
     * better to error than UPSERT.
     */
    IF NOT FOUND THEN
      INSERT INTO _tf.test_factory( table_oid, set_name, insert_sql )
        VALUES( c_table_oid, v_set.set_name, v_set.insert_sql )
      ;
    END IF;
  END LOOP;
END
$body$;

-- vi: expandtab sw=2 ts=2
CREATE OR REPLACE FUNCTION tf.get(
  r anyelement
  , set_name text
) RETURNS SETOF anyelement SECURITY DEFINER LANGUAGE plpgsql AS $body$
DECLARE
  c_table_name CONSTANT text := pg_typeof(r);
  -- This sanity-checks table_name for us
  c_data_table_name CONSTANT name := _tf.data_table_name( c_table_name, set_name );
  c_td_schema CONSTANT name := _tf.schema__getsert();

  sql text;
BEGIN
  sql := format(
    'SELECT * FROM %I.%I AS t'
    , c_td_schema
    , c_data_table_name 
  );
  RAISE DEBUG 'sql = %', sql;

  RETURN QUERY EXECUTE sql;
EXCEPTION
  WHEN undefined_table THEN
    DECLARE
      create_sql text;
    BEGIN
      SELECT format(
            $$
CREATE TABLE %I.%I AS
WITH i AS (
      %s
    )
  SELECT *
    FROM i
$$
            , c_td_schema
            , c_data_table_name
            , factory.insert_sql
          )
        INTO create_sql
        FROM _tf.test_factory__get( c_table_name, set_name ) factory
      ;

      RAISE DEBUG 'sql = %', sql;
      EXECUTE create_sql;
      RETURN QUERY EXECUTE sql;
    END;
END
$body$;

--select (tf.get('moo','moo')::moo).*;

-- vi: expandtab ts=2 sw=2

SET ROLE = DEFAULT;

-- vi: noexpandtab sw=4 ts=4
