spool step-2_user_authority_insert_c5.log;
set serveroutput on size 1000000;
set define off;
prompt --step-2_user_authority_insert_c5.sql

BEGIN
DBMS_OUTPUT.PUT_LINE(SYSTIMESTAMP);
END;
/



declare
v_sponsor varchar2(20):='curie';
t_num NUMBER :=0;

cursor c5 is
Select * from  alf_child_assoc@conn_stdb ch where child_node_id in (Select p.node_id from alf_node_properties@conn_stdb p join alf_qname q on q.id=p.qname_id
where p.STRING_VALUE like 'GROUP_'||v_sponsor||'_ST_C%' and q.local_name='authorityName');


n number(10);
Childcascade VARCHAR2(100) :='true'; --Change this to ture if child cascade required 
begin 

for i in c5 loop
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