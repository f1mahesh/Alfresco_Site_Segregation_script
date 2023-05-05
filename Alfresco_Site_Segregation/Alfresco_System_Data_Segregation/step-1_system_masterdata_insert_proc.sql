spool step-1_system_masterdata_insert_proc.log;
set serveroutput on size 1000000;
set define off;
prompt --step-1_system_masterdata_insert_proc.sql

BEGIN
DBMS_OUTPUT.PUT_LINE(SYSTIMESTAMP);
END;
/


BEGIN
INSERT into ALF_NAMESPACE Select * from ALF_NAMESPACE@conn_stdb order by 1;

INSERT into ALF_QNAME Select * from ALF_QNAME@conn_stdb order by 1;

INSERT into ALF_PROP_CLASS Select * from ALF_PROP_CLASS@conn_stdb order by 1;

INSERT into ALF_PERMISSION Select * from ALF_PERMISSION@conn_stdb order by 1;

INSERT into ALF_MIMETYPE Select * from ALF_MIMETYPE@conn_stdb order by 1;

INSERT into ALF_LOCALE Select * from ALF_LOCALE@conn_stdb order by 1;

INSERT into ALF_ENCODING Select * from ALF_ENCODING@conn_stdb order by 1;

--INSERT into ACT_RE_DEPLOYMENT Select * from ACT_RE_DEPLOYMENT@conn_stdb order by 1;

INSERT into ACT_GE_PROPERTY Select * from ACT_GE_PROPERTY@conn_stdb order by 1;

INSERT into ALF_SERVER Select * from ALF_SERVER@conn_stdb order by 1;

INSERT into ALF_APPLIED_PATCH Select * from ALF_APPLIED_PATCH@conn_stdb order by 1;

EXECUTE IMMEDIATE 'ALTER TABLE ALF_STORE DISABLE CONSTRAINT FK_ALF_STORE_ROOT';

INSERT into ALF_STORE Select * from ALF_STORE@conn_stdb order by 1; -- root node

begin
for i in (Select * from ALF_STORE@conn_stdb order by 1) loop
INSERT_NODE(i.ROOT_NODE_ID,0,'store_root_node','false');
end loop;
end;

EXECUTE IMMEDIATE 'ALTER TABLE ALF_STORE ENABLE CONSTRAINT FK_ALF_STORE_ROOT';

commit;
end;
/

BEGIN
DBMS_OUTPUT.PUT_LINE(SYSTIMESTAMP);
END;
/

spool off;