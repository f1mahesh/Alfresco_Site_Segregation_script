declare
trnx_maxid NUMBER;
seq_maxid NUMBER;
v_sql varchar2(1024);
v_id varchar2(400);
BEGIN
for s in (Select replace(SEQUENCE_NAME,'_SEQ','') table_name from user_sequences  where sequence_name like 'ALF_%' and sequence_name not like 'ALF_PROP_SERIAL_VALUE%') loop
--DBMS_OUTPUT.PUT_LINE('Checking For Table:'||s.table_name);
v_sql :='SELECT last_number FROM USER_SEQUENCES WHERE SEQUENCE_NAME ='''||s.table_name||'_SEQ'||'''';
EXECUTE IMMEDIATE v_sql into seq_maxid;
--DBMS_OUTPUT.PUT_LINE(v_sql||':'||seq_maxid);
if(seq_maxid >1) then

v_sql := 'SELECT column_name FROM USER_TAB_COLUMNS WHERE table_name ='''||s.table_name||''' and ROWNUM=1';
EXECUTE IMMEDIATE v_sql into v_id;
--DBMS_OUTPUT.PUT_LINE(v_id);

v_sql :='Select max('||v_id||') from ' || s.table_name;
EXECUTE IMMEDIATE v_sql into trnx_maxid;
--DBMS_OUTPUT.PUT_LINE(v_sql||':'||trnx_maxid);

if trnx_maxid > seq_maxid then
DBMS_OUTPUT.PUT_LINE(s.table_name||' sequence need to update' ||' Current sequnce:'||seq_maxid||' Max ID:'||trnx_maxid);
EXECUTE IMMEDIATE 'DROP SEQUENCE "ALFRESCO_OWNER"."'||s.table_name||'_SEQ"';
EXECUTE IMMEDIATE 'CREATE SEQUENCE  "ALFRESCO_OWNER"."'||s.table_name||'_SEQ"  MINVALUE 1 MAXVALUE 9999999999999999999999999999 INCREMENT BY 1 START WITH '||trnx_maxid||' CACHE 500 ORDER  NOCYCLE  NOKEEP  NOSCALE  GLOBAL';
EXECUTE IMMEDIATE 'GRANT SELECT ON "ALFRESCO_OWNER"."'||s.table_name||'_SEQ" TO "SAFEDX_OWNER"';
EXECUTE IMMEDIATE 'GRANT SELECT ON "ALFRESCO_OWNER"."'||s.table_name||'_SEQ" TO "RW_ALFRESCO_ROLE"';
DBMS_OUTPUT.PUT_LINE(s.table_name||' sequence has been updated');
end if;

end if;
end loop;
END;
/
