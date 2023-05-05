begin
BEGIN
EXECUTE IMMEDIATE 'DROP TABLE tmp_src_tbl_cnt';
EXCEPTION
WHEN OTHERS THEN
IF SQLCODE != -942 THEN
RAISE;
END IF;
END;
execute IMMEDIATE 'create table tmp_src_tbl_cnt(tableName VARCHAR2(400),count number)';
end;
/

DECLARE
n number;
begin 
for t in (select TABLE_NAME from user_tables where TABLE_NAME not like '%TBL%') loop
execute immediate 'select count(1) from ' || t.TABLE_NAME into n;
INSERT into tmp_src_tbl_cnt(tableName,count) values(t.TABLE_NAME,n);
--dbms_output.put_line(t.TABLE_NAME||'|'||n); 
end loop;
COMMIT;
end;
/

Select * from tmp_src_tbl_cnt;

