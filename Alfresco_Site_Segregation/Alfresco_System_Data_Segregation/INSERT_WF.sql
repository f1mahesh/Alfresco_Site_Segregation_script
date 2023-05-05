create or replace PROCEDURE INSERT_WF(PROC_DEF_ID VARCHAR2) AS
begin
----------Workflow insert steps
Insert into act_re_deployment
Select * from act_re_deployment@PRF1_ALF_OWNER a where a.id_ in (select DEPLOYMENT_ID_ from ACT_RE_PROCDEF@PRF1_ALF_OWNER  where id_ in (select PROC_DEF_ID_ from ACT_HI_PROCINST@PRF1_ALF_OWNER where Id_=PROC_DEF_ID))
and not EXISTS (select * from act_re_deployment e where e.id_=a.id_);


Insert into ACT_GE_BYTEARRAY
Select * from ACT_GE_BYTEARRAY@PRF1_ALF_OWNER a where a.deployment_id_ in (select DEPLOYMENT_ID_ from ACT_RE_PROCDEF@PRF1_ALF_OWNER  where id_ in (select PROC_DEF_ID_ from ACT_HI_PROCINST@PRF1_ALF_OWNER where Id_=PROC_DEF_ID))
and not EXISTS (select * from ACT_GE_BYTEARRAY e where e.id_=a.id_);

Insert into ACT_RE_PROCDEF
select * from ACT_RE_PROCDEF@PRF1_ALF_OWNER a  where a.id_ in (select PROC_DEF_ID_ from ACT_HI_PROCINST@PRF1_ALF_OWNER where Id_=PROC_DEF_ID)
and not EXISTS (select * from ACT_RE_PROCDEF e where e.id_=a.id_);

Insert into ACT_HI_PROCINST
select * from ACT_HI_PROCINST@PRF1_ALF_OWNER a  where a.Id_=PROC_DEF_ID
and not EXISTS (select * from ACT_HI_PROCINST e where e.id_=a.id_);

--Insert into ACT_RU_EXECUTION
--Select * from ACT_RU_EXECUTION@PRF1_ALF_OWNER a where PROC_INST_ID_=PROC_DEF_ID
--and not EXISTS (select * from ACT_RU_EXECUTION e where e.id_=a.id_);

Insert into ACT_RU_EXECUTION
SElect * from (Select * from act_ru_execution@PRF1_ALF_OWNER re start with
re.proc_inst_id_=PROC_DEF_ID connect by nocycle re.ID_= prior re.SUPER_EXEC_
order by 1) a where not EXISTS (select * from ACT_RU_EXECUTION e where e.id_=a.id_);

Insert into ACT_HI_TASKINST
Select * from ACT_HI_TASKINST@PRF1_ALF_OWNER a where a.proc_inst_id_ in (PROC_DEF_ID)
and not EXISTS (select * from ACT_HI_TASKINST e where e.id_=a.id_);

Insert into ACT_RU_TASK
Select * from ACT_RU_TASK@PRF1_ALF_OWNER a where a.proc_inst_id_ in (PROC_DEF_ID)
and not EXISTS (select * from ACT_RU_TASK e where e.id_=a.id_);

Insert into ACT_HI_COMMENT
Select * from ACT_HI_COMMENT@PRF1_ALF_OWNER a where a.task_id_ in (Select id_ from ACT_RU_TASK where proc_inst_id_ in (PROC_DEF_ID))
and not EXISTS (select * from ACT_HI_COMMENT e where e.id_=a.id_);

Insert into ACT_RU_JOB
Select * from ACT_RU_JOB@PRF1_ALF_OWNER a where a.execution_id_ in (Select id_ from ACT_RU_EXECUTION where PROC_INST_ID_=PROC_DEF_ID)
and not EXISTS (select * from ACT_RU_JOB e where e.id_=a.id_);

Insert into ACT_HI_ACTINST
Select * from ACT_HI_ACTINST@PRF1_ALF_OWNER a where a.proc_inst_id_ in (PROC_DEF_ID)
and not EXISTS (select * from ACT_HI_ACTINST e where e.id_=a.id_);

Insert into ACT_GE_BYTEARRAY
Select * from ACT_GE_BYTEARRAY@PRF1_ALF_OWNER a where a.ID_ in (
Select BYTEARRAY_ID_ from ACT_RU_VARIABLE@PRF1_ALF_OWNER where proc_inst_id_ in (PROC_DEF_ID) and  BYTEARRAY_ID_ is not null
UNION
Select BYTEARRAY_ID_ from ACT_HI_VARINST@PRF1_ALF_OWNER where proc_inst_id_ in (PROC_DEF_ID) and  BYTEARRAY_ID_ is not null
UNION
Select BYTEARRAY_ID_ from ACT_HI_DETAIL@PRF1_ALF_OWNER where proc_inst_id_ in (PROC_DEF_ID) and  BYTEARRAY_ID_ is not null)
and not EXISTS (select * from ACT_GE_BYTEARRAY e where e.id_=a.id_);

Insert into ACT_RU_VARIABLE
Select * from  ACT_RU_VARIABLE@PRF1_ALF_OWNER a where a.proc_inst_id_ in (PROC_DEF_ID)
and not EXISTS (select * from ACT_RU_VARIABLE e where e.id_=a.id_);

Insert into ACT_HI_VARINST
Select * from ACT_HI_VARINST@PRF1_ALF_OWNER a where a.proc_inst_id_ in (PROC_DEF_ID)
and not EXISTS (select * from ACT_HI_VARINST e where e.id_=a.id_);

Insert into ACT_HI_DETAIL
Select * from ACT_HI_DETAIL@PRF1_ALF_OWNER a where a.proc_inst_id_ in (PROC_DEF_ID)
and not EXISTS (select * from ACT_HI_DETAIL e where e.id_=a.id_);

Insert into ACT_RU_IDENTITYLINK
Select * from ACT_RU_IDENTITYLINK@PRF1_ALF_OWNER a where a.task_id_ in 
(Select id_ from ACT_RU_TASK@PRF1_ALF_OWNER where proc_inst_id_ in (PROC_DEF_ID))
and not EXISTS (select * from ACT_RU_IDENTITYLINK e where e.id_=a.id_);


Insert into ACT_RU_IDENTITYLINK
Select * from ACT_RU_IDENTITYLINK@PRF1_ALF_OWNER a where a.proc_inst_id_ in (PROC_DEF_ID)
and not EXISTS (select * from ACT_RU_IDENTITYLINK e where e.id_=a.id_);


Insert into ACT_HI_IDENTITYLINK
Select * from ACT_HI_IDENTITYLINK@PRF1_ALF_OWNER a where a.task_id_ in 
(Select id_ from ACT_RU_TASK@PRF1_ALF_OWNER where proc_inst_id_ in (PROC_DEF_ID))
and not EXISTS (select * from ACT_HI_IDENTITYLINK e where e.id_=a.id_);


Insert into ACT_HI_IDENTITYLINK
Select * from ACT_HI_IDENTITYLINK@PRF1_ALF_OWNER a where a.proc_inst_id_ in (PROC_DEF_ID)
and not EXISTS (select * from ACT_HI_IDENTITYLINK e where e.id_=a.id_);

EXCEPTION WHEN OTHERS
THEN dbms_output.put_line('INSERT_WF Proc Error Code-'||SUBSTR( DBMS_UTILITY.format_error_stack
                 || DBMS_UTILITY.format_error_backtrace, 1, 4000)|| 'Error Code :'|| SQLCODE || ' PROC_DEF_ID :'||PROC_DEF_ID);
end INSERT_WF;