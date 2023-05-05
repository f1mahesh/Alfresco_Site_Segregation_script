spool step-3_Site_WF_insert_c1.log;
set serveroutput on size 1000000;
set define off;
prompt --step-3_Site_WF_insert_c1.sql

BEGIN
DBMS_OUTPUT.PUT_LINE(SYSTIMESTAMP);
END;
/
declare
v_sponsor varchar2(20):='curie';
t_num NUMBER :=0;

cursor c1 is
Select q.local_name,c.* from alf_child_assoc@PRF1_ALF_OWNER c 
join alf_qname@PRF1_ALF_OWNER q on q.id=c.type_qname_id 
where child_node_id in (Select n.id from alf_node@PRF1_ALF_OWNER n join tmp_wf_alf_uuid@PRF1_ALF_OWNER w on n.uuid=w.uuid);


    
n number(10);
Childcascade VARCHAR2(100) :='true'; --Change this to ture if child cascade required

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
