\set ECHO none
\ir sql/parameters.conf
\set ECHO all

-- Before running this file User must create database mysql_fdw_regress on
-- MySQL with all permission for 'edb' user with 'edb' password and ran
-- mysql_init.sh file to create tables.

\c contrib_regression
--Testcase 1:
CREATE EXTENSION IF NOT EXISTS mysql_fdw;
--Testcase 2:
CREATE SERVER mysql_svr FOREIGN DATA WRAPPER mysql_fdw
  OPTIONS (host :MYSQL_HOST, port :MYSQL_PORT);
--Testcase 3:
CREATE USER MAPPING FOR public SERVER mysql_svr
  OPTIONS (username :MYSQL_USER_NAME, password :MYSQL_PASS);

-- Create foreign table and Validate
--Testcase 4:
CREATE FOREIGN TABLE f_mysql_test(a int, b int)
  SERVER mysql_svr OPTIONS (dbname 'mysql_fdw_regress', table_name 'mysql_test');
--Testcase 5:
SELECT * FROM f_mysql_test ORDER BY 1, 2;

-- FDW-121: After a change to a pg_foreign_server or pg_user_mapping catalog
-- entry, existing connection should be invalidated and should make new
-- connection using the updated connection details.

-- Alter SERVER option.
-- Set wrong host, subsequent operation on this server should use updated
-- details and fail as the host address is not correct.
ALTER SERVER mysql_svr OPTIONS (SET host 'localhos');
--Testcase 6:
SELECT * FROM f_mysql_test ORDER BY 1, 2;

-- Set the correct host-name, next operation should succeed.
ALTER SERVER mysql_svr OPTIONS (SET host :MYSQL_HOST);
--Testcase 7:
SELECT * FROM f_mysql_test ORDER BY 1, 2;

-- Alter USER MAPPING option.
-- Set wrong user-name and password, next operation should fail.
ALTER USER MAPPING FOR PUBLIC SERVER mysql_svr
  OPTIONS (SET username 'foo1', SET password 'bar1');
--Testcase 8:
SELECT * FROM f_mysql_test ORDER BY 1, 2;

-- Set correct user-name and password, next operation should succeed.
ALTER USER MAPPING FOR PUBLIC SERVER mysql_svr
  OPTIONS (SET username :MYSQL_USER_NAME, SET password :MYSQL_PASS);
--Testcase 9:
SELECT * FROM f_mysql_test ORDER BY 1, 2;

-- Cleanup
--Testcase 10:
DROP FOREIGN TABLE f_mysql_test;
--Testcase 11:
DROP USER MAPPING FOR public SERVER mysql_svr;
--Testcase 12:
DROP SERVER mysql_svr;
--Testcase 13:
DROP EXTENSION mysql_fdw;
