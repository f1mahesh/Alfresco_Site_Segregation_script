spool step-6_node_assco_fix.log;
set serveroutput on size 1000000;
set define off;
prompt --step-6_node_assco_fix.sql

BEGIN
DBMS_OUTPUT.PUT_LINE(SYSTIMESTAMP);
END;
/



--#Fix  Authority
declare
v_sponsor varchar2(20):='curie';
t_num NUMBER :=0;

cursor c1 is
Select * from  alf_child_assoc@conn_stdb ch where child_node_id in (select p.node_id from alf_node_properties@conn_stdb p 
join alf_qname@conn_stdb q on q.id=p.qname_id
where p.STRING_VALUE like 'GROUP_'||v_sponsor ||'_%' and q.local_name='authorityName')
minus
Select * from  alf_child_assoc ch where child_node_id in (select p.node_id from alf_node_properties p 
join alf_qname q on q.id=p.qname_id
where p.STRING_VALUE like 'GROUP_'||v_sponsor ||'_%' and q.local_name='authorityName');

n number(10);
Childcascade VARCHAR2(100) :='true'; --Change this to ture if child cascade required 
begin 

for i in c1 loop
t_num :=t_num+1;
INSERT_NODE(i.CHILD_NODE_ID,i.PARENT_NODE_ID,'child',Childcascade); 
if MOD(t_num,100)=0 then COMMIT; end if;
end loop;
COMMIT; 
dbms_output.put_line('Authority Fix Completed for '||v_sponsor||' And committed record count: '||t_num );
end;
/

--#Fix Missing person 

declare
t_num NUMBER :=0;

cursor c3 is
Select p.node_id from alf_node_properties@conn_stdb p 
join alf_qname@conn_stdb q on q.id=p.qname_id where 1=1
and q.local_name in ('userName')
and node_id in (Select  n.id from alf_node@conn_stdb n
join alf_qname@conn_stdb q on q.id=n.type_qname_id where 1=1
and q.local_name in ('person'))
and p.STRING_VALUE  in (
Select  p.string_value from alf_node_properties p join alf_qname q on q.id=p.qname_id where 1=1
and q.local_name in ('username')
and node_id in (Select  n.id from alf_node n
join alf_qname q on q.id=n.type_qname_id where 1=1
and q.local_name in ('user'))
minus
Select p.string_value from alf_node_properties p join alf_qname q on q.id=p.qname_id where 1=1
and q.local_name in ('userName')
and node_id in (Select  n.id from alf_node n
join alf_qname q on q.id=n.type_qname_id where 1=1
and q.local_name in ('person'))
);

BEGIN
for i in c3 loop
t_num :=t_num+1;
dbms_output.put_line('Prcessing person : '|| i.node_id);

for j in (Select t.* from (Select LEVEL,SYS_CONNECT_BY_PATH(ch.qname_localname, '/') "Path",ch.* from alf_child_assoc@conn_stdb ch  START WITH  ch.child_node_id in (i.node_id) CONNECT BY   PRIOR ch.child_node_id =  ch.parent_node_id) t) loop
INSERT_NODE(j.CHILD_NODE_ID,j.PARENT_NODE_ID,'child','false'); 
end loop;

if MOD(t_num,100)=0 then COMMIT; end if;
end loop;

commit;
END;
/

--#Fix system Users

declare
t_num NUMBER :=0;
v_sponsor varchar2(20):='curie';

cursor c4 is
 Select q.local_name ,(select local_name from alf_qname@conn_stdb where id=n.TYPE_QNAME_ID ) node_type,p.* from alf_node@conn_stdb n
join alf_node_properties@conn_stdb p on n.id=p.node_id
join alf_qname@conn_stdb q on q.id=p.qname_id
and q.local_name in ('userName','username','name')
and n.type_qname_id in (select id from alf_qname@conn_stdb where local_name in ('user','folder','person'))
and p.string_value in ('safed-facility-user-'||v_sponsor||'-member-id0','safedx'||v_sponsor||'integuser','safed-system-user-'||v_sponsor||'-member-id0');

BEGIN
for i in c4 loop
t_num :=t_num+1;
dbms_output.put_line('Processing system person : '|| i.node_id);

for j in (Select t.* from (Select LEVEL,SYS_CONNECT_BY_PATH(ch.qname_localname, '/') "Path",ch.* from alf_child_assoc@conn_stdb ch  START WITH  ch.child_node_id in (i.node_id) CONNECT BY   PRIOR ch.child_node_id =  ch.parent_node_id) t) loop
INSERT_NODE(j.CHILD_NODE_ID,j.PARENT_NODE_ID,'child','false'); 
end loop;

if MOD(t_num,100)=0 then COMMIT; end if;
end loop;

commit;
END;
/


--#Fix person mapping
BEGIN
INSERT into alf_child_assoc
Select * from alf_child_assoc@conn_stdb a where (a.child_node_id in (Select  n.id from alf_node n
join alf_qname q on q.id=n.type_qname_id where 1=1
and q.local_name in ('person')))
and not EXISTS (select 1 from alf_child_assoc e where e.id=a.id) 
and EXISTS (select 1 from alf_node n where n.id=a.PARENT_NODE_ID);

insert into alf_auth_status
Select * from alf_auth_status@conn_stdb  where username in ( 
Select p.STRING_VALUE from alf_node_properties p join alf_qname q on q.id=p.qname_id where 1=1
and q.local_name in ('username')
and node_id in (Select  n.id from alf_node n
join alf_qname q on q.id=n.type_qname_id where 1=1
and q.local_name in ('user'))
and not EXISTS (Select 1 from alf_auth_status  where username=p.STRING_VALUE)
and EXISTS (Select 1 from alf_auth_status@conn_stdb  where username=p.STRING_VALUE)
);

commit;
END;
/


--#Fix Missing Content 
declare
content_id NUMBER(19,0);
t_num NUMBER :=0;

cursor c2 is
SELECT p.long_value content_id FROM alf_node_properties p where p.LONG_VALUE <>0
and not EXISTS (select 1 from alf_content_data d where d.id=p.LONG_VALUE)
and EXISTS (select 1 from alf_content_data@conn_stdb cd where cd.id=p.LONG_VALUE);

BEGIN
for i in c2 loop
t_num :=t_num+1;
dbms_output.put_line('Processing content_id : '|| i.content_id);
Insert into ALF_CONTENT_URL Select * from ALF_CONTENT_URL@conn_stdb a where a.id in (Select  DISTINCT content_URL_Id from ALF_CONTENT_DATA@conn_stdb where id in (i.content_id))
and not EXISTS (select * from ALF_CONTENT_URL e where e.ID=a.ID);

Insert into ALF_CONTENT_DATA Select * from ALF_CONTENT_DATA@conn_stdb a where a.id in (i.content_id)
and not EXISTS (select * from ALF_CONTENT_DATA e where e.ID=a.ID);

Insert into alf_audit_model Select * from alf_audit_model@conn_stdb a where a.CONTENT_DATA_ID in (i.content_id)
and not EXISTS (select * from alf_audit_model e where e.ID=a.ID);

if MOD(t_num,100)=0 then COMMIT; end if;
end loop;
COMMIT; 
dbms_output.put_line('Fix Content Completed And committed record count: '||t_num );
end;
/


-- #Fix ACL Inheritance
BEGIN
INSERT into alf_acl_change_set 
Select * from alf_acl_change_set@conn_stdb a where a.id in(
Select DISTINCT ACL_CHANGE_SET from alf_access_control_list@conn_stdb where id in (Select DISTINCT a.INHERITED_ACL from alf_access_control_list a where 
not EXISTS (Select 1 from alf_access_control_list b where b.id=a.INHERITED_ACL)))
and not exists(select 1 from alf_acl_change_set e where a.id=e.id);
---
INSERT into alf_access_control_list
Select * from alf_access_control_list@conn_stdb where id in (Select DISTINCT a.INHERITED_ACL from alf_access_control_list a where 
not EXISTS (Select 1 from alf_access_control_list b where b.id=a.INHERITED_ACL));
---
Insert into alf_acl_member
Select * from alf_acl_member@conn_stdb a where a.acl_id in (Select id from alf_access_control_list a where 
not EXISTS (Select 1 from alf_acl_member b where b.acl_id=a.id));
---
Insert into alf_access_control_entry
Select * from alf_access_control_entry@conn_stdb ae where ae.id in(
Select distinct ACE_ID from alf_acl_member@conn_stdb where acl_id in (Select id from alf_access_control_list a where 
not EXISTS (Select 1 from alf_acl_member b where b.acl_id=a.id)))
and not EXISTS (Select 1 from alf_access_control_entry e where e.id=ae.id);

commit;
END;
/



--#Fix Associations
BEGIN 
insert into alf_node_assoc
Select * from alf_node_assoc@conn_stdb a
where a.TARGET_NODE_ID in (Select id from alf_node)
and not EXISTS (Select * from alf_node_assoc e where e.id=a.id )
and EXISTS (Select id from alf_node n where n.id=a.SOURCE_NODE_ID);
commit;
END;
/


--#Fix Transcation table Sequence
--declare
--trnx_maxid NUMBER;
--seq_maxid NUMBER;
--BEGIN
--Select max(id) into trnx_maxid from alf_transaction;
--SELECT last_number into seq_maxid FROM USER_SEQUENCES WHERE SEQUENCE_NAME = 'ALF_TRANSACTION_SEQ';
--if trnx_maxid < seq_maxid then
--EXECUTE IMMEDIATE 'DROP SEQUENCE "ALFRESCO_OWNER"."ALF_TRANSACTION_SEQ"';
--EXECUTE IMMEDIATE 'CREATE SEQUENCE  "ALFRESCO_OWNER"."ALF_TRANSACTION_SEQ"  MINVALUE 1 MAXVALUE 9999999999999999999999999999 INCREMENT BY 1 START WITH '||trnx_maxid||' CACHE 20 ORDER  NOCYCLE  NOKEEP  NOSCALE  GLOBAL';
--EXECUTE IMMEDIATE 'GRANT SELECT ON "ALFRESCO_OWNER"."ALF_TRANSACTION_SEQ" TO "SAFEDX_OWNER"';
--EXECUTE IMMEDIATE 'GRANT SELECT ON "ALFRESCO_OWNER"."ALF_TRANSACTION_SEQ" TO "RW_ALFRESCO_ROLE"';
--DBMS_OUTPUT.PUT_LINE('ALF_TRANSACTION_SEQ is updated');
--else 
--DBMS_OUTPUT.PUT_LINE('No change required in ALF_TRANSACTION_SEQ ');
--end if;
--
--END;
--/ 


BEGIN
DBMS_OUTPUT.PUT_LINE(SYSTIMESTAMP);
END;
/
spool off;
