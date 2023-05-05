#!/bin/ksh
##Please provide DB_LINK and SponsorName before execute this script
sqlplus /nolog << EOF
CONNECT admin/admin12345@"(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=sfdxval1.cvktmba5gbnx.us-east-1.rds.amazonaws.com)(PORT=1521))(CONNECT_DATA=(SID=SFDXVAL1)))"

spool alfresco_db_migration_script.log;
set serveroutput on size 1000000;
set define off;
prompt --alfresco_db_migration_script.sql


BEGIN
DBMS_OUTPUT.PUT_LINE(SYSTIMESTAMP);
END;
/
prompt --CREATING SUPPORTING TABLES
begin
PKG_ALF_UTILITIES.SP_ALF_DDL;
end;
/
BEGIN
DBMS_OUTPUT.PUT_LINE(SYSTIMESTAMP);
END;
/
prompt --MIGRATION PROCESS STARTED
begin
PKG_ALF_DB_MIGRATION.SP_ALF_DB_MIGRATION('@DB_LINK','SponsorName');
end;
/

BEGIN
DBMS_OUTPUT.PUT_LINE(SYSTIMESTAMP);
END;
/

set define on;

spool off;

EXIT;
EOF
