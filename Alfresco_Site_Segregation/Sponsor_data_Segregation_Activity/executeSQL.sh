#!/bin/bash
sqlplus /nolog << EOF
CONNECT ALFRESCO_OWNER/ALFRESCO_OWNER@"(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=sdxstst1.clebyiaywrjz.us-west-2.rds.amazonaws.com)(PORT=1521))(CONNECT_DATA=(SID=sdxstst1)))"

set serveroutput on size 1000000;
set define off;
prompt --step-3_Site_WF_insert_c2.sql


BEGIN
DBMS_OUTPUT.PUT_LINE(SYSTIMESTAMP);
END;
/

@step-3_Site_WF_insert_c2.sql

BEGIN
DBMS_OUTPUT.PUT_LINE(SYSTIMESTAMP);
END;
/

set define on;

spool on;

EXIT;
EOF
