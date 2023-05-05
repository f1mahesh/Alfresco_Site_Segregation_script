spool step-2_user_authority_insert_c4.log;
set serveroutput on size 1000000;
set define off;
prompt --step-2_user_authority_insert_c4.sql

BEGIN
DBMS_OUTPUT.PUT_LINE(SYSTIMESTAMP);
END;
/

declare
Childcascade VARCHAR2(100) :='false'; --Change this to ture if child cascade required 
v_sponsor varchar2(20):='curie';
t_num NUMBER :=0;

cursor c4 is
--Insert all the asscoiate childs for SF_Consumer AND CLD_Consumer
Select p.node_id from alf_node_properties@conn_stdb p join alf_qname@conn_stdb q on q.id=p.qname_id
where (p.STRING_VALUE like 'GROUP_'||v_sponsor||'_%_SF_Consumer' OR p.STRING_VALUE like 'GROUP_'||v_sponsor||'_%_CLD_Consumer'
OR p.STRING_VALUE like 'GROUP_'||v_sponsor||'_SF_Consumer') 
and q.local_name='authorityName';


begin 
	
for g in c4 loop

for i in (Select LEVEL,ch.CHILD_NODE_ID,ch.PARENT_NODE_ID from alf_child_assoc@conn_stdb ch  START WITH  ch.parent_node_id in (g.node_id) CONNECT BY PRIOR ch.child_node_id = ch.parent_node_id) loop
t_num :=t_num+1;
INSERT_NODE(i.CHILD_NODE_ID,i.PARENT_NODE_ID,'child',Childcascade); 
if MOD(t_num,100)=0 then COMMIT; end if;
end loop;

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
