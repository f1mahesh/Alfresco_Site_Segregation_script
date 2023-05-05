spool pre_seg_tmp_tbl_proc.log;
set serveroutput on size 1000000;
set define off;
prompt --pre_seg_tmp_tbl_proc.sql

BEGIN
DBMS_OUTPUT.PUT_LINE(SYSTIMESTAMP);
END;
/

BEGIN
BEGIN
EXECUTE IMMEDIATE 'DROP TABLE tmp_alf_ids';
EXCEPTION
WHEN OTHERS THEN
IF SQLCODE != -942 THEN
RAISE;
END IF;
END;
execute immediate 'create table tmp_alf_ids(protocol VARCHAR2(400),IDENTIFIER VARCHAR2(400),Path VARCHAR2(1200),id number)';
END;
/

declare
v_sponsor varchar2(20):='pfizer';

BEGIN
insert into tmp_alf_ids 
Select 'user','alfrescoUserStore',t."Path",t.child_node_id from (
Select LEVEL,SYS_CONNECT_BY_PATH(ch.qname_localname, '/') "Path",ch.* 
from alf_child_assoc ch START WITH ch.parent_node_id in 
(Select root_node_id from alf_store where protocol='user' and IDENTIFIER='alfrescoUserStore')
CONNECT By PRIOR  ch.child_node_id = ch.parent_node_id AND LEVEL <= 2
) t where t."Path" in ('/system/people');

--insert into tmp_alf_ids 
--Select 'workspace','SpacesStore',t."Path",t.child_node_id from (
--Select LEVEL,SYS_CONNECT_BY_PATH(ch.qname_localname, '/') "Path",ch.* 
--from alf_child_assoc ch START WITH ch.parent_node_id in 
--(Select root_node_id from alf_store where protocol='workspace' and IDENTIFIER='SpacesStore')
--CONNECT By PRIOR  ch.child_node_id = ch.parent_node_id AND LEVEL <= 2
--) t where t."Path" in ('/company_home/user_homes','/company_home/sites','/system/authorities')
--;

insert into tmp_alf_ids
SELECT 'workspace','SpacesStore',T."Path",T.CHILD_NODE_ID FROM (SELECT LEVEL,SYS_CONNECT_BY_PATH(CH.QNAME_LOCALNAME, '/') "Path",CH.* 
FROM ALF_CHILD_ASSOC CH START WITH CH.PARENT_NODE_ID IN (SELECT ROOT_NODE_ID 
FROM ALF_STORE WHERE PROTOCOL='workspace' AND IDENTIFIER='SpacesStore') 
CONNECT BY PRIOR CH.CHILD_NODE_ID = CH.PARENT_NODE_ID AND LEVEL <= 3) T 
WHERE T. "Path" IN ('/company_home/user_homes','/company_home/sites','/system/authorities',
'/system/zones/AUTH.ALF','/system/zones/APP.DEFAULT','/system/zones/APP.SHARE','/company_home/SafeDx/Sponsors',
'/system/authorities/GROUP_ALFRESCO_ADMINISTRATORS','/system/authorities/GROUP_EMAIL_CONTRIBUTORS','/system/authorities/GROUP_SITE_ADMINISTRATORS',
'/system/authorities/GROUP_ALFRESCO_SEARCH_ADMINISTRATORS','/system/authorities/GROUP_ALFRESCO_MODEL_ADMINISTRATORS',
'/system/authorities/GROUP_site_'||v_sponsor, '/system/authorities/GROUP_ALFRESCO_SYSTEM_ADMINISTRATORS'
)
;


commit;
end;
/

BEGIN
DBMS_OUTPUT.PUT_LINE(SYSTIMESTAMP);
END;
/

spool off;