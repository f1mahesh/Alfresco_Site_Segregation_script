spool step-2_Alf-Store-data_insert_proc_v3.log;
set serveroutput on size 1000000;
set define off;
prompt --step-2_Alf-Store-data_insert_proc_v3.sql

BEGIN
DBMS_OUTPUT.PUT_LINE(SYSTIMESTAMP);
END;
/

declare
t_num NUMBER :=0;

cursor c1 is
Select * from (Select LEVEL,ch.* from alf_child_assoc@conn_stdb ch  START WITH  ch.parent_node_id in (Select root_node_id from alf_store@conn_stdb where protocol='user' and IDENTIFIER='alfrescoUserStore')
CONNECT BY PRIOR  ch.child_node_id = ch.parent_node_id -- and level < 4
and ch.QNAME_LOCALNAME in ('system','people','admin','abeecher','mjackson','API_User','arender')
ORDER BY 1,parent_node_id,child_node_id asc) t
UNION ALL
Select * from (Select LEVEL,ch.* from alf_child_assoc@conn_stdb ch  START WITH  ch.parent_node_id in (Select root_node_id from alf_store@conn_stdb where protocol='system' and IDENTIFIER='system')
CONNECT BY PRIOR  ch.child_node_id = ch.parent_node_id 
ORDER BY 1,parent_node_id,child_node_id asc)
UNION ALL
Select * from (Select LEVEL,ch.* from alf_child_assoc@conn_stdb ch  START WITH  ch.parent_node_id in (Select root_node_id from alf_store@conn_stdb where protocol='workspace' and IDENTIFIER='lightWeightVersionStore')
CONNECT BY PRIOR  ch.child_node_id = ch.parent_node_id  
ORDER BY 1,parent_node_id,child_node_id asc)
UNION ALL
Select * from (Select LEVEL,ch.* from alf_child_assoc@conn_stdb ch  START WITH  ch.parent_node_id in (Select root_node_id from alf_store@conn_stdb where protocol='archive' and IDENTIFIER='SpacesStore')
CONNECT BY PRIOR  ch.child_node_id = ch.parent_node_id  and level<2
ORDER BY 1,parent_node_id,child_node_id asc) t where  t.QNAME_LOCALNAME in ('admin')
UNION ALL 
Select * from (Select LEVEL,ch.* from alf_child_assoc@conn_stdb ch  START WITH  ch.parent_node_id in (Select root_node_id from alf_store@conn_stdb where protocol='workspace' and IDENTIFIER='SpacesStore')
CONNECT BY PRIOR  ch.child_node_id = ch.parent_node_id 
and ch.parent_node_id not in (Select t.CHILD_NODE_ID from (Select ch.* from alf_child_assoc@conn_stdb ch  START WITH  ch.parent_node_id in (Select root_node_id from alf_store@conn_stdb where protocol='workspace' and IDENTIFIER='SpacesStore')
CONNECT BY PRIOR  ch.child_node_id = ch.parent_node_id and level>2) t where t.qname_localname in ('company_home','system')) -- Skip child for company_home,system
ORDER BY 1,parent_node_id,child_node_id asc) t;

n number(10);
Childcascade VARCHAR2(100) :='false'; --Change this to true if child cascade required 
begin 

for i in c1 loop
t_num :=t_num+1;
INSERT_NODE(i.CHILD_NODE_ID,i.PARENT_NODE_ID,'child',Childcascade); 
if MOD(t_num,100)=0 then COMMIT; end if;
end loop;
commit;
dbms_output.put_line('Processing Completed for system And committed record count for c1: '||t_num );
end;
/

BEGIN
DBMS_OUTPUT.PUT_LINE(SYSTIMESTAMP);
END;
/

spool off;
