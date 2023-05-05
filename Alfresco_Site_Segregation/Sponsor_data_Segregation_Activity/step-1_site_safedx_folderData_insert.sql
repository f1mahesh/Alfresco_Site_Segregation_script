spool step-1_site_safedx_folderData_insert.log;
set serveroutput on size 1000000;
set define off;
prompt --step-1_site_safedx_folderData_insert.sql

BEGIN
DBMS_OUTPUT.PUT_LINE(SYSTIMESTAMP);
END;
/

declare
v_sponsor varchar2(20):='curie';
cursor c1 is
Select * from (Select LEVEL,ch.* from alf_child_assoc@conn_stdb ch  START WITH  ch.parent_node_id in 
(Select id from tmp_alf_ids@conn_stdb where protocol='workspace' and IDENTIFIER='SpacesStore' and path in ('/company_home/SafeDx/Sponsors','/company_home/sites'))
CONNECT BY PRIOR  ch.child_node_id = ch.parent_node_id and level<2) t
where t.QNAME_LOCALNAME in (v_sponsor);
    
n number(10);
Childcascade VARCHAR2(100) :='true'; --Change this to true if child cascade required 
begin 

for i in c1 loop
--dbms_output.put_line('Processing CHILD_NODE_ID :'||i.CHILD_NODE_ID ||' PARENT_NODE_ID:'||i.PARENT_NODE_ID);
INSERT_NODE(i.CHILD_NODE_ID,i.PARENT_NODE_ID,'child',Childcascade); 

end loop;
end;
/

BEGIN
DBMS_OUTPUT.PUT_LINE(SYSTIMESTAMP);
END;
/

spool off;
