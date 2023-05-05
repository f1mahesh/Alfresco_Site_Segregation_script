---#Table count validation (Note: Please execute table count proc in source and target DB to generate the table count post execution of all the segregation procs.)

Select s.tablename,s.count src_count,t.count trg_count,
case when t.count=s.count then 'Match' else 'Mismatch' end status
from tmp_src_tbl_cnt@conn_stdb s,tmp_trg_tbl_cnt t
where t.tablename=s.tablename
order by 4;

--#END#


--#Validate Associations 

Select * from alf_node_assoc@spdv a
where a.SOURCE_NODE_ID in (Select id from alf_node)
and not EXISTS (Select * from alf_node_assoc e where e.id=a.id )

--#END#

-- #Validate ACl inhertance : These query shoud not return any record.

Select * from alf_acl_change_set@spdv a where a.id in(
Select DISTINCT ACL_CHANGE_SET from alf_access_control_list@spdv where id in (Select DISTINCT a.INHERITED_ACL from alf_access_control_list a where 
not EXISTS (Select 1 from alf_access_control_list b where b.id=a.INHERITED_ACL)))
and not exists(select 1 from alf_acl_change_set e where a.id=e.id);

Select * from alf_access_control_list@spdv where id in (Select DISTINCT a.INHERITED_ACL from alf_access_control_list a where 
not EXISTS (Select 1 from alf_access_control_list b where b.id=a.INHERITED_ACL));

Select * from alf_acl_member@spdv a where a.acl_id in (Select id from alf_access_control_list a where 
not EXISTS (Select 1 from alf_acl_member b where b.acl_id=a.id));


Select * from alf_access_control_entry@spdv ae where ae.id in(
Select distinct ACE_ID from alf_acl_member@spdv where acl_id in (Select id from alf_access_control_list a where 
not EXISTS (Select 1 from alf_acl_member b where b.acl_id=a.id)))
and not EXISTS (Select 1 from alf_access_control_entry e where e.id=ae.id)

--#END#

