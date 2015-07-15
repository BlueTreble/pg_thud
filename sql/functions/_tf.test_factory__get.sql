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
