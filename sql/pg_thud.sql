/*
 * Author: info@bluetreble.com
 * Created at: 2015-07-14 21:19:38 -0500
 *
 */

--
-- This is a example code genereted automaticaly
-- by pgxn-utils.

SET client_min_messages = warning;

-- If your extension will create a type you can
-- do somenthing like this
CREATE TYPE pg_thud AS ( a text, b text );

-- Maybe you want to create some function, so you can use
-- this as an example
CREATE OR REPLACE FUNCTION pg_thud (text, text)
RETURNS pg_thud LANGUAGE SQL AS 'SELECT ROW($1, $2)::pg_thud';

-- Sometimes it is common to use special operators to
-- work with your new created type, you can create
-- one like the command bellow if it is applicable
-- to your case

CREATE OPERATOR #? (
	LEFTARG   = text,
	RIGHTARG  = text,
	PROCEDURE = pg_thud
);
