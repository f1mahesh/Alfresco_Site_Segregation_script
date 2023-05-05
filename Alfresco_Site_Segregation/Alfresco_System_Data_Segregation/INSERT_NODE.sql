create or replace PROCEDURE INSERT_NODE(nodeId NUMBER,parentNodeId number, type VARCHAR2,Childcascade VARCHAR2) AS
c_nodeid NUMBER;
parent_node number;
node_type VARCHAR2(400);
v_trans_id VARCHAR2(1024);
content_id NUMBER(19,0);
people_id NUMBER;
user_homes_id NUMBER;
t_num NUMBER :=0;
V_SEQ NUMBER;
v_acl_ids ALF_NUM_ARRAY;
cursor c1 is
Select id from alf_node where id=nodeId;

cursor c2 is
Select long_value from alf_node_properties@PRF1_ALF_OWNER p
join alf_qname@PRF1_ALF_OWNER q on q.id=p.qname_id
where node_id in (nodeId) and q.local_name in ('content','preferenceValues','versionProperties','versionEdition','keyStore');

begin
open c1;
FETCH c1 into c_nodeid;

if c1%notfound then
--dbms_output.put_line('Processing Child:'||nodeId ||' Parent:'||parentNodeId||' Type:'||type);
Insert into alf_transaction Select * FROM alf_transaction@PRF1_ALF_OWNER a WHERE a.ID IN (Select  n.transaction_id from alf_node@PRF1_ALF_OWNER n WHERE n.id in (nodeId)) and not EXISTS (select 1 from alf_transaction e where e.id=a.id);

Select acl.Id BULK COLLECT into v_acl_ids from alf_access_control_list@PRF1_ALF_OWNER  acl START WITH
acl.id in (Select  n.acl_id from alf_node@PRF1_ALF_OWNER n WHERE n.id in (nodeId))
CONNECT BY NOCYCLE  acl.id = PRIOR acl.INHERITED_ACL;

SP_ALF_POPULATE_NUM_FILTER_LIST(nodeId,v_acl_ids,V_SEQ);

Insert into ALF_ACL_CHANGE_SET
Select * from ALF_ACL_CHANGE_SET@PRF1_ALF_OWNER a where a.id in (Select DISTINCT acl.ACL_CHANGE_SET from alf_access_control_list@PRF1_ALF_OWNER acl where acl.id in (Select FILTER_VALUES from TBL_ALF_NUM_FILTER where SEQUENCE_NO =V_SEQ))
and not EXISTS (select 1 from ALF_ACL_CHANGE_SET e where e.ID=a.ID);

Insert into alf_access_control_list
Select * from (Select * from alf_access_control_list@PRF1_ALF_OWNER where id in (Select FILTER_VALUES from TBL_ALF_NUM_FILTER where SEQUENCE_NO =V_SEQ)) a
where not EXISTS (select 1 from alf_access_control_list e where e.id=a.id);

begin
Insert into alf_node Select * from alf_node@PRF1_ALF_OWNER WHERE id in (nodeId);
EXCEPTION when OTHERS then
dbms_output.put_line('EXCEPTION in alf_node for :'||SUBSTR( DBMS_UTILITY.format_error_stack
                 || DBMS_UTILITY.format_error_backtrace, 1, 4000)|| 'Error Code :'|| SQLCODE || ' Node Id :'||nodeId);
end;

Insert into alf_node_properties Select * from alf_node_properties@PRF1_ALF_OWNER  where node_id in (nodeId);

Insert into ALF_NODE_ASPECTS Select * from ALF_NODE_ASPECTS@PRF1_ALF_OWNER where node_id in (nodeId);

begin
Insert into ALF_NODE_ASSOC Select * from ALF_NODE_ASSOC@PRF1_ALF_OWNER  where TARGET_NODE_ID in (nodeId);
EXCEPTION WHEN OTHERS
THEN
dbms_output.put_line('ALF_NODE_ASSOC CHECK_CONSTRAINT_VIOLATED for :'||SUBSTR( DBMS_UTILITY.format_error_stack
                 || DBMS_UTILITY.format_error_backtrace, 1, 4000)|| 'Error Code :'|| SQLCODE || ' Node Id :'||nodeId);
end;

--###Authority
Insert into ALF_AUTHORITY
Select * from ALF_AUTHORITY@PRF1_ALF_OWNER a where a.id in (Select authority_id from ALF_ACCESS_CONTROL_ENTRY@PRF1_ALF_OWNER where ID in
(SElect ace_id from ALF_ACL_MEMBER@PRF1_ALF_OWNER where acl_id in (Select FILTER_VALUES from TBL_ALF_NUM_FILTER where SEQUENCE_NO =V_SEQ)))
and not EXISTS (select 1 from ALF_AUTHORITY e where e.id=a.id)
;


Insert into ALF_ACCESS_CONTROL_ENTRY
Select * from ALF_ACCESS_CONTROL_ENTRY@PRF1_ALF_OWNER a where a.ID in (SElect ace_id from ALF_ACL_MEMBER@PRF1_ALF_OWNER where acl_id in (Select FILTER_VALUES from TBL_ALF_NUM_FILTER where SEQUENCE_NO =V_SEQ))
and not EXISTS (select 1 from ALF_ACCESS_CONTROL_ENTRY e where e.id=a.id);

Insert into ALF_ACL_MEMBER
Select * from ALF_ACL_MEMBER@PRF1_ALF_OWNER a where a.acl_id in (Select FILTER_VALUES from TBL_ALF_NUM_FILTER where SEQUENCE_NO =V_SEQ)
and not EXISTS (select 1 from ALF_ACL_MEMBER e where e.ID=a.ID);
--End Authority

--###Content

open c2;
FETCH c2 into content_id;
--dbms_output.put_line('content_id : '||content_id);
if c2%FOUND then
--dbms_output.put_line('Prcessing content_id : '||content_id);
Insert into ALF_CONTENT_URL Select * from ALF_CONTENT_URL@PRF1_ALF_OWNER a where a.id in (Select  DISTINCT content_URL_Id from ALF_CONTENT_DATA@PRF1_ALF_OWNER where id in (content_id))
and not EXISTS (select 1 from ALF_CONTENT_URL e where e.ID=a.ID);

Insert into ALF_CONTENT_DATA Select * from ALF_CONTENT_DATA@PRF1_ALF_OWNER a where a.id in (content_id)
and not EXISTS (select 1 from ALF_CONTENT_DATA e where e.ID=a.ID);

Insert into alf_audit_model Select * from alf_audit_model@PRF1_ALF_OWNER a where a.CONTENT_DATA_ID in (content_id)
and not EXISTS (select 1 from alf_audit_model e where e.ID=a.ID);
end if;
close c2;
--End content

else null ;--dbms_output.put_line('Node Exists : '||nodeId);
c_nodeid :=nodeId;
end if;

select local_name into node_type from alf_qname@PRF1_ALF_OWNER where id=(select type_qname_id from alf_node@PRF1_ALF_OWNER where id=nodeId);
if(node_type='person') then

Insert into alf_auth_status Select * from alf_auth_status@PRF1_ALF_OWNER a where a.username in
(Select p.STRING_VALUE from alf_node_properties@PRF1_ALF_OWNER p join alf_qname@PRF1_ALF_OWNER q on p.qname_id=q.id
where p.node_id=nodeId and p.qname_id=(Select id from alf_qname@PRF1_ALF_OWNER where LOCAL_NAME='userName'))
and not EXISTS (select 1 from alf_auth_status e where e.id=a.id);

--Associte to all the parents
Insert into alf_child_assoc Select * from  (Select ch.* from alf_child_assoc@PRF1_ALF_OWNER ch  START WITH  ch.child_node_id =nodeId
and ch.parent_node_id in (Select id from tmp_alf_ids@PRF1_ALF_OWNER where protocol='workspace' and IDENTIFIER='SpacesStore'
and path in ('/system/zones/AUTH.ALF','/system/zones/APP.DEFAULT','/system/authorities'))
CONNECT BY  ch.child_node_id = PRIOR ch.parent_node_id and LEVEL <2) a
where not EXISTS (select 1 from alf_child_assoc e where e.id=a.id);


Select id into user_homes_id from tmp_alf_ids@PRF1_ALF_OWNER where protocol='workspace' and IDENTIFIER='SpacesStore'
and path in ('/company_home/user_homes');

Select id into people_id from tmp_alf_ids@PRF1_ALF_OWNER where protocol='user' and IDENTIFIER='alfrescoUserStore'
and path in ('/system/people');

Select p.STRING_VALUE into v_trans_id from alf_node_properties@PRF1_ALF_OWNER p join alf_qname@PRF1_ALF_OWNER q on q.id=p.qname_id
where node_id in (nodeId) and q.local_name in ('userName');

--Associate to System User and User home folder
for k in (Select case when q.local_name='username' then people_id when q.local_name='name' then user_homes_id end PARENT_NODE_ID,p.node_id CHILD_NODE_ID 
from alf_node_properties@PRF1_ALF_OWNER p join alf_qname@PRF1_ALF_OWNER q on q.id=p.qname_id where p.STRING_VALUE in (v_trans_id) and q.local_name in ('name','username')) loop

INSERT_NODE(k.CHILD_NODE_ID,k.PARENT_NODE_ID,'systemUser','false');

end loop;

elsif(node_type='authorityContainer') then

Insert into ALF_AUTHORITY Select * from ALF_AUTHORITY@PRF1_ALF_OWNER a where authority in
(Select p.STRING_VALUE  from alf_node_properties@PRF1_ALF_OWNER p join alf_qname@PRF1_ALF_OWNER q on p.qname_id=q.id
where p.node_id=nodeId and p.qname_id=(Select id from alf_qname@PRF1_ALF_OWNER where LOCAL_NAME='authorityName'))
and not EXISTS (select 1 from ALF_AUTHORITY e where e.id=a.id);

Insert into alf_child_assoc Select * from (Select ch.* from alf_child_assoc@PRF1_ALF_OWNER ch  START WITH  ch.child_node_id =nodeId
and ch.parent_node_id in (Select id from tmp_alf_ids@PRF1_ALF_OWNER where protocol='workspace' and IDENTIFIER='SpacesStore'
and path in ('/system/zones/AUTH.ALF','/system/zones/APP.DEFAULT','/system/authorities'))
CONNECT BY  ch.child_node_id = PRIOR ch.parent_node_id and LEVEL <2) a
where not EXISTS (select 1 from alf_child_assoc e where e.id=a.id);

end if;


begin
Insert into alf_child_assoc Select * from alf_child_assoc@PRF1_ALF_OWNER a where (a.child_node_id in (nodeId) and a.PARENT_NODE_ID in (parentNodeId))
and not EXISTS (select 1 from alf_child_assoc e where e.id=a.id);
EXCEPTION WHEN OTHERS THEN
dbms_output.put_line('EXCEPTION in alf_child_assoc for :'||SUBSTR( DBMS_UTILITY.format_error_stack
                 || DBMS_UTILITY.format_error_backtrace, 1, 4000)|| 'Error Code :'|| SQLCODE || ' Child :'||nodeId||' Parent:'||parentNodeId);
end;

--Sub Child
if Childcascade='true' then
commit;
for k in (Select LEVEL,ch.* from alf_child_assoc@PRF1_ALF_OWNER ch  START WITH  ch.parent_node_id =nodeId --1050597
CONNECT BY PRIOR  ch.child_node_id = ch.parent_node_id
ORDER BY 1,parent_node_id,child_node_id asc) loop
t_num :=t_num+1;
INSERT_NODE(k.CHILD_NODE_ID,k.PARENT_NODE_ID,'subchild','false');
if MOD(t_num,100)=0 then COMMIT; end if;
end loop;
end if;
--End Sub Child

COMMIT;
close c1;
--RETURN c_nodeid;
EXCEPTION WHEN OTHERS
THEN dbms_output.put_line('INSERTALLNODE Proc Error Code-'||SUBSTR( DBMS_UTILITY.format_error_stack
                 || DBMS_UTILITY.format_error_backtrace, 1, 4000)|| 'Error Code :'|| SQLCODE || ' Node Id :'||nodeId);

END INSERT_NODE;