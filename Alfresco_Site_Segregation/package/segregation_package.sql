spool segregation_package.log;

set serveroutput on size 1000000;

set define off;

prompt --segregation_package.sql
BEGIN
DBMS_OUTPUT.PUT_LINE(SYSTIMESTAMP);
END;
/

select name from v$database;

select Username FROM USER_USERS;

BEGIN
EXECUTE IMMEDIATE 'alter session set current_schema=ALFRESCO_OWNER';
END;
/
prompt --pkg_alf_utilities_spec.sql
@./segregation_package/pkg_alf_utilities_spec.sql
prompt --pkg_alf_utilities_body.sql
@./segregation_package/pkg_alf_utilities_body.sql

Begin
PKG_ALF_UTILITIES.SP_ALF_DDL;
end ;
/
prompt --pkg_alf_db_migration_spec.sql
@./segregation_package/pkg_alf_db_migration_spec.sql
prompt --pkg_alf_db_migration_body.sql
@./segregation_package/pkg_alf_db_migration_body.sql

BEGIN
DBMS_OUTPUT.PUT_LINE(SYSTIMESTAMP);
END;
/

set define on;

spool off;