spool step-3_Site_WF_insert_c2.log;
set serveroutput on size 1000000;
set define off;
prompt --step-3_Site_WF_insert_c2.sql

BEGIN
DBMS_OUTPUT.PUT_LINE(SYSTIMESTAMP);
END;
/

declare
v_sponsor varchar2(20):='curie';
t_num NUMBER :=0;

TYPE varray is table of number;
v_proc_inst_ids  varray;

cursor c2 is
Select PROC_INST_ID_ from tmp_wf_alf_uuid@PRF1_ALF_OWNER;
    

begin 
v_proc_inst_ids:=varray();
for w in c2 loop
t_num :=t_num+1;
begin 
INSERT_WF(w.PROC_INST_ID_);
EXCEPTION WHEN OTHERS then
IF SQLCODE = '-2291' THEN
dbms_output.put_line('Got error for PROC_INST_ID_:'||w.PROC_INST_ID_ ||' it will process in next loop');
v_proc_inst_ids.extend;
v_proc_inst_ids(v_proc_inst_ids.count) :=w.PROC_INST_ID_;
end if;
end;
if MOD(t_num,100)=0 then COMMIT; end if;
end loop;

for k in 1 .. v_proc_inst_ids.count loop
dbms_output.put_line('processing error PROC_INST_ID_: '||v_proc_inst_ids(k));
INSERT_WF(v_proc_inst_ids(k));
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
