spool step-2_user_authority_insert_c2.log;

set serveroutput on size 1000000;

set define off;

prompt --step-2_user_authority_insert_c2.sql


BEGIN
DBMS_OUTPUT.PUT_LINE(SYSTIMESTAMP);
END;
/


declare
v_sponsor varchar2(20):='curie';
t_num NUMBER :=0;
cursor c2 is
Select * from ( Select LEVEL,SYS_CONNECT_BY_PATH(ch.QNAME_LOCALNAME, '/') Path,ch.* from alf_child_assoc@conn_stdb ch  START WITH  ch.parent_node_id in 
(Select id from tmp_alf_ids@conn_stdb  where protocol='workspace' and IDENTIFIER='SpacesStore' and  Path='/system/authorities/GROUP_site_'||v_sponsor)
CONNECT BY PRIOR  ch.child_node_id = ch.parent_node_id ) t
--where EXISTS (Select 1 from alf_node@conn_stdb n join alf_qname@conn_stdb q on q.id=n.type_qname_id where q.local_name='person' and n.id=t.child_node_id)
UNION ALL
--- Insert all the association with APP.SHARE for sponsor.
Select * from (Select LEVEL,SYS_CONNECT_BY_PATH(ch.QNAME_LOCALNAME, '/') Path,ch.* from alf_child_assoc@conn_stdb ch  START WITH  ch.parent_node_id in 
(Select id from tmp_alf_ids@conn_stdb  where protocol='workspace' and IDENTIFIER='SpacesStore' and  Path='/system/zones/APP.SHARE')
CONNECT BY PRIOR  ch.child_node_id = ch.parent_node_id and level<2 ) t
where t.path like '/GROUP_site_'||v_sponsor||'%';


n number(10);
Childcascade VARCHAR2(100) :='false'; --Change this to ture if child cascade required 
begin 

for i in c2 loop
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
