spool step-4_archive_insert.log;
set serveroutput on size 1000000;
set define off;
prompt --step-4_archive_insert.sql

BEGIN
DBMS_OUTPUT.PUT_LINE(SYSTIMESTAMP);
END;
/

--Run with cascade true
declare
v_sponsor varchar2(20):='curie';
t_num NUMBER :=0;
cursor c1 is
Select * from (Select LEVEL,ch.* from alf_child_assoc@conn_stdb ch  START WITH  ch.parent_node_id in (Select root_node_id from alf_store@conn_stdb where protocol='archive' and IDENTIFIER='SpacesStore')
CONNECT BY PRIOR  ch.child_node_id = ch.parent_node_id
ORDER BY 1,parent_node_id,child_node_id asc) t 
where EXISTS (Select tq.local_name,tp.* from alf_node_properties@conn_stdb tp join alf_qname@conn_stdb tq on tq.id=tp.qname_id 
where tp.node_id in (t.CHILD_NODE_ID) and tq.local_name in ('sponsorName') and tp.string_value=v_sponsor 
);
    
n number(10);
Childcascade VARCHAR2(100) :='true'; --Change this to true if child cascade required 
begin 

for i in c1 loop
t_num :=t_num+1;
--dbms_output.put_line('Processing CHILD_NODE_ID :'||i.CHILD_NODE_ID ||' PARENT_NODE_ID:'||i.PARENT_NODE_ID);
INSERT_NODE(i.CHILD_NODE_ID,i.PARENT_NODE_ID,'child',Childcascade); 
if MOD(t_num,100)=0 then COMMIT; end if;
end loop;
COMMIT; 
dbms_output.put_line('Processing Completed for '||v_sponsor||' And committed record count: '||t_num );
end;
/

BEGIN
DBMS_OUTPUT.PUT_LINE(SYSTIMESTAMP);
END;
/

spool off;
