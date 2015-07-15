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
