-- Need to be SU
-- TODO: Uncomment __owner related stuff once the problems are fixed
SET ROLE = DEFAULT;

CREATE OR REPLACE FUNCTION _tf.schema__getsert(
) RETURNS name SECURITY DEFINER LANGUAGE plpgsql AS $body$
BEGIN
  IF NOT EXISTS( SELECT 1 FROM pg_namespace WHERE nspname = '_test_data' ) THEN
    CREATE SCHEMA _test_data; -- AUTHORIZATION test_factory__owner;
  END IF;

  RETURN '_test_data';
END
$body$;

-- SET ROLE test_factory__owner;

-- vi: expandtab ts=2 sw=2

