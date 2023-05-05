spool step-5_system_AuditModel_Feed_Lock_insert_proc.log;
set serveroutput on size 1000000;
set define off;
prompt --step-5_system_AuditModel_Feed_Lock_insert_proc.sql

BEGIN
DBMS_OUTPUT.PUT_LINE(SYSTIMESTAMP);
END;
/

begin
-- Audit Model (Make sure all the audit data is copied to custom table as it will copy the model only. the audit entries will be skipped)
insert into alf_content_url 
Select * from alf_content_url@conn_stdb a where a.id in 
(Select CONTENT_URL_ID from alf_content_data@conn_stdb where id in (select CONTENT_DATA_ID from ALF_AUDIT_MODEL@conn_stdb))
and not exists (Select * from alf_content_url e where e.id=a.id);

insert into alf_content_data 
Select * from alf_content_data@conn_stdb a where a.id in (select CONTENT_DATA_ID from ALF_AUDIT_MODEL@conn_stdb)
and not exists (Select * from alf_content_data e where e.id=a.id);

insert into ALF_AUDIT_MODEL 
select * from ALF_AUDIT_MODEL@conn_stdb a
where not exists (Select * from ALF_AUDIT_MODEL e where e.id=a.id);

insert into ALF_PROP_STRING_VALUE 
select * from ALF_PROP_STRING_VALUE@conn_stdb;

insert into ALF_PROP_CLASS
select * from ALF_PROP_CLASS@conn_stdb a
where not exists (Select * from ALF_PROP_CLASS e where e.id=a.id);

--Lock (Copy as it is)
insert into ALF_LOCK_RESOURCE Select * from ALF_LOCK_RESOURCE@conn_stdb;

insert into ALF_LOCK Select * from ALF_LOCK@conn_stdb;

--Activity Feed (Copy as it is)
Insert into ALF_ACTIVITY_FEED Select * from ALF_ACTIVITY_FEED@conn_stdb ;

Insert into ALF_ACTIVITY_POST Select * from ALF_ACTIVITY_POST@conn_stdb; 

commit;
end;
/

BEGIN
DBMS_OUTPUT.PUT_LINE(SYSTIMESTAMP);
END;
/

spool off;
