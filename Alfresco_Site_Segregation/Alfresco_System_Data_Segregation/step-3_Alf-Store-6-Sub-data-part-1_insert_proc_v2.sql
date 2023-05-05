spool step-3_Alf-Store-6-Sub-data-part-1_insert_proc_v2.log;
set serveroutput on size 1000000;
set define off;
prompt --step-3_Alf-Store-6-Sub-data-part-1_insert_proc_v2.sql

BEGIN
DBMS_OUTPUT.PUT_LINE(SYSTIMESTAMP);
END;
/

declare
t_num NUMBER :=0;
Childcascade VARCHAR2(100) :='false'; --Change this to true if child cascade required 

cursor c1 is
Select * from (Select LEVEL,SYS_CONNECT_BY_PATH(ch.qname_localname, '/') "Path",ch.* from alf_child_assoc@conn_stdb ch  START WITH  ch.parent_node_id in 
(Select t.CHILD_NODE_ID from (Select LEVEL,SYS_CONNECT_BY_PATH(ch.qname_localname, '/') "Path",ch.* from alf_child_assoc@conn_stdb ch START WITH ch.parent_node_id in (Select root_node_id from alf_store@conn_stdb where protocol='workspace' and IDENTIFIER='SpacesStore')
CONNECT By PRIOR  ch.child_node_id = ch.parent_node_id AND LEVEL <= 1) t where t."Path" in ('/company_home'))
CONNECT BY PRIOR  ch.child_node_id = ch.parent_node_id 
and ch.parent_node_id not in (Select t.CHILD_NODE_ID from (Select LEVEL,SYS_CONNECT_BY_PATH(ch.qname_localname, '/') "Path",ch.* from alf_child_assoc@conn_stdb ch START WITH ch.parent_node_id in (Select root_node_id from alf_store@conn_stdb where protocol='workspace' and IDENTIFIER='SpacesStore')
CONNECT By PRIOR  ch.child_node_id = ch.parent_node_id AND LEVEL <= 2) t
where t."Path" in ('/company_home/SafeDx','/company_home/sites','/company_home/user_homes')) -- Skip child for user_homes,sites,SafeDx
ORDER BY 1,parent_node_id,child_node_id asc) t;

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

declare
t_num NUMBER :=0;
Childcascade VARCHAR2(100) :='false';

cursor c2 is
Select * from (Select LEVEL,SYS_CONNECT_BY_PATH(ch.qname_localname, '/') "Path",ch.* from alf_child_assoc@conn_stdb ch  START WITH  ch.parent_node_id in (Select t.CHILD_NODE_ID from (Select LEVEL,SYS_CONNECT_BY_PATH(ch.qname_localname, '/') "Path",ch.* from alf_child_assoc@conn_stdb ch START WITH ch.parent_node_id in (Select root_node_id from alf_store@conn_stdb where protocol='workspace' and IDENTIFIER='SpacesStore')
CONNECT By PRIOR  ch.child_node_id = ch.parent_node_id AND LEVEL <= 2) t where t."Path" in ('/company_home/user_homes'))
CONNECT BY PRIOR  ch.child_node_id = ch.parent_node_id 
ORDER BY 1,parent_node_id,child_node_id asc) t
where t.child_node_id in (Select p.node_id from alf_node_properties p
join alf_qname@conn_stdb q on p.qname_id=q.id 
where p.STRING_VALUE in ('admin','guest','abeecher','mjackson','API_User','arender')
and p.qname_id in (Select id from alf_qname@conn_stdb where LOCAL_NAME='name'));

begin 
for i in c2 loop
t_num :=t_num+1;
INSERT_NODE(i.CHILD_NODE_ID,i.PARENT_NODE_ID,'child',Childcascade); 
if MOD(t_num,100)=0 then COMMIT; end if;
end loop;
COMMIT;
dbms_output.put_line('Processing Completed for system And committed record count for c2: '||t_num );
end;
/


declare
t_num NUMBER :=0;
Childcascade VARCHAR2(100) :='false';

cursor c3 is
Select * from (Select LEVEL,SYS_CONNECT_BY_PATH(ch.qname_localname, '/') "Path",ch.* from alf_child_assoc@conn_stdb ch  START WITH  ch.parent_node_id in (Select t.CHILD_NODE_ID from (Select LEVEL,SYS_CONNECT_BY_PATH(ch.qname_localname, '/') "Path",ch.* from alf_child_assoc@conn_stdb ch START WITH ch.parent_node_id in (Select root_node_id from alf_store@conn_stdb where protocol='workspace' and IDENTIFIER='SpacesStore')
CONNECT By PRIOR  ch.child_node_id = ch.parent_node_id AND LEVEL <= 2) t where t."Path" in ('/company_home/SafeDx'))
CONNECT BY PRIOR  ch.child_node_id = ch.parent_node_id  
and ch.parent_node_id not in (Select id from tmp_alf_ids@conn_stdb where protocol='workspace' and IDENTIFIER='SpacesStore' and path='/company_home/SafeDx/Sponsors') -- Skip child for Sponsors
ORDER BY 1,parent_node_id,child_node_id asc) t;
begin 
for i in c3 loop
t_num :=t_num+1;
INSERT_NODE(i.CHILD_NODE_ID,i.PARENT_NODE_ID,'child',Childcascade); 
if MOD(t_num,100)=0 then COMMIT; end if;
end loop;
COMMIT;
dbms_output.put_line('Processing Completed for system And committed record count for c3: '||t_num );
end;
/

BEGIN
DBMS_OUTPUT.PUT_LINE(SYSTIMESTAMP);
END;
/

declare
t_num NUMBER :=0;
Childcascade VARCHAR2(100) :='false';

cursor c4 is
Select * from (Select LEVEL,SYS_CONNECT_BY_PATH(ch.qname_localname, '/') "Path",ch.* from alf_child_assoc@conn_stdb ch  START WITH  ch.parent_node_id in (Select t.CHILD_NODE_ID from (Select LEVEL,SYS_CONNECT_BY_PATH(ch.qname_localname, '/') "Path",ch.* from alf_child_assoc@conn_stdb ch  START WITH  ch.parent_node_id in 
(Select root_node_id from alf_store@conn_stdb where protocol='workspace' and IDENTIFIER='SpacesStore') CONNECT BY PRIOR  ch.child_node_id = ch.parent_node_id and level<=1) t 
where t."Path" in ('/system')) CONNECT BY PRIOR  ch.child_node_id = ch.parent_node_id 
and ch.parent_node_id not in (Select t.CHILD_NODE_ID from (Select LEVEL,SYS_CONNECT_BY_PATH(ch.qname_localname, '/') "Path",ch.* from alf_child_assoc@conn_stdb ch START WITH ch.parent_node_id in 
(Select root_node_id from alf_store@conn_stdb where protocol='workspace' and IDENTIFIER='SpacesStore') CONNECT By PRIOR  ch.child_node_id = ch.parent_node_id AND LEVEL <= 2) t
where t."Path" in ('/system/people','/system/workflow','/system/authorities','/system/zones')) -- Skip child for people,workflow,authorities,zones
ORDER BY 1,parent_node_id,child_node_id asc) t;
begin 
for i in c4 loop
t_num :=t_num+1;
INSERT_NODE(i.CHILD_NODE_ID,i.PARENT_NODE_ID,'child',Childcascade); 
if MOD(t_num,100)=0 then COMMIT; end if;
end loop;
COMMIT;
dbms_output.put_line('Processing Completed for system And committed record count for c4: '||t_num );
end;
/

declare
t_num NUMBER :=0;
Childcascade VARCHAR2(100) :='false';

cursor c5 is
Select * from (Select LEVEL,SYS_CONNECT_BY_PATH(ch.qname_localname, '/') "Path",ch.* from alf_child_assoc@conn_stdb ch  START WITH  ch.parent_node_id in (
Select t.CHILD_NODE_ID from (Select LEVEL,SYS_CONNECT_BY_PATH(ch.qname_localname, '/') "Path",ch.* from alf_child_assoc@conn_stdb ch START WITH ch.parent_node_id in 
(Select root_node_id from alf_store@conn_stdb where protocol='workspace' and IDENTIFIER='SpacesStore') CONNECT By PRIOR  ch.child_node_id = ch.parent_node_id AND LEVEL <= 2) t where t."Path" in ('/system/people')
)CONNECT BY PRIOR  ch.child_node_id = ch.parent_node_id
ORDER BY 1,parent_node_id,child_node_id asc) t where t.child_node_id in (
Select p.node_id from alf_node_properties p join alf_qname@conn_stdb q on p.qname_id=q.id 
where p.STRING_VALUE in ('admin','guest','abeecher','mjackson','API_User')
and p.qname_id in (Select id from alf_qname@conn_stdb where LOCAL_NAME in ('userName','username')));
begin 
for i in c5 loop
t_num :=t_num+1;
INSERT_NODE(i.CHILD_NODE_ID,i.PARENT_NODE_ID,'child',Childcascade); 
if MOD(t_num,100)=0 then COMMIT; end if;
end loop;
COMMIT;
dbms_output.put_line('Processing Completed for system And committed record count for c5: '||t_num );
end;
/

declare
t_num NUMBER :=0;
Childcascade VARCHAR2(100) :='false';

cursor c6 is
Select * from (Select LEVEL,SYS_CONNECT_BY_PATH(ch.qname_localname, '/') "Path",ch.* from alf_child_assoc@conn_stdb ch START WITH ch.parent_node_id in 
(Select root_node_id from alf_store@conn_stdb where protocol='workspace' and IDENTIFIER='SpacesStore')
CONNECT By PRIOR  ch.child_node_id = ch.parent_node_id AND LEVEL <= 3) t where t."Path" in ('/system/workflow/packages');
begin 
for i in c6 loop
t_num :=t_num+1;
INSERT_NODE(i.CHILD_NODE_ID,i.PARENT_NODE_ID,'child',Childcascade); 
if MOD(t_num,100)=0 then COMMIT; end if;
end loop;
COMMIT;
dbms_output.put_line('Processing Completed for system And committed record count for c6: '||t_num );
end;
/


declare
t_num NUMBER :=0;
Childcascade VARCHAR2(100) :='false';

cursor c7 is
Select * from (Select LEVEL,SYS_CONNECT_BY_PATH(ch.qname_localname, '/') "Path",ch.* from alf_child_assoc@conn_stdb ch START WITH ch.parent_node_id in 
(Select id from tmp_alf_ids@conn_stdb where protocol='workspace' and IDENTIFIER='SpacesStore' and  Path='/system/authorities')
CONNECT By PRIOR  ch.child_node_id = ch.parent_node_id AND LEVEL <= 1) t
where t."Path" in ('/GROUP_ALFRESCO_ADMINISTRATORS','/GROUP_EMAIL_CONTRIBUTORS','/GROUP_SITE_ADMINISTRATORS',
'/GROUP_ALFRESCO_SEARCH_ADMINISTRATORS','/GROUP_ALFRESCO_MODEL_ADMINISTRATORS','/GROUP_ALFRESCO_SYSTEM_ADMINISTRATORS');
begin 
for i in c7 loop
t_num :=t_num+1;
INSERT_NODE(i.CHILD_NODE_ID,i.PARENT_NODE_ID,'child',Childcascade); 
if MOD(t_num,100)=0 then COMMIT; end if;
end loop;
COMMIT;
dbms_output.put_line('Processing Completed for system And committed record count for c7: '||t_num );
end;
/

declare
t_num NUMBER :=0;
Childcascade VARCHAR2(100) :='false';

cursor c8 is
Select * from (Select LEVEL,SYS_CONNECT_BY_PATH(ch.qname_localname, '/') "Path",ch.* from alf_child_assoc@conn_stdb ch  START WITH  ch.parent_node_id in (
Select id from tmp_alf_ids@conn_stdb where protocol='workspace' and IDENTIFIER='SpacesStore' and path in ('/system/authorities/GROUP_ALFRESCO_ADMINISTRATORS','/system/authorities/GROUP_EMAIL_CONTRIBUTORS','/system/authorities/GROUP_SITE_ADMINISTRATORS',
'/system/authorities/GROUP_ALFRESCO_SEARCH_ADMINISTRATORS','/system/authorities/GROUP_ALFRESCO_MODEL_ADMINISTRATORS','/system/authorities/GROUP_ALFRESCO_SYSTEM_ADMINISTRATORS'))
CONNECT BY PRIOR  ch.child_node_id = ch.parent_node_id  ORDER BY 1,parent_node_id,child_node_id asc) t
where t.child_node_id in (Select p.node_id from alf_node_properties p
join alf_qname@conn_stdb q on p.qname_id=q.id 
where p.STRING_VALUE in ('admin','guest','abeecher','mjackson','API_User')
and p.qname_id=(Select id from alf_qname@conn_stdb where LOCAL_NAME='userName'));
begin 
for i in c8 loop
t_num :=t_num+1;
INSERT_NODE(i.CHILD_NODE_ID,i.PARENT_NODE_ID,'child',Childcascade); 
if MOD(t_num,100)=0 then COMMIT; end if;
end loop;
COMMIT;
dbms_output.put_line('Processing Completed for system And committed record count for c8: '||t_num );
end;
/


declare
t_num NUMBER :=0;
Childcascade VARCHAR2(100) :='false';

cursor c9 is
Select * from (Select LEVEL,SYS_CONNECT_BY_PATH(ch.qname_localname, '/') "Path",ch.* from alf_child_assoc@conn_stdb ch  START WITH  ch.parent_node_id in 
(Select t.CHILD_NODE_ID from (Select LEVEL,SYS_CONNECT_BY_PATH(ch.qname_localname, '/') "Path",ch.* from alf_child_assoc@conn_stdb ch START WITH ch.parent_node_id in 
(Select root_node_id from alf_store@conn_stdb where protocol='workspace' and IDENTIFIER='SpacesStore')
CONNECT By PRIOR  ch.child_node_id = ch.parent_node_id AND LEVEL <= 2) t where t."Path" in ('/system/zones'))
CONNECT BY PRIOR  ch.child_node_id = ch.parent_node_id and level<2
ORDER BY 1,parent_node_id,child_node_id asc) t;
begin 
for i in c9 loop
t_num :=t_num+1;
INSERT_NODE(i.CHILD_NODE_ID,i.PARENT_NODE_ID,'child',Childcascade); 
if MOD(t_num,100)=0 then COMMIT; end if;
end loop;
COMMIT;
dbms_output.put_line('Processing Completed for system And committed record count for c9: '||t_num );
end;
/


declare
t_num NUMBER :=0;
Childcascade VARCHAR2(100) :='false';

cursor c10 is
Select * from (Select LEVEL,SYS_CONNECT_BY_PATH(ch.qname_localname, '/') "Path",ch.* from alf_child_assoc@conn_stdb  ch  START WITH  ch.parent_node_id in (
Select id from tmp_alf_ids@conn_stdb  where protocol='workspace' and IDENTIFIER='SpacesStore' and path in ('/system/zones/AUTH.ALF','/system/zones/APP.DEFAULT','/system/zones/APP.SHARE')
)CONNECT BY PRIOR  ch.child_node_id = ch.parent_node_id and level<2
ORDER BY 1,parent_node_id,child_node_id asc) t where t."Path" in 
('/admin','/guest','/API_User','/GROUP_ALFRESCO_ADMINISTRATORS','/GROUP_EMAIL_CONTRIBUTORS','/GROUP_SITE_ADMINISTRATORS','/GROUP_ALFRESCO_MODEL_ADMINISTRATORS','/GROUP_ALFRESCO_SYSTEM_ADMINISTRATORS','/GROUP_ALFRESCO_SEARCH_ADMINISTRATORS')
;
begin 
for i in c10 loop
t_num :=t_num+1;
INSERT_NODE(i.CHILD_NODE_ID,i.PARENT_NODE_ID,'child',Childcascade); 
if MOD(t_num,100)=0 then COMMIT; end if;
end loop;
COMMIT;
dbms_output.put_line('Processing Completed for system And committed record count for c10: '||t_num );
end;
/

BEGIN
DBMS_OUTPUT.PUT_LINE(SYSTIMESTAMP);
END;
/

spool off;