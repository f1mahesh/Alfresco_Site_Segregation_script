sqlplus ALFRESCO_OWNER/ALFRESCO_OWNER@"(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=sdxstst1.clebyiaywrjz.us-west-2.rds.amazonaws.com)(PORT=1521))(CONNECT_DATA=(SID=sdxstst1)))" << EOF
prompt --contentUrl.sql
@./contentUrl.sql


EOF
