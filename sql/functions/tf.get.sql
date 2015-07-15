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
