spool pre_seg_tmp_wf_tbl_proc.log;
set serveroutput on size 1000000;
set define off;
prompt --pre_seg_tmp_wf_tbl_proc.sql

BEGIN
DBMS_OUTPUT.PUT_LINE(SYSTIMESTAMP);
END;
/


begin
BEGIN
EXECUTE IMMEDIATE 'DROP TABLE tmp_wf_alf_uuid';
EXCEPTION
WHEN OTHERS THEN
IF SQLCODE != -942 THEN
RAISE;
END IF;
END;
execute IMMEDIATE 'create table tmp_wf_alf_uuid(uuid VARCHAR2(36 CHAR),PROC_INST_ID_ VARCHAR2(64 CHAR))';
end;
/

declare
v_sponsor varchar2(20):='galaxy';

Begin
insert into tmp_wf_alf_uuid
Select REPLACE(v.TEXT_,'workspace://SpacesStore/','') uuid,v.proc_inst_id_ from ACT_RU_VARIABLE v
join (select PROC_INST_ID_ from ACT_RU_VARIABLE where name_ in ('sdwf_sponsorName')
and text_=v_sponsor group by PROC_INST_ID_  
union Select PROC_INST_ID_ from ACT_HI_VARINST where name_ in ('sdwf_sponsorName')
and text_=v_sponsor group by PROC_INST_ID_   
union Select PROC_INST_ID_ from ACT_HI_DETAIL where name_ in ('sdwf_sponsorName')
and text_=v_sponsor group by PROC_INST_ID_) t on t.proc_inst_id_=v.proc_inst_id_
and  v.name_='bpm_package';

commit;
end;
/

BEGIN
DBMS_OUTPUT.PUT_LINE(SYSTIMESTAMP);
END;
/

spool off;