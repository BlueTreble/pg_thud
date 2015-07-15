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
