/*
 * Author: info@bluetreble.com
 * Created at: 2015-07-14 21:19:38 -0500
 *
 */

--
-- This is a example code genereted automaticaly
-- by pgxn-utils.

SET client_min_messages = warning;

-- TODO: this fails if you try to install in two databases since roles are
--      cluster wide
-- CREATE ROLE test_factory__owner;
CREATE SCHEMA tf; -- AUTHORIZATION test_factory__owner;
COMMENT ON SCHEMA tf IS $$Test factory. Tools for maintaining test data.$$;
GRANT USAGE ON SCHEMA tf TO public;

CREATE SCHEMA _tf; -- AUTHORIZATION test_factory__owner;

-- SET ROLE test_factory__owner;

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

