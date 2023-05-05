#!/bin/ksh
sqlplus /nolog << EOF
CONNECT admin/admin12345@"(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=sfdxval1.cvktmba5gbnx.us-east-1.rds.amazonaws.com)(PORT=1521))(CONNECT_DATA=(SID=SFDXVAL1)))"

spool sn_audit_migration.log;
set serveroutput on size 1000000;
set define off;
prompt --alter_alertnotification_index.sql


BEGIN
DBMS_OUTPUT.PUT_LINE(SYSTIMESTAMP);
END;
/

@sn_audit_migration.sql

BEGIN
DBMS_OUTPUT.PUT_LINE(SYSTIMESTAMP);
END;
/

set define on;

spool off;

EXIT;
EOF
