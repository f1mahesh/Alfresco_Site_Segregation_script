spool step-4_Alf-Store-6-Sub-data-part-2_insert_proc.log;
set serveroutput on size 1000000;
set define off;
prompt --step-4_Alf-Store-6-Sub-data-part-2_insert_proc.sql

BEGIN
DBMS_OUTPUT.PUT_LINE(SYSTIMESTAMP);
END;
/

declare
cursor c1 is
Select * from (Select LEVEL,SYS_CONNECT_BY_PATH(ch.qname_localname, '/') "Path",ch.* from alf_child_assoc@conn_stdb ch  START WITH  ch.parent_node_id in 
(Select id from tmp_alf_ids@conn_stdb  where protocol='workspace' and IDENTIFIER='SpacesStore' and path in ('/company_home/sites'))
CONNECT BY PRIOR  ch.child_node_id = ch.parent_node_id  and level < 2) t
where t."Path"  not in 
(Select '/'||p.string_value from alf_node_properties@conn_stdb p
join alf_node@conn_stdb n on n.id=p.node_id and n.type_qname_id in (Select id from alf_qname@conn_stdb where local_name='site')
where p.qname_id in (Select id from alf_qname@conn_stdb where local_name='name'))
;
    
t_num NUMBER :=0;
Childcascade VARCHAR2(100) :='true'; --Change this to true if child cascade required 
begin 

for i in c1 loop
t_num :=t_num+1;
INSERT_NODE(i.CHILD_NODE_ID,i.PARENT_NODE_ID,'child',Childcascade); 
if MOD(t_num,100)=0 then COMMIT; end if;
end loop;
COMMIT;
dbms_output.put_line('Processing Completed for system And committed record count for c1: '||t_num );
end;
/

BEGIN
DBMS_OUTPUT.PUT_LINE(SYSTIMESTAMP);
END;
/

spool off;