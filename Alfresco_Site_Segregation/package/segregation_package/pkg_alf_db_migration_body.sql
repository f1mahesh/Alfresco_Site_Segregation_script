create or replace PACKAGE BODY PKG_ALF_DB_MIGRATION
AS
  /*******************************************************************************
  Program Name: PKG_ALF_DB_MIGRATION
  Purpose: This Package is used for migrating sponsor specific data to a new environment
  Author: SAFED DB Team
  Creation Date: 09-JAN-2023
  Modified By:
  Modification Date:
  Modification Remarks:
  *******************************************************************************/

/*******************************************************************************
Program Name: SP_ALF_DB_MIGRATION
Purpose: This SP is the driving procedure to perform the migration activity.
Author: Safedx DB Team
Creation Date: 09-JAN-2023
Modified By:
Modification Date:
Modification Remarks:
*******************************************************************************/
PROCEDURE SP_ALF_DB_MIGRATION(IP_DB_LINK IN VARCHAR2, IP_SPONSOR_NAME IN VARCHAR2) AS
V_START_TIME DATE;
V_END_TIME DATE;
V_REF_NAME VARCHAR2(100 CHAR);
V_REF_ID NUMBER(38,0);
V_REMARKS VARCHAR2(100 CHAR);
BEGIN
	V_DB_LINK :=IP_DB_LINK;
	V_SPONSOR:=IP_SPONSOR_NAME;
	V_START_TIME:=SYSDATE;
    V_REF_NAME:='SP_ALF_DB_MIGRATION';
    V_REF_ID:=0;
    V_REMARKS:='Completed successfully';
--Alfresco_System_Data_Segregation
--CREATE ALF_NUM_ARRAY IF DOES NOT EXISTS PLEASE RUN PROCEDURE PKG_ALF_UTILITIES.SP_ALF_DDL
--Alfresco_System_Data_Segregation
    SP_SYSTEM_DATA_SEGREGATION;
--Sponsor_data_Segregation_Activity
    SP_SPONSOR_DATA_SEGREGATION;
V_END_TIME:=SYSDATE;
SP_MIGRATION_PROCESS_LOG('SP_ALF_DB_MIGRATION', V_START_TIME, V_END_TIME,V_REF_NAME, NULL, NULL,NULL, NULL, NULL, V_REMARKS, NULL) ;
EXCEPTION WHEN OTHERS
THEN V_REMARKS:='Not Processed';
SP_MIGRATION_PROCESS_LOG('SP_ALF_DB_MIGRATION', V_START_TIME, V_END_TIME,V_REF_NAME, NULL, NULL,NULL, SQLCODE, SQLERRM, V_REMARKS, NULL) ;
END SP_ALF_DB_MIGRATION;

PROCEDURE SP_SPONSOR_DATA_SEGREGATION IS
V_START_TIME DATE;
V_END_TIME DATE;
V_REMARKS VARCHAR2(100 CHAR);
BEGIN
    V_START_TIME:=SYSDATE;
--step-1_site_safedx_folderData_insert
    SP_INSERT_SAFEDX_SITE_FOLDER_DATA;
--step-2_user_authority_insert_c1
    SP_INSERT_USER_AUTHORITY_PART1;
--step-2_user_authority_insert_c2
    SP_INSERT_USER_AUTHORITY_PART2;
--step-2_user_authority_insert_c3
    SP_INSERT_USER_AUTHORITY_PART3;
--step-2_user_authority_insert_c4
    SP_INSERT_USER_AUTHORITY_PART4;
--step-2_user_authority_insert_c5
    SP_INSERT_USER_AUTHORITY_PART5;
--step-3_Site_WF_insert_c1
    SP_INSERT_SITE_WORKFLOW_PART1;
--step-3_Site_WF_insert_c2
    SP_INSERT_SITE_WORKFLOW_PART2;
--step-4_archive_insert
    SP_INSERT_ARCHIVE_DATA;
--step-5_version_insert
    SP_INSERT_VERSION_DATA;
--step-6_node_assco_fix
    SP_FIXING_NODE_ASSOC_DATA;
--step-7_sequence_update.sql
	V_END_TIME:=SYSDATE;
	SP_MIGRATION_PROCESS_LOG('SP_SPONSOR_DATA_SEGREGATION', V_START_TIME, V_END_TIME,NULL, NULL, NULL,NULL, NULL, NULL, V_REMARKS, NULL) ;
EXCEPTION WHEN OTHERS
THEN V_REMARKS:='Not Processed';
SP_MIGRATION_PROCESS_LOG('SP_SPONSOR_DATA_SEGREGATION', V_START_TIME, V_END_TIME,NULL, null, null,null,SQLCODE, SQLERRM, V_REMARKS,NULL) ;
END SP_SPONSOR_DATA_SEGREGATION;

PROCEDURE SP_INSERT_SAFEDX_SITE_FOLDER_DATA IS
	t_num number(10);
	Childcascade VARCHAR2(100) :='true'; --Change this to true if child cascade required
    type t_parent_id is table of alf_child_assoc.parent_node_id%type;
    type t_child_id is table of alf_child_assoc.child_node_id%type;
    v_parent_node_id t_parent_id;
    v_child_node_id t_child_id;
    V_SQL CLOB;
	V_START_TIME DATE;
    V_END_TIME DATE;
    V_REF_NAME VARCHAR2(100 CHAR);
    V_REMARKS VARCHAR2(100 CHAR);
begin
    V_START_TIME:=SYSDATE;
    V_REF_NAME:='INSERT_SAFEDX_SITE_FOLDER_DATA';

     V_SQL:='Select parent_node_id,child_node_id from (Select LEVEL,ch.* from alf_child_assoc'||V_DB_LINK||' ch START WITH  ch.parent_node_id in
(Select id from tmp_alf_ids'||V_DB_LINK||' where protocol=''workspace'' and IDENTIFIER=''SpacesStore'' and path in (''/company_home/SafeDx/Sponsors'',''/company_home/sites''))
CONNECT BY PRIOR  ch.child_node_id = ch.parent_node_id and level<2) t
where t.QNAME_LOCALNAME in ('''||v_sponsor||''')';
    EXECUTE IMMEDIATE V_SQL BULK COLLECT INTO v_parent_node_id,v_child_node_id;
    begin
        for i in 1..v_child_node_id.COUNT loop
            --t_num :=t_num+1;
            INSERT_NODE(v_child_node_id(i),v_parent_node_id(i),'child',Childcascade);
        --if MOD(t_num,100)=0 then COMMIT; end if;
        end loop;
    COMMIT;
    end;
	V_END_TIME:=SYSDATE;
	SP_MIGRATION_PROCESS_LOG('SP_INSERT_SAFEDX_SITE_FOLDER_DATA', V_START_TIME, V_END_TIME,V_REF_NAME, NULL, NULL,NULL, NULL, NULL, V_REMARKS, NULL) ;
EXCEPTION WHEN OTHERS
THEN
	V_REMARKS:='Not Processed';
 SP_MIGRATION_PROCESS_LOG('SP_INSERT_SAFEDX_SITE_FOLDER_DATA', V_START_TIME, V_END_TIME,V_REF_NAME, null, null,null,SQLCODE, SQLERRM, V_REMARKS,NULL) ;
END SP_INSERT_SAFEDX_SITE_FOLDER_DATA;

PROCEDURE SP_INSERT_USER_AUTHORITY_PART1 IS
	n number(10);
	Childcascade VARCHAR2(100) :='false'; --Change this to ture if child cascade required
	t_num NUMBER :=0;
    type t_parent_id is table of alf_child_assoc.parent_node_id%type;
    type t_child_id is table of alf_child_assoc.child_node_id%type;
    v_parent_node_id t_parent_id;
    v_child_node_id t_child_id;
    V_SQL CLOB;
    V_STRING_VALUE VARCHAR2(100):='GROUP_site_'||v_sponsor;
	V_START_TIME DATE;
    V_END_TIME DATE;
    V_REF_NAME VARCHAR2(100 CHAR);
    V_REMARKS VARCHAR2(100 CHAR);

BEGIN
    V_START_TIME:=SYSDATE;
    V_REF_NAME:='INSERT_USER_AUTHORITY_PART1';
    begin
    V_SQL:='Select parent_node_id,child_node_id from alf_child_assoc'||V_DB_LINK||' ch where child_node_id in (select p.node_id from alf_node_properties'||V_DB_LINK||' p join alf_qname'||V_DB_LINK||' q on q.id=p.qname_id
	where p.STRING_VALUE='''||V_STRING_VALUE||''' and q.local_name=''authorityName'')';
    EXECUTE IMMEDIATE V_SQL BULK COLLECT INTO v_parent_node_id,v_child_node_id;
		begin
			for i in 1..v_child_node_id.COUNT loop
				----t_num :=t_num+1;
				INSERT_NODE(v_child_node_id(i),v_parent_node_id(i),'child',Childcascade);
			----if MOD(t_num,100)=0 then COMMIT; end if;
			end loop;
		COMMIT;
		--dbms_output.put_line('Processing Completed for '||v_sponsor||' And committed record count: '||t_num );
		end;
	end;
	V_END_TIME:=SYSDATE;
	SP_MIGRATION_PROCESS_LOG('SP_INSERT_USER_AUTHORITY_PART1', V_START_TIME, V_END_TIME,V_REF_NAME, NULL, NULL,NULL, NULL, NULL, V_REMARKS, NULL) ;
EXCEPTION WHEN OTHERS
THEN
	V_REMARKS:='Not Processed';
	SP_MIGRATION_PROCESS_LOG('SP_INSERT_USER_AUTHORITY_PART1', V_START_TIME, V_END_TIME,V_REF_NAME, null, null,null,SQLCODE, SQLERRM, V_REMARKS,NULL) ;
END SP_INSERT_USER_AUTHORITY_PART1;

PROCEDURE SP_INSERT_USER_AUTHORITY_PART2 IS
    t_num NUMBER :=0;
    n number(10);
    Childcascade VARCHAR2(100) :='false'; --Change this to ture if child cascade required
    type t_parent_id is table of alf_child_assoc.parent_node_id%type;
    type t_child_id is table of alf_child_assoc.child_node_id%type;
    v_parent_node_id t_parent_id;
    v_child_node_id t_child_id;
    V_SQL CLOB;
    V_STRING_VALUE VARCHAR2(100):='GROUP_site_'||v_sponsor;
	V_START_TIME DATE;
    V_END_TIME DATE;
    V_REF_NAME VARCHAR2(100 CHAR);
    V_REMARKS VARCHAR2(100 CHAR);
	TYPE varray is table of VARCHAR2(32670);
	v_parent_child_ids  varray;
	v_parent_id number;
	v_child_id number;
BEGIN
	v_parent_child_ids:=varray();	


    V_START_TIME:=SYSDATE;
    V_REF_NAME:='INSERT_USER_AUTHORITY_PART2';

	V_SQL:='Select parent_node_id,child_node_id from ( Select LEVEL,SYS_CONNECT_BY_PATH(ch.QNAME_LOCALNAME, ''/'') Path,ch.* from alf_child_assoc'||V_DB_LINK||' ch  START WITH  ch.parent_node_id in
(Select id from tmp_alf_ids'||V_DB_LINK||'  where protocol=''workspace'' and IDENTIFIER=''SpacesStore'' and  Path=''/system/authorities/GROUP_site_'||v_sponsor||''')
CONNECT BY PRIOR  ch.child_node_id = ch.parent_node_id ) t
UNION ALL
Select parent_node_id,child_node_id from  (Select LEVEL,SYS_CONNECT_BY_PATH(ch.QNAME_LOCALNAME, ''/'') Path,ch.* from alf_child_assoc'||V_DB_LINK||' ch  START WITH  ch.parent_node_id in
(Select id from tmp_alf_ids'||V_DB_LINK||'  where protocol=''workspace'' and IDENTIFIER=''SpacesStore'' and  Path=''/system/zones/APP.SHARE'')
CONNECT BY PRIOR  ch.child_node_id = ch.parent_node_id and level<2 ) t
where t.path like ''/GROUP_site_'||v_sponsor||'%''';
    EXECUTE IMMEDIATE V_SQL BULK COLLECT INTO v_parent_node_id,v_child_node_id;
    begin
        for i in 1..v_child_node_id.COUNT loop
          begin
            INSERT_NODE(v_child_node_id(i),v_parent_node_id(i),'child',Childcascade);
                   EXCEPTION WHEN OTHERS then
                IF SQLCODE = '-2291' THEN
					v_parent_child_ids.extend;
					v_parent_child_ids(v_parent_child_ids.count) :=v_child_node_id(i)||'|'||v_parent_node_id(i);
				end if;
			end;
        end loop;
    COMMIT;
	for rec in 1..v_parent_child_ids.count loop
			select to_number(SUBSTR(v_parent_child_ids(rec), 1, Instr(v_parent_child_ids(rec), '|', -1, 1) -1)),to_number(SUBSTR(v_parent_child_ids(rec), Instr(v_parent_child_ids(rec), '|', -1, 1) +1)) into v_child_id,v_parent_id from dual;
				INSERT_NODE(v_child_id,v_parent_id,'child',Childcascade);
		end loop;
        --dbms_output.put_line('Processing Completed for '||v_sponsor||' And committed record count: '||t_num );
    end;

	V_END_TIME:=SYSDATE;
	SP_MIGRATION_PROCESS_LOG('SP_INSERT_USER_AUTHORITY_PART2', V_START_TIME, V_END_TIME,V_REF_NAME, NULL, NULL,NULL, NULL, NULL, V_REMARKS, NULL) ;
EXCEPTION WHEN OTHERS
THEN
	V_REMARKS:='Not Processed';
	SP_MIGRATION_PROCESS_LOG('SP_INSERT_USER_AUTHORITY_PART2', V_START_TIME, V_END_TIME,V_REF_NAME, null, null,null,SQLCODE, SQLERRM, V_REMARKS,NULL);
END SP_INSERT_USER_AUTHORITY_PART2;

PROCEDURE SP_INSERT_USER_AUTHORITY_PART3 IS
    t_num NUMBER :=0;
    n number(10);
    Childcascade VARCHAR2(100) :='false'; --Change this to ture if child cascade required
    type t_parent_id is table of alf_child_assoc.parent_node_id%type;
    type t_child_id is table of alf_child_assoc.child_node_id%type;
    v_parent_node_id t_parent_id;
    v_child_node_id t_child_id;
    V_SQL CLOB;
    V_STRING_VALUE1 VARCHAR2(100):='GROUP_'||v_sponsor||'_%_SF_C%';
    V_STRING_VALUE2 VARCHAR2(100):='GROUP_'||v_sponsor||'_%_CLD_C%';
    V_STRING_VALUE3 VARCHAR2(100):='GROUP_'||v_sponsor||'_SF_C%';
	V_START_TIME DATE;
    V_END_TIME DATE;
    V_REF_NAME VARCHAR2(100 CHAR);
    V_REMARKS VARCHAR2(100 CHAR);
--Insert the site groups:  SF_Consumer AND CLD_Consumer
BEGIN
    V_START_TIME:=SYSDATE;
    V_REF_NAME:='INSERT_USER_AUTHORITY_PART3';

    V_SQL:='Select parent_node_id,child_node_id from alf_child_assoc'||V_DB_LINK||' ch where child_node_id in (Select p.node_id from alf_node_properties'||V_DB_LINK||' p join alf_qname q on q.id=p.qname_id
where (p.STRING_VALUE like '''||V_STRING_VALUE1||''' OR p.STRING_VALUE like '''||V_STRING_VALUE2||''' OR p.STRING_VALUE like '''||V_STRING_VALUE3||''')
and q.local_name=''authorityName'')
and not EXISTS (select * from alf_child_assoc e where e.id=ch.id)';

    EXECUTE IMMEDIATE V_SQL BULK COLLECT INTO v_parent_node_id,v_child_node_id;
    begin
        for i in 1..v_child_node_id.COUNT loop
          --  --t_num :=t_num+1;
            INSERT_NODE(v_child_node_id(i),v_parent_node_id(i),'child',Childcascade);
      --  --if MOD(t_num,100)=0 then COMMIT; end if;
        end loop;
    COMMIT;
    --dbms_output.put_line('Processing Completed for '||v_sponsor||' And committed record count: '||t_num );
    end;
    V_END_TIME:=SYSDATE;
	SP_MIGRATION_PROCESS_LOG('SP_INSERT_USER_AUTHORITY_PART3', V_START_TIME, V_END_TIME,V_REF_NAME, NULL, NULL,NULL, NULL, NULL, V_REMARKS, NULL) ;
EXCEPTION WHEN OTHERS
THEN
	V_REMARKS:='Not Processed';
	SP_MIGRATION_PROCESS_LOG('SP_INSERT_USER_AUTHORITY_PART3', V_START_TIME, V_END_TIME,V_REF_NAME, null, null,null,SQLCODE, SQLERRM, V_REMARKS,NULL);
END SP_INSERT_USER_AUTHORITY_PART3;

PROCEDURE SP_INSERT_USER_AUTHORITY_PART4 IS
    Childcascade VARCHAR2(100) :='false'; --Change this to ture if child cascade required
    t_num NUMBER :=0;
    type t_parent_id is table of alf_child_assoc.parent_node_id%type;
    type t_child_id is table of alf_child_assoc.child_node_id%type;
    type t_node_id is table of alf_node_properties.node_id%type;
    v_parent_node_id t_parent_id;
    v_child_node_id t_child_id;
    v_node_id t_node_id;
    V_SQL CLOB;
    V_STRING_VALUE1 VARCHAR2(100):='GROUP_'||v_sponsor||'_%_SF_Consumer%';
    V_STRING_VALUE2 VARCHAR2(100):='GROUP_'||v_sponsor||'_%_CLD_Consumer%';
    V_STRING_VALUE3 VARCHAR2(100):='GROUP_'||v_sponsor||'_SF_Consumer%';
	V_START_TIME DATE;
    V_END_TIME DATE;
    V_REF_NAME VARCHAR2(100 CHAR);
    V_REMARKS VARCHAR2(100 CHAR);

--Insert all the asscoiate childs for SF_Consumer AND CLD_Consumer
BEGIN
    V_START_TIME:=SYSDATE;
    V_REF_NAME:='INSERT_USER_AUTHORITY_PART4';

    V_SQL:='Select p.node_id from alf_node_properties'||V_DB_LINK||' p join alf_qname'||V_DB_LINK||' q on q.id=p.qname_id
where (p.STRING_VALUE like '''||V_STRING_VALUE1||''' OR p.STRING_VALUE like '''||V_STRING_VALUE2||'''
OR p.STRING_VALUE like '''||V_STRING_VALUE3||''')
and q.local_name=''authorityName''';

    EXECUTE IMMEDIATE V_SQL BULK COLLECT INTO v_node_id;
    begin
        for j in 1..v_node_id.COUNT loop
            V_SQL:='Select parent_node_id,child_node_id from(Select LEVEL,ch.CHILD_NODE_ID,ch.PARENT_NODE_ID
            from alf_child_assoc'||V_DB_LINK||' ch  START WITH  ch.parent_node_id in ('||v_node_id(j)||') CONNECT BY PRIOR ch.child_node_id = ch.parent_node_id)';
            EXECUTE IMMEDIATE V_SQL BULK COLLECT INTO v_parent_node_id,v_child_node_id;
            for i in 1..v_child_node_id.COUNT loop
             --   --t_num :=t_num+1;
                INSERT_NODE(v_child_node_id(i),v_parent_node_id(i),'child',Childcascade);
              --  --if MOD(t_num,100)=0 then COMMIT; end if;
            end loop;
        end loop;
        COMMIT;
    --dbms_output.put_line('Processing Completed for '||v_sponsor||' And committed record count: '||t_num );
    end;
    V_END_TIME:=SYSDATE;
	SP_MIGRATION_PROCESS_LOG('SP_INSERT_USER_AUTHORITY_PART4', V_START_TIME, V_END_TIME,V_REF_NAME, NULL, NULL,NULL, NULL, NULL, V_REMARKS, NULL) ;
EXCEPTION WHEN OTHERS
THEN
	V_REMARKS:='Not Processed';
	SP_MIGRATION_PROCESS_LOG('SP_INSERT_USER_AUTHORITY_PART4', V_START_TIME, V_END_TIME,V_REF_NAME, null, null,null,SQLCODE, SQLERRM, V_REMARKS,NULL);
END SP_INSERT_USER_AUTHORITY_PART4;

PROCEDURE SP_INSERT_USER_AUTHORITY_PART5 IS
    n number(10);
    Childcascade VARCHAR2(100) :='true'; --Change this to ture if child cascade required
    t_num NUMBER :=0;
    type t_parent_id is table of alf_child_assoc.parent_node_id%type;
    type t_child_id is table of alf_child_assoc.child_node_id%type;
    type t_node_id is table of alf_node_properties.node_id%type;
    v_parent_node_id t_parent_id;
    v_child_node_id t_child_id;
    V_SQL CLOB;
    V_STRING_VALUE VARCHAR2(100):='GROUP_'||v_sponsor||'_ST_C%';
	V_START_TIME DATE;
    V_END_TIME DATE;
    V_REF_NAME VARCHAR2(100 CHAR);
    V_REMARKS VARCHAR2(100 CHAR);
BEGIN
    V_START_TIME:=SYSDATE;
    V_REF_NAME:='INSERT_USER_AUTHORITY_PART5';

    V_SQL:='Select parent_node_id,child_node_id from  alf_child_assoc'||V_DB_LINK||' ch where child_node_id in (Select p.node_id from alf_node_properties'||V_DB_LINK||' p join alf_qname q on q.id=p.qname_id where p.STRING_VALUE like '''||V_STRING_VALUE||''' and q.local_name=''authorityName'')';
    EXECUTE IMMEDIATE V_SQL BULK COLLECT INTO v_parent_node_id,v_child_node_id;
    begin
        for i in 1..v_child_node_id.COUNT loop
          --  --t_num :=t_num+1;
            INSERT_NODE(v_child_node_id(i),v_parent_node_id(i),'child',Childcascade);
          --  --if MOD(t_num,100)=0 then COMMIT; end if;
        end loop;
        COMMIT;

    --dbms_output.put_line('Processing Completed for '||v_sponsor||' And committed record count: '||t_num );
    end;
    V_END_TIME:=SYSDATE;
	SP_MIGRATION_PROCESS_LOG('SP_INSERT_USER_AUTHORITY_PART5', V_START_TIME, V_END_TIME,V_REF_NAME, NULL, NULL,NULL, NULL, NULL, V_REMARKS, NULL) ;
EXCEPTION WHEN OTHERS
THEN
	V_REMARKS:='Not Processed';
	SP_MIGRATION_PROCESS_LOG('SP_INSERT_USER_AUTHORITY_PART5', V_START_TIME, V_END_TIME,V_REF_NAME, null, null,null,SQLCODE, SQLERRM, V_REMARKS,NULL);
END SP_INSERT_USER_AUTHORITY_PART5;

PROCEDURE SP_INSERT_SITE_WORKFLOW_PART1 IS
    t_num NUMBER :=0;
    i number(10);
    Childcascade VARCHAR2(100) :='true'; --Change this to ture if child cascade required
    type t_parent_id is table of alf_child_assoc.parent_node_id%type;
    type t_child_id is table of alf_child_assoc.child_node_id%type;
    type t_node_id is table of alf_node_properties.node_id%type;
    v_parent_node_id t_parent_id;
    v_child_node_id t_child_id;
    V_SQL CLOB;
	V_START_TIME DATE;
	V_END_TIME DATE;
	V_REF_NAME VARCHAR2(100 CHAR);
	V_REF_ID NUMBER(38,0);
	V_REMARKS VARCHAR2(100 CHAR);

BEGIN
	V_START_TIME:=SYSDATE;
    V_REF_NAME:='INSERT_SITE_WORKFLOW';
    V_REF_ID:=0;
    V_REMARKS:='Completed successfully';

    V_SQL:='Select parent_node_id,child_node_id from alf_child_assoc'||V_DB_LINK||' c join alf_qname'||V_DB_LINK||' q on q.id=c.type_qname_id
where child_node_id in (Select n.id from alf_node'||V_DB_LINK||' n join tmp_wf_alf_uuid'||V_DB_LINK||' w on n.uuid=w.uuid)';

    EXECUTE IMMEDIATE V_SQL BULK COLLECT INTO v_parent_node_id,v_child_node_id;
    begin
        for i in 1..v_child_node_id.COUNT loop
--            --t_num :=t_num+1;
            INSERT_NODE(v_child_node_id(i),v_parent_node_id(i),'child',Childcascade);
  --          --if MOD(t_num,100)=0 then COMMIT; end if;
        end loop;
        COMMIT;
    --dbms_output.put_line('Processing Completed for '||v_sponsor||' And committed record count: '||t_num );
    end;
V_END_TIME:=SYSDATE;
SP_MIGRATION_PROCESS_LOG('SP_INSERT_SITE_WORKFLOW_PART1', V_START_TIME, V_END_TIME,V_REF_NAME, NULL, NULL,NULL, NULL, NULL, V_REMARKS, NULL) ;
EXCEPTION WHEN OTHERS
THEN V_REMARKS:='Not Processed';
SP_MIGRATION_PROCESS_LOG('SP_INSERT_SITE_WORKFLOW_PART1', V_START_TIME, V_END_TIME,V_REF_NAME, NULL, NULL,NULL, SQLCODE, SQLERRM, V_REMARKS, NULL) ;
END SP_INSERT_SITE_WORKFLOW_PART1;
PROCEDURE SP_INSERT_SITE_WORKFLOW_PART2 IS
    t_num NUMBER :=0;
    type t_PROC_INST_ID is table of NVARCHAR2(64 CHAR);
    v_PROC_INST_ID t_PROC_INST_ID;
--    V_PROD_INST_ID_LIST ALF_NUM_ARRAY;
    TMP_PROC_INST_ID NUMBER;
    V_SQL CLOB;
    V_SEQ number;
	V_START_TIME DATE;
	V_END_TIME DATE;
	V_REF_NAME VARCHAR2(100 CHAR);
	V_REF_ID NUMBER(38,0);
	V_REMARKS VARCHAR2(100 CHAR);
BEGIN
	V_START_TIME:=SYSDATE;
    V_REF_NAME:='INSERT_SITE_WORKFLOW';
    V_REF_ID:=0;
    V_REMARKS:='Completed successfully';
    begin
    v_sql:='Select PROC_INST_ID_ from tmp_wf_alf_uuid'||V_DB_LINK;
    EXECUTE IMMEDIATE v_sql BULK COLLECT into v_PROC_INST_ID;
        for i in 1..v_PROC_INST_ID.COUNT loop
            begin
--            --t_num :=t_num+1;
            INSERT_WF(v_PROC_INST_ID(i));
            EXCEPTION WHEN OTHERS then
                IF SQLCODE = '-2291' THEN
                    TMP_PROC_INST_ID:=v_PROC_INST_ID(i);
                    SP_ALF_POPULATE_NUM_FILTER_LIST('PROC_INST_ID',TMP_PROC_INST_ID,V_SEQ);
                end if;
            end;
  --          --if MOD(t_num,100)=0 then COMMIT; end if;
        end loop;
    COMMIT;
    IF V_SEQ >0 THEN SP_REPROCESS_PENDING_WF_RECS; END IF;

    --dbms_output.put_line('Processing Completed for '||v_sponsor||' And committed record count: '||t_num );
    end;
V_END_TIME:=SYSDATE;
SP_MIGRATION_PROCESS_LOG('SP_INSERT_SITE_WORKFLOW_PART2', V_START_TIME, V_END_TIME,V_REF_NAME, NULL, NULL,NULL, NULL, NULL, V_REMARKS, NULL) ;
EXCEPTION WHEN OTHERS
THEN V_REMARKS:='Not Processed';
SP_MIGRATION_PROCESS_LOG('SP_INSERT_SITE_WORKFLOW_PART2', V_START_TIME, V_END_TIME,V_REF_NAME, NULL, NULL,NULL, SQLCODE, SQLERRM, V_REMARKS, NULL) ;
END SP_INSERT_SITE_WORKFLOW_PART2;

PROCEDURE SP_REPROCESS_PENDING_WF_RECS IS
    V_SEQ number;
--    V_FILTER_VALUES ALF_NUM_ARRAY;
    TMP_FILTER_VALUES NUMBER;
BEGIN
FOR REC IN (Select FILTER_VALUES from TBL_ALF_NUM_FILTER where FILTER_TYPE='PROC_INST_ID') LOOP
    BEGIN
        update TBL_ALF_NUM_FILTER set FILTER_TYPE='WF-Step-3'
        where FILTER_TYPE='PROC_INST_ID' and FILTER_VALUES=rec.FILTER_VALUES;
        COMMIT;
        INSERT_WF(REC.FILTER_VALUES);
    EXCEPTION WHEN OTHERS then
        IF SQLCODE = '-2291' THEN
            TMP_FILTER_VALUES:=REC.FILTER_VALUES;
            SP_ALF_POPULATE_NUM_FILTER_LIST('PROC_INST_ID',TMP_FILTER_VALUES,V_SEQ);
--            ELSE TMP_FILTER_VALUES:=TMP_FILTER_VALUES||','||rec.FILTER_VALUES; END IF;
        end if;
    end;
END LOOP;
COMMIT;
END;

PROCEDURE SP_INSERT_ARCHIVE_DATA IS
    t_num NUMBER :=0;
    n number(10);
    Childcascade VARCHAR2(100) :='true'; --Change this to true if child cascade required
    type t_parent_id is table of alf_child_assoc.parent_node_id%type;
    type t_child_id is table of alf_child_assoc.child_node_id%type;
    v_parent_node_id t_parent_id;
    v_child_node_id t_child_id;
    V_SQL CLOB;
	V_START_TIME DATE;
	V_END_TIME DATE;
	V_REF_NAME VARCHAR2(100 CHAR);
	V_REF_ID NUMBER(38,0);
	V_REMARKS VARCHAR2(100 CHAR);

BEGIN
	V_START_TIME:=SYSDATE;
    V_REF_NAME:='INSERT_ARCHIVE_DATA';
    V_REF_ID:=0;
    V_REMARKS:='Completed successfully';
    V_SQL:='Select parent_node_id,child_node_id from (Select LEVEL,ch.* from alf_child_assoc'||V_DB_LINK||' ch
    START WITH  ch.parent_node_id in (Select root_node_id from alf_store'||V_DB_LINK||' where protocol=''archive'' and IDENTIFIER=''SpacesStore'')
CONNECT BY PRIOR  ch.child_node_id = ch.parent_node_id
ORDER BY 1,parent_node_id,child_node_id asc) t
where EXISTS (Select tq.local_name,tp.* from alf_node_properties'||V_DB_LINK||' tp join alf_qname'||V_DB_LINK||' tq on tq.id=tp.qname_id
where tp.node_id in (t.CHILD_NODE_ID) and tq.local_name in (''sponsorName'') and tp.string_value='''||v_sponsor||''' )';
    EXECUTE IMMEDIATE V_SQL BULK COLLECT INTO v_parent_node_id,v_child_node_id;
    begin
        for i in 1..v_child_node_id.COUNT loop
     --       --t_num :=t_num+1;
            INSERT_NODE(v_child_node_id(i),v_parent_node_id(i),'child',Childcascade);
       --     --if MOD(t_num,100)=0 then COMMIT; end if;
        end loop;
        COMMIT;
    --dbms_output.put_line('Processing Completed for '||v_sponsor||' And committed record count: '||t_num );
    end;
	V_END_TIME:=SYSDATE;
	SP_MIGRATION_PROCESS_LOG('SP_INSERT_ARCHIVE_DATA', V_START_TIME, V_END_TIME,V_REF_NAME, NULL, NULL,NULL, NULL, NULL, V_REMARKS, NULL) ;
EXCEPTION WHEN OTHERS
THEN V_REMARKS:='Not Processed';
SP_MIGRATION_PROCESS_LOG('SP_INSERT_ARCHIVE_DATA', V_START_TIME, V_END_TIME,V_REF_NAME, NULL, NULL,NULL, SQLCODE, SQLERRM, V_REMARKS, NULL) ;
END SP_INSERT_ARCHIVE_DATA;
PROCEDURE SP_INSERT_VERSION_DATA IS
    t_num NUMBER :=0;
    n number(10);
    Childcascade VARCHAR2(100) :='true'; --Change this to true if child cascade required
    type t_parent_id is table of alf_child_assoc.parent_node_id%type;
    type t_child_id is table of alf_child_assoc.child_node_id%type;
    v_parent_node_id t_parent_id;
    v_child_node_id t_child_id;
    V_SQL CLOB;
	V_START_TIME DATE;
	V_END_TIME DATE;
	V_REF_NAME VARCHAR2(100 CHAR);
	V_REF_ID NUMBER(38,0);
	V_REMARKS VARCHAR2(100 CHAR);

BEGIN
 	V_START_TIME:=SYSDATE;
    V_REF_NAME:='INSERT_VERSION_DATA';
    V_REF_ID:=0;
    V_REMARKS:='Completed successfully';
      V_SQL:='Select parent_node_id,child_node_id from(Select LEVEL,ch.* from alf_child_assoc'||V_DB_LINK||' ch  START WITH  ch.parent_node_id in (Select root_node_id from alf_store'||V_DB_LINK||' where protocol=''workspace'' and IDENTIFIER=''version2Store'')
CONNECT BY PRIOR  ch.child_node_id = ch.parent_node_id and level<2
ORDER BY 1,parent_node_id,child_node_id asc) t
where EXISTS (Select tq.local_name,tp.* from alf_node_properties'||V_DB_LINK||' tp join alf_qname'||V_DB_LINK||' tq on tq.id=tp.qname_id
where tp.node_id in (Select id from alf_node'||V_DB_LINK||' where uuid in
(Select p.string_value from alf_node_properties'||V_DB_LINK||' p join alf_qname'||V_DB_LINK||' q on q.id=p.qname_id where 1=1
and node_id in (t.CHILD_NODE_ID) and q.local_name in (''versionedNodeId'')))
and tq.local_name in (''sponsorName'') and tp.string_value='''||v_sponsor||''')';

    EXECUTE IMMEDIATE V_SQL BULK COLLECT INTO v_parent_node_id,v_child_node_id;
    begin
        for i in 1..v_child_node_id.COUNT loop
 --           --t_num :=t_num+1;
            INSERT_NODE(v_child_node_id(i),v_parent_node_id(i),'child',Childcascade);
   --         --if MOD(t_num,100)=0 then COMMIT; end if;
        end loop;
        COMMIT;
    --dbms_output.put_line('Processing Completed for '||v_sponsor||' And committed record count: '||t_num );
    end;
	V_END_TIME:=SYSDATE;
	SP_MIGRATION_PROCESS_LOG('SP_INSERT_VERSION_DATA', V_START_TIME, V_END_TIME,V_REF_NAME, NULL, NULL,NULL, NULL, NULL, V_REMARKS, NULL) ;
EXCEPTION WHEN OTHERS
THEN V_REMARKS:='Not Processed';
SP_MIGRATION_PROCESS_LOG('SP_INSERT_VERSION_DATA', V_START_TIME, V_END_TIME,V_REF_NAME, NULL, NULL,NULL, SQLCODE, SQLERRM, V_REMARKS, NULL) ;
END SP_INSERT_VERSION_DATA;

PROCEDURE SP_FIXING_NODE_ASSOC_DATA IS
	V_START_TIME DATE;
	V_END_TIME DATE;
	V_REF_NAME VARCHAR2(100 CHAR);
	V_REF_ID NUMBER(38,0);
	V_REMARKS VARCHAR2(100 CHAR);
BEGIN
V_START_TIME:=SYSDATE;
    V_REF_NAME:='SP_FIXING_NODE_ASSOC_DATA';
    V_REF_ID:=0;
    V_REMARKS:='Completed successfully';
--#Fix  Authority
    SP_FIX_AUTHORITY_DATA;
--#Fix Missing person
    SP_FIX_MISSING_PERSON_DATA;
--#Fix system Users
    SP_FIX_SYSTEM_USERS_DATA;
--#Fix person mapping
    SP_FIX_PERSON_MAPPING_DATA;
--#Fix Missing Content
    SP_FIX_MISSING_CONTENT_DATA;
-- #Fix ACL Inheritance
    SP_FIX_ACL_INHERITANCE_DATA;
--#Fix Associations
    SP_FIX_ASSOCIATION_DATA;
	V_END_TIME:=SYSDATE;
	SP_MIGRATION_PROCESS_LOG('SP_FIXING_NODE_ASSOC_DATA', V_START_TIME, V_END_TIME,V_REF_NAME, NULL, NULL,NULL, NULL, NULL, V_REMARKS, NULL) ;
EXCEPTION WHEN OTHERS
THEN V_REMARKS:='Not Processed';
SP_MIGRATION_PROCESS_LOG('SP_FIXING_NODE_ASSOC_DATA', V_START_TIME, V_END_TIME,V_REF_NAME, NULL, NULL,NULL, SQLCODE, SQLERRM, V_REMARKS, NULL) ;
END SP_FIXING_NODE_ASSOC_DATA;
PROCEDURE SP_FIX_AUTHORITY_DATA IS
    t_num NUMBER :=0;
    n number(10);
    Childcascade VARCHAR2(100) :='true'; --Change this to ture if child cascade required
    type t_parent_id is table of alf_child_assoc.parent_node_id%type;
    type t_child_id is table of alf_child_assoc.child_node_id%type;
    v_parent_node_id t_parent_id;
    v_child_node_id t_child_id;
    V_SQL CLOB;
    V_STRING_VALUE VARCHAR2(100):='GROUP_'||v_sponsor||'_%';
		V_START_TIME DATE;
	V_END_TIME DATE;
	V_REF_NAME VARCHAR2(100 CHAR);
	V_REF_ID NUMBER(38,0);
	V_REMARKS VARCHAR2(100 CHAR);

BEGIN
	V_START_TIME:=SYSDATE;
    V_REF_NAME:='SP_FIX_AUTHORITY_DATA';
    V_REF_ID:=0;
    V_REMARKS:='Completed successfully';
    V_SQL:='Select parent_node_id,child_node_id from  alf_child_assoc'||V_DB_LINK||' ch where child_node_id in (select p.node_id from alf_node_properties'||V_DB_LINK||' p
join alf_qname'||V_DB_LINK||' q on q.id=p.qname_id
where p.STRING_VALUE like '''||V_STRING_VALUE ||''' and q.local_name=''authorityName'')
minus
Select parent_node_id,child_node_id  from  alf_child_assoc ch where child_node_id in (select p.node_id from alf_node_properties p
join alf_qname q on q.id=p.qname_id
where p.STRING_VALUE like '''||V_STRING_VALUE ||''' and q.local_name=''authorityName'')';
    EXECUTE IMMEDIATE V_SQL BULK COLLECT INTO v_parent_node_id,v_child_node_id;
    begin
        for i in 1..v_child_node_id.COUNT loop
--            --t_num :=t_num+1;
            INSERT_NODE(v_child_node_id(i),v_parent_node_id(i),'child',Childcascade);
  --          --if MOD(t_num,100)=0 then COMMIT; end if;
        end loop;
        COMMIT;
    --dbms_output.put_line('Authority Fix Completed for '||v_sponsor||' And committed record count: '||t_num );
    end;
    V_END_TIME:=SYSDATE;
	SP_MIGRATION_PROCESS_LOG('SP_FIX_AUTHORITY_DATA', V_START_TIME, V_END_TIME,V_REF_NAME, NULL, NULL,NULL, NULL, NULL, V_REMARKS, NULL) ;
EXCEPTION WHEN OTHERS
THEN V_REMARKS:='Not Processed';
SP_MIGRATION_PROCESS_LOG('SP_FIX_AUTHORITY_DATA', V_START_TIME, V_END_TIME,V_REF_NAME, NULL, NULL,NULL, SQLCODE, SQLERRM, V_REMARKS, NULL) ;
END SP_FIX_AUTHORITY_DATA;
PROCEDURE SP_FIX_MISSING_PERSON_DATA IS
    t_num NUMBER :=0;
    type t_parent_id is table of alf_child_assoc.parent_node_id%type;
    type t_child_id is table of alf_child_assoc.child_node_id%type;
    type t_node_id is table of alf_node_properties.node_id%type;
    v_parent_node_id t_parent_id;
    v_child_node_id t_child_id;
    v_node_id t_node_id;
    V_SQL CLOB;
	V_START_TIME DATE;
	V_END_TIME DATE;
	V_REF_NAME VARCHAR2(100 CHAR);
	V_REF_ID NUMBER(38,0);
	V_REMARKS VARCHAR2(100 CHAR);

BEGIN
	V_START_TIME:=SYSDATE;
    V_REF_NAME:='FIX_MISSING_PERSON';
    V_REF_ID:=0;
    V_REMARKS:='Completed successfully';
    V_SQL:='Select p.node_id from alf_node_properties'||V_DB_LINK||' p
join alf_qname'||V_DB_LINK||' q on q.id=p.qname_id where 1=1
and q.local_name in (''userName'')
and node_id in (Select  n.id from alf_node'||V_DB_LINK||' n
join alf_qname'||V_DB_LINK||' q on q.id=n.type_qname_id where 1=1
and q.local_name in (''person''))
and p.STRING_VALUE  in (
Select  p.string_value from alf_node_properties p join alf_qname q on q.id=p.qname_id where 1=1
and q.local_name in (''username'')
and node_id in (Select  n.id from alf_node n
join alf_qname q on q.id=n.type_qname_id where 1=1
and q.local_name in (''user''))
minus
Select p.string_value from alf_node_properties p join alf_qname q on q.id=p.qname_id where 1=1
and q.local_name in (''userName'')
and node_id in (Select  n.id from alf_node n
join alf_qname q on q.id=n.type_qname_id where 1=1
and q.local_name in (''person'')))';

    EXECUTE IMMEDIATE V_SQL BULK COLLECT INTO v_node_id;
    begin
        for i in 1..v_node_id.COUNT loop
--            --t_num :=t_num+1;
            V_SQL:='SELECT parent_node_id,child_node_id from (Select t.* from (Select LEVEL,SYS_CONNECT_BY_PATH(ch.qname_localname, ''/'') "Path",ch.* from alf_child_assoc'||V_DB_LINK||' ch  START WITH  ch.child_node_id in ('||v_node_id(i)||') CONNECT BY   PRIOR ch.child_node_id =  ch.parent_node_id) t)';
            EXECUTE IMMEDIATE V_SQL BULK COLLECT INTO v_parent_node_id,v_child_node_id;
            for j in 1..v_child_node_id.COUNT loop
  --              --t_num :=t_num+1;
                INSERT_NODE(v_child_node_id(j),v_parent_node_id(j),'child','false');
            END LOOP;
    --        --if MOD(t_num,100)=0 then COMMIT; end if;
            end loop;
            COMMIT;
        END;
	V_END_TIME:=SYSDATE;
	SP_MIGRATION_PROCESS_LOG('SP_FIX_MISSING_PERSON_DATA', V_START_TIME, V_END_TIME,V_REF_NAME, NULL, NULL,NULL, NULL, NULL, V_REMARKS, NULL) ;
EXCEPTION WHEN OTHERS
THEN V_REMARKS:='Not Processed';
SP_MIGRATION_PROCESS_LOG('SP_FIX_MISSING_PERSON_DATA', V_START_TIME, V_END_TIME,V_REF_NAME, NULL, NULL,NULL, SQLCODE, SQLERRM, V_REMARKS, NULL) ;
END SP_FIX_MISSING_PERSON_DATA;

PROCEDURE SP_FIX_SYSTEM_USERS_DATA IS
    t_num NUMBER :=0;
    type t_parent_id is table of alf_child_assoc.parent_node_id%type;
    type t_child_id is table of alf_child_assoc.child_node_id%type;
    type t_node_id is table of alf_node_properties.node_id%type;
    v_parent_node_id t_parent_id;
    v_child_node_id t_child_id;
    v_node_id t_node_id;
    V_SQL CLOB;
	V_START_TIME DATE;
	V_END_TIME DATE;
	V_REF_NAME VARCHAR2(100 CHAR);
	V_REF_ID NUMBER(38,0);
	V_REMARKS VARCHAR2(100 CHAR);

BEGIN
	V_START_TIME:=SYSDATE;
    V_REF_NAME:='FIX_SYSTEM_USERS';
    V_REF_ID:=0;
    V_REMARKS:='Completed successfully';
V_SQL:='Select node_id FROM (Select q.local_name ,(select local_name from alf_qname'||V_DB_LINK||' where id=n.TYPE_QNAME_ID ) node_type,p.* from alf_node'||V_DB_LINK||' n
join alf_node_properties'||V_DB_LINK||' p on n.id=p.node_id
join alf_qname'||V_DB_LINK||' q on q.id=p.qname_id
and q.local_name in (''userName'',''username'',''name'')
and n.type_qname_id in (select id from alf_qname'||V_DB_LINK||' where local_name in (''user'',''folder'',''person''))
and p.string_value in (''safed-facility-user-'||v_sponsor||'-member-id0'',''safedx'||v_sponsor||'integuser'',''safed-system-user-'||v_sponsor||'-member-id0''))';
    EXECUTE IMMEDIATE V_SQL BULK COLLECT INTO v_node_id;
    begin
        for i in 1..v_node_id.COUNT loop
--            --t_num :=t_num+1;
            V_SQL:='SELECT parent_node_id,child_node_id from (Select LEVEL,SYS_CONNECT_BY_PATH(ch.qname_localname, ''/'') "Path",ch.* from alf_child_assoc'||V_DB_LINK||' ch  START WITH  ch.child_node_id in ('||v_node_id(i)||') CONNECT BY   PRIOR ch.child_node_id =  ch.parent_node_id)';
            EXECUTE IMMEDIATE V_SQL BULK COLLECT INTO v_parent_node_id,v_child_node_id;
            for j in 1..v_child_node_id.COUNT loop
  --              --t_num :=t_num+1;
                INSERT_NODE(v_child_node_id(j),v_parent_node_id(j),'child','false');
            END LOOP;
    --    --if MOD(t_num,100)=0 then COMMIT; end if;
        end loop;
    commit;
    END;
    V_END_TIME:=SYSDATE;
	SP_MIGRATION_PROCESS_LOG('SP_FIX_SYSTEM_USERS_DATA', V_START_TIME, V_END_TIME,V_REF_NAME, NULL, NULL,NULL, NULL, NULL, V_REMARKS, NULL) ;
EXCEPTION WHEN OTHERS
THEN V_REMARKS:='Not Processed';
SP_MIGRATION_PROCESS_LOG('SP_FIX_SYSTEM_USERS_DATA', V_START_TIME, V_END_TIME,V_REF_NAME, NULL, NULL,NULL, SQLCODE, SQLERRM, V_REMARKS, NULL) ;
END SP_FIX_SYSTEM_USERS_DATA;

PROCEDURE SP_FIX_PERSON_MAPPING_DATA IS
V_START_TIME DATE;
V_END_TIME DATE;
V_REF_NAME VARCHAR2(100 CHAR);
V_REF_ID NUMBER(38,0);
V_TABLE_NAME VARCHAR2(100 CHAR);
V_PRE_DATA_COUNT NUMBER(38,0);
V_POST_DATA_COUNT NUMBER(38,0);
V_REMARKS VARCHAR2(100 CHAR);
V_SQL CLOB;
BEGIN
    V_START_TIME:=SYSDATE;
    V_REF_NAME:='FIX_PERSON_MAPPING_DATA';
    V_REF_ID:=0;
    V_REMARKS:='Completed successfully';

	BEGIN
		V_SQL:='Select count (1) from alf_child_assoc'||V_DB_LINK||' a where (a.child_node_id in (Select  n.id from alf_node n
		join alf_qname q on q.id=n.type_qname_id where 1=1
		and q.local_name in (''person'')))
		and not EXISTS (select 1 from alf_child_assoc e where e.id=a.id)
		and EXISTS (select 1 from alf_node n where n.id=a.PARENT_NODE_ID)';
		EXECUTE IMMEDIATE V_SQL INTO V_PRE_DATA_COUNT;
		V_TABLE_NAME:='alf_child_assoc';
		V_SQL:='INSERT into alf_child_assoc
		Select * from alf_child_assoc'||V_DB_LINK||' a where (a.child_node_id in (Select  n.id from alf_node n
		join alf_qname q on q.id=n.type_qname_id where 1=1
		and q.local_name in (''person'')))
		and not EXISTS (select 1 from alf_child_assoc e where e.id=a.id)
		and EXISTS (select 1 from alf_node n where n.id=a.PARENT_NODE_ID)';
		EXECUTE IMMEDIATE V_SQL;
		V_SQL:='Select count (1) from alf_child_assoc a where (a.child_node_id in (Select  n.id from alf_node n
		join alf_qname q on q.id=n.type_qname_id where 1=1
		and q.local_name in (''person'')))
		and EXISTS (select 1 from alf_node n where n.id=a.PARENT_NODE_ID)';
		EXECUTE IMMEDIATE V_SQL INTO V_POST_DATA_COUNT;
		V_END_TIME:=SYSDATE;
			SP_MIGRATION_PROCESS_LOG('SP_FIX_PERSON_MAPPING_DATA', V_START_TIME, V_END_TIME,V_REF_NAME, V_REF_ID, V_PRE_DATA_COUNT, V_POST_DATA_COUNT,NULL,NULL,V_REMARKS, V_TABLE_NAME);
	EXCEPTION
		WHEN OTHERS THEN
			V_REMARKS:='Not Processed';
			SP_MIGRATION_PROCESS_LOG('SP_FIX_PERSON_MAPPING_DATA', V_START_TIME, V_END_TIME,V_REF_NAME, V_REF_ID, V_PRE_DATA_COUNT,NULL, SQLCODE, SQLERRM, V_REMARKS, V_TABLE_NAME) ;
	END;

	BEGIN
		V_REMARKS:='Completed successfully';
		V_START_TIME:=V_END_TIME;
		V_SQL:='Select count (1) from alf_auth_status'||V_DB_LINK||'  where username in (
		Select p.STRING_VALUE from alf_node_properties p join alf_qname q on q.id=p.qname_id where 1=1
		and q.local_name in (''username'')
		and node_id in (Select  n.id from alf_node n
		join alf_qname q on q.id=n.type_qname_id where 1=1
		and q.local_name in (''user''))
		and not EXISTS (Select 1 from alf_auth_status  where username=p.STRING_VALUE)
		and EXISTS (Select 1 from alf_auth_status'||V_DB_LINK||'  where username=p.STRING_VALUE))';
		EXECUTE IMMEDIATE V_SQL INTO V_PRE_DATA_COUNT;
		V_TABLE_NAME:='alf_auth_status';
		V_SQL:='insert into alf_auth_status
		Select * from alf_auth_status'||V_DB_LINK||'  where username in (
		Select p.STRING_VALUE from alf_node_properties p join alf_qname q on q.id=p.qname_id where 1=1
		and q.local_name in (''username'')
		and node_id in (Select  n.id from alf_node n
		join alf_qname q on q.id=n.type_qname_id where 1=1
		and q.local_name in (''user''))
		and not EXISTS (Select 1 from alf_auth_status  where username=p.STRING_VALUE)
		and EXISTS (Select 1 from alf_auth_status'||V_DB_LINK||'  where username=p.STRING_VALUE))';
		EXECUTE IMMEDIATE V_SQL;
		V_SQL:='Select count (1) from alf_auth_status  where username in (
		Select p.STRING_VALUE from alf_node_properties p join alf_qname q on q.id=p.qname_id where 1=1
		and q.local_name in (''username'')
		and node_id in (Select  n.id from alf_node n
		join alf_qname q on q.id=n.type_qname_id where 1=1
		and q.local_name in (''user''))
		and EXISTS (Select 1 from alf_auth_status  where username=p.STRING_VALUE))';
		EXECUTE IMMEDIATE V_SQL INTO V_POST_DATA_COUNT;
		V_END_TIME:=SYSDATE;
			SP_MIGRATION_PROCESS_LOG('SP_FIX_PERSON_MAPPING_DATA', V_START_TIME, V_END_TIME,V_REF_NAME, V_REF_ID, V_PRE_DATA_COUNT, V_POST_DATA_COUNT,NULL,NULL,V_REMARKS, V_TABLE_NAME);
	EXCEPTION
		WHEN OTHERS THEN
			V_REMARKS:='Not Processed';
			SP_MIGRATION_PROCESS_LOG('SP_FIX_PERSON_MAPPING_DATA', V_START_TIME, V_END_TIME,V_REF_NAME, V_REF_ID, V_PRE_DATA_COUNT,NULL, SQLCODE, SQLERRM, V_REMARKS, V_TABLE_NAME) ;
	END;
	COMMIT;

EXCEPTION
	WHEN OTHERS THEN
		V_REMARKS:='Not Processed';
		SP_MIGRATION_PROCESS_LOG('SP_FIX_PERSON_MAPPING_DATA', NULL, NULL,NULL, NULL, NULL,NULL, SQLCODE, SQLERRM, V_REMARKS, NULL) ;
END SP_FIX_PERSON_MAPPING_DATA;

PROCEDURE SP_FIX_MISSING_CONTENT_DATA IS
    t_num NUMBER :=0;
    type t_content_id is table of alf_node_properties.long_value%type;
    v_content_id t_content_id;
    V_START_TIME DATE;
	V_END_TIME DATE;
	V_REF_NAME VARCHAR2(100 CHAR);
	V_REF_ID NUMBER(38,0);
	V_TABLE_NAME VARCHAR2(100 CHAR);
	V_PRE_DATA_COUNT NUMBER(38,0);
	V_POST_DATA_COUNT NUMBER(38,0);
	V_REMARKS VARCHAR2(100 CHAR);
	V_SQL CLOB;

BEGIN
    V_START_TIME:=SYSDATE;
    V_REF_NAME:='FIX_MISSING_CONTENT_DATA';
    V_REF_ID:=0;
    V_REMARKS:='Completed successfully';
    BEGIN
    V_SQL:='SELECT p.long_value FROM alf_node_properties p where p.LONG_VALUE <>0
and not EXISTS (select 1 from alf_content_data d where d.id=p.LONG_VALUE)
and EXISTS (select 1 from alf_content_data'||V_DB_LINK||' cd where cd.id=p.LONG_VALUE)';
    EXECUTE IMMEDIATE V_SQL BULK COLLECT INTO v_content_id;

        for i in 1..v_content_id.COUNT loop
            --t_num :=t_num+1;
    --        dbms_output.put_line('Processing content_id : '|| i.content_id);
            BEGIN
				V_SQL:='Select count (1) from ALF_CONTENT_URL'||V_DB_LINK||' a where a.id in (Select  DISTINCT content_URL_Id from ALF_CONTENT_DATA'||V_DB_LINK||' where id in ('||v_content_id(i)||'))
				and not EXISTS (select * from ALF_CONTENT_URL e where e.ID=a.ID)';
				EXECUTE IMMEDIATE V_SQL INTO V_PRE_DATA_COUNT;
				V_TABLE_NAME:='ALF_CONTENT_URL';
				V_SQL:='Insert into ALF_CONTENT_URL Select * from ALF_CONTENT_URL'||V_DB_LINK||' a where a.id in (Select  DISTINCT content_URL_Id from ALF_CONTENT_DATA'||V_DB_LINK||' where id in ('||v_content_id(i)||'))
				and not EXISTS (select * from ALF_CONTENT_URL e where e.ID=a.ID)';
				EXECUTE IMMEDIATE V_SQL;
				V_SQL:='Select count (1) from ALF_CONTENT_URL a where a.id in (Select  DISTINCT content_URL_Id from ALF_CONTENT_DATA where id in ('||v_content_id(i)||'))';
				EXECUTE IMMEDIATE V_SQL INTO V_POST_DATA_COUNT;
				V_END_TIME:=SYSDATE;
					SP_MIGRATION_PROCESS_LOG('SP_FIX_MISSING_CONTENT_DATA', V_START_TIME, V_END_TIME,V_REF_NAME, V_REF_ID, V_PRE_DATA_COUNT, V_POST_DATA_COUNT,NULL,NULL,V_REMARKS, V_TABLE_NAME);
			EXCEPTION
				WHEN OTHERS THEN
					V_REMARKS:='Not Processed';
					SP_MIGRATION_PROCESS_LOG('SP_FIX_MISSING_CONTENT_DATA', V_START_TIME, V_END_TIME,V_REF_NAME, V_REF_ID, V_PRE_DATA_COUNT,NULL, SQLCODE, SQLERRM, V_REMARKS, V_TABLE_NAME) ;
			END;

			BEGIN
				V_REMARKS:='Completed successfully';
				V_START_TIME:=V_END_TIME;
				V_SQL:='Select count (1) from ALF_CONTENT_DATA'||V_DB_LINK||' a where a.id in ('||v_content_id(i)||')
				and not EXISTS (select * from ALF_CONTENT_DATA e where e.ID=a.ID)';
				EXECUTE IMMEDIATE V_SQL INTO V_PRE_DATA_COUNT;
				V_TABLE_NAME:='ALF_CONTENT_DATA';
				V_SQL:='Insert into ALF_CONTENT_DATA Select * from ALF_CONTENT_DATA'||V_DB_LINK||' a where a.id in ('||v_content_id(i)||')
				and not EXISTS (select * from ALF_CONTENT_DATA e where e.ID=a.ID)';
				EXECUTE IMMEDIATE V_SQL;
				V_SQL:='Select count (1) from ALF_CONTENT_DATA a where a.id in ('||v_content_id(i)||')';
				EXECUTE IMMEDIATE V_SQL INTO V_POST_DATA_COUNT;
				V_END_TIME:=SYSDATE;
					SP_MIGRATION_PROCESS_LOG('SP_FIX_MISSING_CONTENT_DATA', V_START_TIME, V_END_TIME,V_REF_NAME, V_REF_ID, V_PRE_DATA_COUNT, V_POST_DATA_COUNT,NULL,NULL,V_REMARKS, V_TABLE_NAME);
			EXCEPTION
				WHEN OTHERS THEN
					V_REMARKS:='Not Processed';
					SP_MIGRATION_PROCESS_LOG('SP_FIX_MISSING_CONTENT_DATA', V_START_TIME, V_END_TIME,V_REF_NAME, V_REF_ID, V_PRE_DATA_COUNT,NULL, SQLCODE, SQLERRM, V_REMARKS, V_TABLE_NAME) ;
			END;

			BEGIN
				V_REMARKS:='Completed successfully';
				V_START_TIME:=V_END_TIME;
				V_SQL:='Select count (1) from alf_audit_model'||V_DB_LINK||' a where a.CONTENT_DATA_ID in ('||v_content_id(i)||')
				and not EXISTS (select * from alf_audit_model e where e.ID=a.ID)';
				EXECUTE IMMEDIATE V_SQL INTO V_PRE_DATA_COUNT;
				V_TABLE_NAME:='alf_audit_model';
				V_SQL:='Insert into alf_audit_model Select * from alf_audit_model'||V_DB_LINK||' a where a.CONTENT_DATA_ID in ('||v_content_id(i)||')
				and not EXISTS (select * from alf_audit_model e where e.ID=a.ID)';
				EXECUTE IMMEDIATE V_SQL;
				V_SQL:='Select count (1) from alf_audit_model a where a.CONTENT_DATA_ID in ('||v_content_id(i)||')';
				EXECUTE IMMEDIATE V_SQL INTO V_POST_DATA_COUNT;
				V_END_TIME:=SYSDATE;
					SP_MIGRATION_PROCESS_LOG('SP_FIX_MISSING_CONTENT_DATA', V_START_TIME, V_END_TIME,V_REF_NAME, V_REF_ID, V_PRE_DATA_COUNT, V_POST_DATA_COUNT,NULL,NULL,V_REMARKS, V_TABLE_NAME);
			EXCEPTION
				WHEN OTHERS THEN
					V_REMARKS:='Not Processed';
					SP_MIGRATION_PROCESS_LOG('SP_FIX_MISSING_CONTENT_DATA', V_START_TIME, V_END_TIME,V_REF_NAME, V_REF_ID, V_PRE_DATA_COUNT,NULL, SQLCODE, SQLERRM, V_REMARKS, V_TABLE_NAME) ;
			END;
            --if MOD(t_num,100)=0 then
			--COMMIT;
			--end if;
        end loop;
    COMMIT;
    --dbms_output.put_line('Fix Content Completed And committed record count: '||t_num );
    end;

EXCEPTION
	WHEN OTHERS THEN
		V_REMARKS:='Not Processed';
		SP_MIGRATION_PROCESS_LOG('SP_FIX_MISSING_CONTENT_DATA', NULL, NULL,NULL, NULL, NULL,NULL, SQLCODE, SQLERRM, V_REMARKS, NULL) ;
END SP_FIX_MISSING_CONTENT_DATA;

PROCEDURE SP_FIX_ACL_INHERITANCE_DATA IS
V_SQL CLOB;
V_START_TIME DATE;
V_END_TIME DATE;
V_REF_NAME VARCHAR2(100 CHAR);
V_REF_ID NUMBER(38,0);
V_TABLE_NAME VARCHAR2(100 CHAR);
V_PRE_DATA_COUNT NUMBER(38,0);
V_POST_DATA_COUNT NUMBER(38,0);
V_REMARKS VARCHAR2(100 CHAR);

BEGIN
    V_START_TIME:=SYSDATE;
    V_REF_NAME:='FIX_ACL_INHERITANCE_DATA';
    V_REF_ID:=0;
    V_REMARKS:='Completed successfully';

	    begin
		     V_SQL:='Select count(1) from alf_acl_change_set'||V_DB_LINK||' a where a.id in(
             Select DISTINCT ACL_CHANGE_SET from alf_access_control_list'||V_DB_LINK||' where id in (Select DISTINCT a.INHERITED_ACL from alf_access_control_list a where
             not EXISTS (Select 1 from alf_access_control_list b where b.id=a.INHERITED_ACL)))
             and not exists(select 1 from alf_acl_change_set e where a.id=e.id)';
			 EXECUTE IMMEDIATE V_SQL INTO V_PRE_DATA_COUNT;
	        V_TABLE_NAME:='alf_acl_change_set';
            V_SQL:='INSERT into alf_acl_change_set Select * from alf_acl_change_set'||V_DB_LINK||' a where a.id in(
            Select DISTINCT ACL_CHANGE_SET from alf_access_control_list'||V_DB_LINK||' where id in (Select DISTINCT a.INHERITED_ACL from alf_access_control_list a where
            not EXISTS (Select 1 from alf_access_control_list b where b.id=a.INHERITED_ACL)))
            and not exists(select 1 from alf_acl_change_set e where a.id=e.id)';
            EXECUTE IMMEDIATE V_SQL;
			V_SQL:='Select count(1) from alf_acl_change_set a where a.id in(
             Select DISTINCT ACL_CHANGE_SET from alf_access_control_list where id in (Select DISTINCT a.INHERITED_ACL from alf_access_control_list a where
             not EXISTS (Select 1 from alf_access_control_list b where b.id=a.INHERITED_ACL))) ';
			EXECUTE IMMEDIATE V_SQL INTO V_POST_DATA_COUNT;
		    V_END_TIME:=SYSDATE;
			SP_MIGRATION_PROCESS_LOG('SP_FIX_ACL_INHERITANCE_DATA', V_START_TIME, V_END_TIME,V_REF_NAME, V_REF_ID, V_PRE_DATA_COUNT, V_POST_DATA_COUNT,NULL,NULL,V_REMARKS, V_TABLE_NAME);
	    EXCEPTION
		    WHEN OTHERS THEN
		    	V_REMARKS:='Not Processed';
		    	SP_MIGRATION_PROCESS_LOG('SP_FIX_ACL_INHERITANCE_DATA', V_START_TIME, V_END_TIME,V_REF_NAME, V_REF_ID, V_PRE_DATA_COUNT,NULL, SQLCODE, SQLERRM, V_REMARKS, V_TABLE_NAME) ;
	    END;

		begin
			V_REMARKS:='Completed successfully';
			V_START_TIME:=V_END_TIME;
		    V_SQL:=' Select count(1) from alf_access_control_list'||V_DB_LINK||' where id in (Select DISTINCT a.INHERITED_ACL from alf_access_control_list a where
            not EXISTS (Select 1 from alf_access_control_list b where b.id=a.INHERITED_ACL))';
			EXECUTE IMMEDIATE V_SQL INTO V_PRE_DATA_COUNT;
	        V_TABLE_NAME:='alf_access_control_list';
            V_SQL:='INSERT into alf_access_control_list Select * from alf_access_control_list'||V_DB_LINK||' where id in (Select DISTINCT a.INHERITED_ACL from alf_access_control_list a where
             not EXISTS (Select 1 from alf_access_control_list b where b.id=a.INHERITED_ACL))';
             EXECUTE IMMEDIATE V_SQL;
			  V_SQL:=' Select count(1) from alf_access_control_list where id in (Select DISTINCT a.INHERITED_ACL from alf_access_control_list a )';
			 EXECUTE IMMEDIATE V_SQL INTO V_POST_DATA_COUNT;
		    V_END_TIME:=SYSDATE;
			SP_MIGRATION_PROCESS_LOG('SP_FIX_ACL_INHERITANCE_DATA', V_START_TIME, V_END_TIME,V_REF_NAME, V_REF_ID, V_PRE_DATA_COUNT, V_POST_DATA_COUNT,NULL,NULL,V_REMARKS, V_TABLE_NAME);
	    EXCEPTION
		    WHEN OTHERS THEN
		    	V_REMARKS:='Not Processed';
		    	SP_MIGRATION_PROCESS_LOG('SP_FIX_ACL_INHERITANCE_DATA', V_START_TIME, V_END_TIME,V_REF_NAME, V_REF_ID, V_PRE_DATA_COUNT,NULL, SQLCODE, SQLERRM, V_REMARKS, V_TABLE_NAME) ;
	    END;

		begin
			V_REMARKS:='Completed successfully';
			V_START_TIME:=V_END_TIME;
            V_SQL:=' Select count(1) from alf_acl_member'||V_DB_LINK||' a where a.acl_id in (Select id from alf_access_control_list a where
            not EXISTS (Select 1 from alf_acl_member b where b.acl_id=a.id))';
            EXECUTE IMMEDIATE V_SQL INTO V_PRE_DATA_COUNT;
	        V_TABLE_NAME:='alf_acl_member';
            V_SQL:='Insert into alf_acl_member Select * from alf_acl_member'||V_DB_LINK||' a where a.acl_id in (Select id from alf_access_control_list a where
             not EXISTS (Select 1 from alf_acl_member b where b.acl_id=a.id))';
             EXECUTE IMMEDIATE V_SQL;
			 V_SQL:=' Select count(1) from alf_acl_member a where a.acl_id in (Select id from alf_access_control_list a )';
			 EXECUTE IMMEDIATE V_SQL INTO V_POST_DATA_COUNT;
		    V_END_TIME:=SYSDATE;
			SP_MIGRATION_PROCESS_LOG('SP_FIX_ACL_INHERITANCE_DATA', V_START_TIME, V_END_TIME,V_REF_NAME, V_REF_ID, V_PRE_DATA_COUNT, V_POST_DATA_COUNT,NULL,NULL,V_REMARKS, V_TABLE_NAME);
	    EXCEPTION
		    WHEN OTHERS THEN
		    	V_REMARKS:='Not Processed';
		    	SP_MIGRATION_PROCESS_LOG('SP_FIX_ACL_INHERITANCE_DATA', V_START_TIME, V_END_TIME,V_REF_NAME, V_REF_ID, V_PRE_DATA_COUNT,NULL, SQLCODE, SQLERRM, V_REMARKS, V_TABLE_NAME) ;
	    END;

		begin
			V_REMARKS:='Completed successfully';
			V_START_TIME:=V_END_TIME;
		    V_SQL:=' Select count(1) from alf_access_control_entry'||V_DB_LINK||' ae where ae.id in(
            Select distinct ACE_ID from alf_acl_member'||V_DB_LINK||' where acl_id in (Select id from alf_access_control_list a where
            not EXISTS (Select 1 from alf_acl_member b where b.acl_id=a.id)))
            and not EXISTS (Select 1 from alf_access_control_entry e where e.id=ae.id)';
			EXECUTE IMMEDIATE V_SQL INTO V_PRE_DATA_COUNT;
	        V_TABLE_NAME:='alf_access_control_entry';
            V_SQL:='Insert into alf_access_control_entry
            Select * from alf_access_control_entry'||V_DB_LINK||' ae where ae.id in(
            Select distinct ACE_ID from alf_acl_member'||V_DB_LINK||' where acl_id in (Select id from alf_access_control_list a where
            not EXISTS (Select 1 from alf_acl_member b where b.acl_id=a.id)))
            and not EXISTS (Select 1 from alf_access_control_entry e where e.id=ae.id)';
			EXECUTE IMMEDIATE V_SQL;
			V_SQL:=' Select count(1) from alf_access_control_entry ae where ae.id in(
            Select distinct ACE_ID from alf_acl_member where acl_id in (Select id from alf_access_control_list a where
            not EXISTS (Select 1 from alf_acl_member b where b.acl_id=a.id)))  ';
            EXECUTE IMMEDIATE V_SQL INTO V_POST_DATA_COUNT;
		    V_END_TIME:=SYSDATE;
		    	SP_MIGRATION_PROCESS_LOG('SP_FIX_ACL_INHERITANCE_DATA', V_START_TIME, V_END_TIME,V_REF_NAME, V_REF_ID, V_PRE_DATA_COUNT, V_POST_DATA_COUNT,NULL,NULL,V_REMARKS, V_TABLE_NAME);
	    EXCEPTION
		        WHEN OTHERS THEN
		        	V_REMARKS:='Not Processed';
		        	SP_MIGRATION_PROCESS_LOG('SP_FIX_ACL_INHERITANCE_DATA', V_START_TIME, V_END_TIME,V_REF_NAME, V_REF_ID, V_PRE_DATA_COUNT,NULL, SQLCODE, SQLERRM, V_REMARKS, V_TABLE_NAME) ;
	     END;
        commit;


EXCEPTION
		WHEN OTHERS THEN
			V_REMARKS:='Not Processed';
			SP_MIGRATION_PROCESS_LOG('SP_FIX_ACL_INHERITANCE_DATA', NULL, NULL,NULL, NULL, NULL,NULL, SQLCODE, SQLERRM, V_REMARKS, NULL) ;
END SP_FIX_ACL_INHERITANCE_DATA;

PROCEDURE SP_FIX_ASSOCIATION_DATA IS
V_SQL CLOB;
V_START_TIME DATE;
V_END_TIME DATE;
V_REF_NAME VARCHAR2(100 CHAR);
V_REF_ID NUMBER(38,0);
V_TABLE_NAME VARCHAR2(100 CHAR);
V_PRE_DATA_COUNT NUMBER(38,0);
V_POST_DATA_COUNT NUMBER(38,0);
V_REMARKS VARCHAR2(100 CHAR);

BEGIN
    V_START_TIME:=SYSDATE;
    V_REF_NAME:='FIX_ASSOCIATION_DATA';
    V_REF_ID:=0;
    V_REMARKS:='Completed successfully';

    BEGIN
	     V_SQL:='Select count(1) from alf_node_assoc'||V_DB_LINK||' a
         where a.TARGET_NODE_ID in (Select id from alf_node)
         and not EXISTS (Select * from alf_node_assoc e where e.id=a.id )
         and EXISTS (Select id from alf_node n where n.id=a.SOURCE_NODE_ID)';
         EXECUTE IMMEDIATE V_SQL INTO V_PRE_DATA_COUNT;
	    V_TABLE_NAME:='alf_node_assoc';
        V_SQL:='insert into alf_node_assoc
        Select * from alf_node_assoc'||V_DB_LINK||' a
        where a.TARGET_NODE_ID in (Select id from alf_node)
        and not EXISTS (Select * from alf_node_assoc e where e.id=a.id )
        and EXISTS (Select id from alf_node n where n.id=a.SOURCE_NODE_ID)';
        EXECUTE IMMEDIATE V_SQL;
		V_SQL:='Select count(1) from alf_node_assoc a
         where a.TARGET_NODE_ID in (Select id from alf_node)
         and EXISTS (Select id from alf_node n where n.id=a.SOURCE_NODE_ID)';
		EXECUTE IMMEDIATE V_SQL INTO V_POST_DATA_COUNT;
		V_END_TIME:=SYSDATE;
			SP_MIGRATION_PROCESS_LOG('SP_FIX_ASSOCIATION_DATA', V_START_TIME, V_END_TIME,V_REF_NAME, V_REF_ID, V_PRE_DATA_COUNT, V_POST_DATA_COUNT,NULL,NULL,V_REMARKS, V_TABLE_NAME);
	EXCEPTION
		WHEN OTHERS THEN
			V_REMARKS:='Not Processed';
			SP_MIGRATION_PROCESS_LOG('SP_FIX_ASSOCIATION_DATA', V_START_TIME, V_END_TIME,V_REF_NAME, V_REF_ID, V_PRE_DATA_COUNT,NULL, SQLCODE, SQLERRM, V_REMARKS, V_TABLE_NAME) ;
	END;
    commit;

EXCEPTION
		WHEN OTHERS THEN
			V_REMARKS:='Not Processed';
			SP_MIGRATION_PROCESS_LOG('SP_FIX_ASSOCIATION_DATA', NULL, NULL,NULL, NULL, NULL,NULL, SQLCODE, SQLERRM, V_REMARKS, NULL) ;

END SP_FIX_ASSOCIATION_DATA;
PROCEDURE SEQUENCE_SYNCHRONIZATION IS
trnx_maxid NUMBER;
seq_maxid NUMBER;
v_sql varchar2(1024);
v_id varchar2(400);
	V_START_TIME DATE;
	V_END_TIME DATE;
	V_REF_NAME VARCHAR2(100 CHAR);
	V_REF_ID NUMBER(38,0);
	V_REMARKS VARCHAR2(100 CHAR);
BEGIN
	V_START_TIME:=SYSDATE;
    V_REF_NAME:='SEQUENCE_SYNCHRONIZATION';
    V_REF_ID:=0;
    V_REMARKS:='Completed successfully';
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
            --    DBMS_OUTPUT.PUT_LINE(s.table_name||' sequence need to update' ||' Current sequnce:'||seq_maxid||' Max ID:'||trnx_maxid);
                EXECUTE IMMEDIATE 'DROP SEQUENCE "ALFRESCO_OWNER"."'||s.table_name||'_SEQ"';
                EXECUTE IMMEDIATE 'CREATE SEQUENCE  "ALFRESCO_OWNER"."'||s.table_name||'_SEQ"  MINVALUE 1 MAXVALUE 9999999999999999999999999999 INCREMENT BY 1 START WITH '||trnx_maxid||' CACHE 500 ORDER  NOCYCLE  NOKEEP  NOSCALE  GLOBAL';
                EXECUTE IMMEDIATE 'GRANT SELECT ON "ALFRESCO_OWNER"."'||s.table_name||'_SEQ" TO "SAFEDX_OWNER"';
                EXECUTE IMMEDIATE 'GRANT SELECT ON "ALFRESCO_OWNER"."'||s.table_name||'_SEQ" TO "RW_ALFRESCO_ROLE"';
                --DBMS_OUTPUT.PUT_LINE(s.table_name||' sequence has been updated');
                end if;
        end if;
    end loop;
V_END_TIME:=SYSDATE;
SP_MIGRATION_PROCESS_LOG('SEQUENCE_SYNCHRONIZATION', V_START_TIME, V_END_TIME,V_REF_NAME, NULL, NULL,NULL, NULL, NULL, V_REMARKS, NULL) ;
EXCEPTION WHEN OTHERS
THEN V_REMARKS:='Not Processed';
SP_MIGRATION_PROCESS_LOG('SEQUENCE_SYNCHRONIZATION', V_START_TIME, V_END_TIME,V_REF_NAME, NULL, NULL,NULL, SQLCODE, SQLERRM, V_REMARKS, NULL) ;
END SEQUENCE_SYNCHRONIZATION ;
PROCEDURE SP_SYSTEM_DATA_SEGREGATION IS
	V_START_TIME DATE;
	V_END_TIME DATE;
	V_REF_NAME VARCHAR2(100 CHAR);
	V_REF_ID NUMBER(38,0);
	V_REMARKS VARCHAR2(100 CHAR);
BEGIN
	V_START_TIME:=SYSDATE;
    V_REF_NAME:='SYSTEM_DATA_SEGREGATION';
    V_REF_ID:=0;
    V_REMARKS:='Completed successfully';

--step-1_system_masterdata_insert
    SP_INSERT_SYSTEM_MASTERDATA;
--step-2_Alf-Store-data_insert
    SP_INSERT_STORE_DATA;
--step-3_Alf-Store-6-Sub-data-part-1_insert_proc
    SP_INSERT_STORE_SUBDATA_PART1;
--step-4_Alf-Store-6-Sub-data-part-2_insert_proc
    SP_INSERT_STORE_SUBDATA_PART2;
--step-5_system_AuditModel_Feed_Lock_insert_proc
    SP_INSERT_SYSTEM_AUDITMODEL_FEED_LOCK;
V_END_TIME:=SYSDATE;
SP_MIGRATION_PROCESS_LOG('SP_SYSTEM_DATA_SEGREGATION', V_START_TIME, V_END_TIME,V_REF_NAME, NULL, NULL,NULL, NULL, NULL, V_REMARKS, NULL) ;
EXCEPTION WHEN OTHERS
THEN V_REMARKS:='Not Processed';
SP_MIGRATION_PROCESS_LOG('SP_SYSTEM_DATA_SEGREGATION', V_START_TIME, V_END_TIME,V_REF_NAME, NULL, NULL,NULL, SQLCODE, SQLERRM, V_REMARKS, NULL) ;
END SP_SYSTEM_DATA_SEGREGATION;

PROCEDURE SP_INSERT_SYSTEM_MASTERDATA IS
	V_SQL CLOB;
	V_START_TIME DATE;
    V_END_TIME DATE;
    V_REF_NAME VARCHAR2(100 CHAR);
    V_REF_ID NUMBER(38,0);
    V_TABLE_NAME VARCHAR2(100 CHAR);
    V_PRE_DATA_COUNT NUMBER(38,0);
    V_post_DATA_COUNT NUMBER(38,0);
    V_REMARKS VARCHAR2(100 CHAR);
BEGIN
    V_START_TIME:=SYSDATE;
    V_REF_NAME:='SYS_MASTER_DATA';
    V_REF_ID:=0;
    V_REMARKS:='Completed successfully';
    BEGIN
	    begin
		    V_SQL:='Select count(1) from ALF_NAMESPACE'||V_DB_LINK||'';
		    EXECUTE IMMEDIATE V_SQL INTO V_PRE_DATA_COUNT;
		    V_TABLE_NAME:='ALF_NAMESPACE';
            V_SQL:='INSERT into ALF_NAMESPACE Select * from ALF_NAMESPACE'||V_DB_LINK||' order by 1';
            EXECUTE IMMEDIATE V_SQL;
	        V_SQL:='Select count(1) from ALF_NAMESPACE';
	        EXECUTE IMMEDIATE V_SQL INTO V_post_DATA_COUNT;
		    V_END_TIME:=SYSDATE;
            SP_MIGRATION_PROCESS_LOG('INSERT_SYSTEM_MASTERDATA', V_START_TIME, V_END_TIME,V_REF_NAME,V_REF_ID,V_PRE_DATA_COUNT,V_post_DATA_COUNT,null,null,null, V_TABLE_NAME );
        EXCEPTION
	        WHEN OTHERS THEN
                V_REMARKS:='Not Processed';
                SP_MIGRATION_PROCESS_LOG('INSERT_SYSTEM_MASTERDATA', V_START_TIME, V_END_TIME,V_REF_NAME, V_REF_ID, V_PRE_DATA_COUNT,null,SQLCODE, SQLERRM, V_REMARKS,V_TABLE_NAME) ;
        END;

		begin
			V_REMARKS:='Completed successfully';
			V_START_TIME:=V_END_TIME;
		    V_SQL:='Select count(1) from ALF_QNAME'||V_DB_LINK||'';
		    EXECUTE IMMEDIATE V_SQL INTO V_PRE_DATA_COUNT;
		    V_TABLE_NAME:='ALF_QNAME';
            V_SQL:='INSERT into ALF_QNAME Select * from ALF_QNAME'||V_DB_LINK||' order by 1';
            EXECUTE IMMEDIATE V_SQL;
            V_SQL:='Select count(1) from ALF_QNAME';
	        EXECUTE IMMEDIATE V_SQL INTO V_post_DATA_COUNT;
		    V_END_TIME:=SYSDATE;
            SP_MIGRATION_PROCESS_LOG('INSERT_SYSTEM_MASTERDATA', V_START_TIME, V_END_TIME,V_REF_NAME,V_REF_ID,V_PRE_DATA_COUNT,V_post_DATA_COUNT,null,null,null, V_TABLE_NAME );
        EXCEPTION
	        WHEN OTHERS THEN
                V_REMARKS:='Not Processed';
                SP_MIGRATION_PROCESS_LOG('INSERT_SYSTEM_MASTERDATA', V_START_TIME, V_END_TIME,V_REF_NAME, V_REF_ID, V_PRE_DATA_COUNT,null,SQLCODE, SQLERRM, V_REMARKS,V_TABLE_NAME) ;
        END;

	    begin
			V_REMARKS:='Completed successfully';
			V_START_TIME:=V_END_TIME;
	        V_SQL:='Select count(1) from ALF_PROP_CLASS'||V_DB_LINK||'';
		    EXECUTE IMMEDIATE V_SQL INTO V_PRE_DATA_COUNT;
		    V_TABLE_NAME:='ALF_PROP_CLASS';
            V_SQL:='INSERT into ALF_PROP_CLASS Select * from ALF_PROP_CLASS'||V_DB_LINK||' order by 1';
            EXECUTE IMMEDIATE V_SQL;
	        V_SQL:='Select count(1) from ALF_PROP_CLASS';
	        EXECUTE IMMEDIATE V_SQL INTO V_post_DATA_COUNT;
		    V_END_TIME:=SYSDATE;
            SP_MIGRATION_PROCESS_LOG('INSERT_SYSTEM_MASTERDATA', V_START_TIME, V_END_TIME,V_REF_NAME,V_REF_ID,V_PRE_DATA_COUNT,V_post_DATA_COUNT,null,null,null, V_TABLE_NAME );
        EXCEPTION
	        WHEN OTHERS THEN
                V_REMARKS:='Not Processed';
                SP_MIGRATION_PROCESS_LOG('INSERT_SYSTEM_MASTERDATA', V_START_TIME, V_END_TIME,V_REF_NAME, V_REF_ID, V_PRE_DATA_COUNT,null,SQLCODE, SQLERRM, V_REMARKS,V_TABLE_NAME) ;
        END;

		begin
			V_REMARKS:='Completed successfully';
			V_START_TIME:=V_END_TIME;
	        V_SQL:='Select count(1) from ALF_PERMISSION'||V_DB_LINK||'';
		    EXECUTE IMMEDIATE V_SQL INTO V_PRE_DATA_COUNT;
		    V_TABLE_NAME:='ALF_PERMISSION';
            V_SQL:='INSERT into ALF_PERMISSION Select * from ALF_PERMISSION'||V_DB_LINK||' order by 1';
            EXECUTE IMMEDIATE V_SQL;
	        V_SQL:='Select count(1) from ALF_PERMISSION';
	        EXECUTE IMMEDIATE V_SQL INTO V_post_DATA_COUNT;
		    V_END_TIME:=SYSDATE;
            SP_MIGRATION_PROCESS_LOG('INSERT_SYSTEM_MASTERDATA', V_START_TIME, V_END_TIME,V_REF_NAME,V_REF_ID,V_PRE_DATA_COUNT,V_post_DATA_COUNT,null,null,null, V_TABLE_NAME );
        EXCEPTION
	        WHEN OTHERS THEN
                V_REMARKS:='Not Processed';
                SP_MIGRATION_PROCESS_LOG('INSERT_SYSTEM_MASTERDATA', V_START_TIME, V_END_TIME,V_REF_NAME, V_REF_ID, V_PRE_DATA_COUNT,null,SQLCODE, SQLERRM, V_REMARKS,V_TABLE_NAME) ;
        END;

	    begin
			V_REMARKS:='Completed successfully';
			V_START_TIME:=V_END_TIME;
	        V_SQL:='Select count(1) from ALF_MIMETYPE'||V_DB_LINK||'';
		    EXECUTE IMMEDIATE V_SQL INTO V_PRE_DATA_COUNT;
		    V_TABLE_NAME:='ALF_MIMETYPE';
            V_SQL:='INSERT into ALF_MIMETYPE Select * from ALF_MIMETYPE'||V_DB_LINK||' order by 1';
            EXECUTE IMMEDIATE V_SQL;
	        V_SQL:='Select count(1) from ALF_MIMETYPE';
	        EXECUTE IMMEDIATE V_SQL INTO V_post_DATA_COUNT;
		    V_END_TIME:=SYSDATE;
            SP_MIGRATION_PROCESS_LOG('INSERT_SYSTEM_MASTERDATA', V_START_TIME, V_END_TIME,V_REF_NAME,V_REF_ID,V_PRE_DATA_COUNT,V_post_DATA_COUNT,null,null,null, V_TABLE_NAME );
        EXCEPTION
	        WHEN OTHERS THEN
                V_REMARKS:='Not Processed';
                SP_MIGRATION_PROCESS_LOG('INSERT_SYSTEM_MASTERDATA', V_START_TIME, V_END_TIME,V_REF_NAME, V_REF_ID, V_PRE_DATA_COUNT,null,SQLCODE, SQLERRM, V_REMARKS,V_TABLE_NAME) ;
        END;

	     begin
			V_REMARKS:='Completed successfully';
			V_START_TIME:=V_END_TIME;
	        V_SQL:='Select count(1) from ALF_LOCALE'||V_DB_LINK||'';
		    EXECUTE IMMEDIATE V_SQL INTO V_PRE_DATA_COUNT;
		    V_TABLE_NAME:='ALF_LOCALE';
            V_SQL:='INSERT into ALF_LOCALE Select * from ALF_LOCALE'||V_DB_LINK||' order by 1';
            EXECUTE IMMEDIATE V_SQL;
	        V_SQL:='Select count(1) from ALF_LOCALE';
	        EXECUTE IMMEDIATE V_SQL INTO V_post_DATA_COUNT;
		    V_END_TIME:=SYSDATE;
            SP_MIGRATION_PROCESS_LOG('INSERT_SYSTEM_MASTERDATA', V_START_TIME, V_END_TIME,V_REF_NAME,V_REF_ID,V_PRE_DATA_COUNT,V_post_DATA_COUNT,null,null,null, V_TABLE_NAME );
        EXCEPTION
	        WHEN OTHERS THEN
                V_REMARKS:='Not Processed';
                SP_MIGRATION_PROCESS_LOG('INSERT_SYSTEM_MASTERDATA', V_START_TIME, V_END_TIME,V_REF_NAME, V_REF_ID, V_PRE_DATA_COUNT,null,SQLCODE, SQLERRM, V_REMARKS,V_TABLE_NAME) ;
        END;

	    begin
			V_REMARKS:='Completed successfully';
			V_START_TIME:=V_END_TIME;
	        V_SQL:='Select count(1) from ALF_ENCODING'||V_DB_LINK||'';
		    EXECUTE IMMEDIATE V_SQL INTO V_PRE_DATA_COUNT;
		    V_TABLE_NAME:='ALF_ENCODING';
            V_SQL:='INSERT into ALF_ENCODING Select * from ALF_ENCODING'||V_DB_LINK||' order by 1';
            EXECUTE IMMEDIATE V_SQL;
	        V_SQL:='Select count(1) from ALF_ENCODING';
	        EXECUTE IMMEDIATE V_SQL INTO V_post_DATA_COUNT;
		    V_END_TIME:=SYSDATE;
            SP_MIGRATION_PROCESS_LOG('INSERT_SYSTEM_MASTERDATA', V_START_TIME, V_END_TIME,V_REF_NAME,V_REF_ID,V_PRE_DATA_COUNT,V_post_DATA_COUNT,null,null,null, V_TABLE_NAME );
        EXCEPTION
	        WHEN OTHERS THEN
                V_REMARKS:='Not Processed';
                SP_MIGRATION_PROCESS_LOG('INSERT_SYSTEM_MASTERDATA', V_START_TIME, V_END_TIME,V_REF_NAME, V_REF_ID, V_PRE_DATA_COUNT,null,SQLCODE, SQLERRM, V_REMARKS,V_TABLE_NAME) ;
        END;
--INSERT into ACT_RE_DEPLOYMENT Select * from ACT_RE_DEPLOYMENT@conn_stdb order by 1;

	    begin
			V_REMARKS:='Completed successfully';
			V_START_TIME:=V_END_TIME;
	        V_SQL:='Select count(1) from ACT_GE_PROPERTY'||V_DB_LINK||'';
		    EXECUTE IMMEDIATE V_SQL INTO V_PRE_DATA_COUNT;
		    V_TABLE_NAME:='ACT_GE_PROPERTY';
            V_SQL:='INSERT into ACT_GE_PROPERTY Select * from ACT_GE_PROPERTY'||V_DB_LINK||' order by 1';
            EXECUTE IMMEDIATE V_SQL;
	        V_SQL:='Select count(1) from ACT_GE_PROPERTY';
	        EXECUTE IMMEDIATE V_SQL INTO V_post_DATA_COUNT;
		    V_END_TIME:=SYSDATE;
            SP_MIGRATION_PROCESS_LOG('INSERT_SYSTEM_MASTERDATA', V_START_TIME, V_END_TIME,V_REF_NAME,V_REF_ID,V_PRE_DATA_COUNT,V_post_DATA_COUNT,null,null,null, V_TABLE_NAME );
        EXCEPTION
	        WHEN OTHERS THEN
                V_REMARKS:='Not Processed';
                SP_MIGRATION_PROCESS_LOG('INSERT_SYSTEM_MASTERDATA', V_START_TIME, V_END_TIME,V_REF_NAME, V_REF_ID, V_PRE_DATA_COUNT,null,SQLCODE, SQLERRM, V_REMARKS,V_TABLE_NAME) ;
        END;


----ALF_SERVER table not present in source DB
--	    begin
--			V_REMARKS:='Completed successfully';
--			V_START_TIME:=V_END_TIME;
--	        V_SQL:='Select count(1) from ALF_SERVER'||V_DB_LINK||'';
--		    EXECUTE IMMEDIATE V_SQL INTO V_PRE_DATA_COUNT;
--		    V_TABLE_NAME:='ALF_SERVER';
--            V_SQL:='INSERT into ALF_SERVER Select * from ALF_SERVER'||V_DB_LINK||' order by 1';
--            EXECUTE IMMEDIATE V_SQL;
--	        V_SQL:='Select count(1) from ALF_SERVER';
--	        EXECUTE IMMEDIATE V_SQL INTO V_post_DATA_COUNT;
--		    V_END_TIME:=SYSDATE;
--            SP_MIGRATION_PROCESS_LOG('INSERT_SYSTEM_MASTERDATA', V_START_TIME, V_END_TIME,V_REF_NAME,V_REF_ID,V_PRE_DATA_COUNT,V_post_DATA_COUNT,null,null,null, V_TABLE_NAME );
--        EXCEPTION
--	        WHEN OTHERS THEN
--                V_REMARKS:='Not Processed';
--                SP_MIGRATION_PROCESS_LOG('INSERT_SYSTEM_MASTERDATA', V_START_TIME, V_END_TIME,V_REF_NAME, V_REF_ID, V_PRE_DATA_COUNT,null,SQLCODE, SQLERRM, V_REMARKS,V_TABLE_NAME) ;
--        END;

	    begin
			V_REMARKS:='Completed successfully';
			V_START_TIME:=V_END_TIME;
	        V_SQL:='Select count(1) from ALF_APPLIED_PATCH'||V_DB_LINK||'';
		    EXECUTE IMMEDIATE V_SQL INTO V_PRE_DATA_COUNT;
		    V_TABLE_NAME:='ALF_APPLIED_PATCH';
            V_SQL:='INSERT into ALF_APPLIED_PATCH Select * from ALF_APPLIED_PATCH'||V_DB_LINK||' order by 1';
            EXECUTE IMMEDIATE V_SQL;
	        V_SQL:='Select count(1) from ALF_APPLIED_PATCH';
	        EXECUTE IMMEDIATE V_SQL INTO V_post_DATA_COUNT;
		    V_END_TIME:=SYSDATE;
            SP_MIGRATION_PROCESS_LOG('INSERT_SYSTEM_MASTERDATA', V_START_TIME, V_END_TIME,V_REF_NAME,V_REF_ID,V_PRE_DATA_COUNT,V_post_DATA_COUNT,null,null,null, V_TABLE_NAME );
        EXCEPTION
	        WHEN OTHERS THEN
                V_REMARKS:='Not Processed';
                SP_MIGRATION_PROCESS_LOG('INSERT_SYSTEM_MASTERDATA', V_START_TIME, V_END_TIME,V_REF_NAME, V_REF_ID, V_PRE_DATA_COUNT,null,SQLCODE, SQLERRM, V_REMARKS,V_TABLE_NAME) ;
        END;


    EXECUTE IMMEDIATE 'ALTER TABLE ALF_STORE DISABLE CONSTRAINT FK_ALF_STORE_ROOT';

         begin
			V_REMARKS:='Completed successfully';
			V_START_TIME:=V_END_TIME;
	        V_SQL:='Select count(1) from ALF_STORE'||V_DB_LINK||'';
		    EXECUTE IMMEDIATE V_SQL INTO V_PRE_DATA_COUNT;
		    V_TABLE_NAME:='ALF_STORE';
            V_SQL:='INSERT into ALF_STORE Select * from ALF_STORE'||V_DB_LINK||' order by 1'; -- root node
            EXECUTE IMMEDIATE V_SQL;
	        V_SQL:='Select count(1) from ALF_STORE';
	        EXECUTE IMMEDIATE V_SQL INTO V_post_DATA_COUNT;
		    V_END_TIME:=SYSDATE;
            SP_MIGRATION_PROCESS_LOG('INSERT_SYSTEM_MASTERDATA', V_START_TIME, V_END_TIME,V_REF_NAME,V_REF_ID,V_PRE_DATA_COUNT,V_post_DATA_COUNT,null,null,null, V_TABLE_NAME );
        EXCEPTION
	        WHEN OTHERS THEN
                V_REMARKS:='Not Processed';
                SP_MIGRATION_PROCESS_LOG('INSERT_SYSTEM_MASTERDATA', V_START_TIME, V_END_TIME,V_REF_NAME, V_REF_ID, V_PRE_DATA_COUNT,null,SQLCODE, SQLERRM, V_REMARKS,V_TABLE_NAME) ;
        END;

    commit;
    begin
        for i in (Select * from ALF_STORE order by 1) loop
            INSERT_NODE(i.ROOT_NODE_ID,0,'store_root_node','false');
        end loop;
    end;

    EXECUTE IMMEDIATE 'ALTER TABLE ALF_STORE ENABLE CONSTRAINT FK_ALF_STORE_ROOT';
    commit;
    end;
	V_END_TIME:=SYSDATE;
	SP_MIGRATION_PROCESS_LOG('INSERT_SYSTEM_MASTERDATA', V_START_TIME, V_END_TIME,V_REF_NAME, NULL, NULL,NULL, NULL, NULL, V_REMARKS, NULL) ;
EXCEPTION WHEN OTHERS
THEN V_REMARKS:='Not Processed';
SP_MIGRATION_PROCESS_LOG('INSERT_SYSTEM_MASTERDATA', V_START_TIME, V_END_TIME,V_REF_NAME, null, null,null,SQLCODE, SQLERRM, V_REMARKS,V_TABLE_NAME) ;
END SP_INSERT_SYSTEM_MASTERDATA;


PROCEDURE SP_INSERT_STORE_DATA IS
    t_num NUMBER :=0;
    n number(10);
    Childcascade VARCHAR2(100) :='false'; --Change this to true if child cascade required
    type t_parent_id is table of alf_child_assoc.parent_node_id%type;
    type t_child_id is table of alf_child_assoc.child_node_id%type;
    v_parent_node_id t_parent_id;
    v_child_node_id t_child_id;
    V_SQL CLOB;
	V_START_TIME DATE;
    V_END_TIME DATE;
    V_REF_NAME VARCHAR2(100 CHAR);
    V_REF_ID NUMBER(38,0);
    V_TABLE_NAME VARCHAR2(100 CHAR);
    V_PRE_DATA_COUNT NUMBER(38,0);
    V_post_DATA_COUNT NUMBER(38,0);
    V_REMARKS VARCHAR2(100 CHAR);
BEGIN
    V_START_TIME:=SYSDATE;
    V_REF_NAME:='INSERT_STORE_DATA';
    V_REF_ID:=0;
    V_REMARKS:='Completed successfully';

    V_SQL:='Select parent_node_id,child_node_id from (Select LEVEL,ch.* from alf_child_assoc'||V_DB_LINK||' ch  START WITH  ch.parent_node_id in (Select root_node_id from alf_store'||V_DB_LINK||' where protocol=''user'' and IDENTIFIER=''alfrescoUserStore'')
    CONNECT BY PRIOR  ch.child_node_id = ch.parent_node_id -- and level < 4
    and ch.QNAME_LOCALNAME in (''system'',''people'',''admin'',''abeecher'',''mjackson'',''API_User'',''arender'')
    ORDER BY 1,parent_node_id,child_node_id asc) t
    UNION ALL
    Select parent_node_id,child_node_id  from (Select LEVEL,ch.* from alf_child_assoc'||V_DB_LINK||' ch  START WITH  ch.parent_node_id in (Select root_node_id from alf_store'||V_DB_LINK||' where protocol=''system'' and IDENTIFIER=''system'')
    CONNECT BY PRIOR  ch.child_node_id = ch.parent_node_id
    ORDER BY 1,parent_node_id,child_node_id asc)
    UNION ALL
    Select parent_node_id,child_node_id  from (Select LEVEL,ch.* from alf_child_assoc'||V_DB_LINK||' ch  START WITH  ch.parent_node_id in (Select root_node_id from alf_store'||V_DB_LINK||' where protocol=''workspace'' and IDENTIFIER=''lightWeightVersionStore'')
    CONNECT BY PRIOR  ch.child_node_id = ch.parent_node_id
    ORDER BY 1,parent_node_id,child_node_id asc)
    UNION ALL
    Select parent_node_id,child_node_id  from (Select LEVEL,ch.* from alf_child_assoc'||V_DB_LINK||' ch  START WITH  ch.parent_node_id in (Select root_node_id from alf_store'||V_DB_LINK||' where protocol=''archive'' and IDENTIFIER=''SpacesStore'')
    CONNECT BY PRIOR  ch.child_node_id = ch.parent_node_id  and level<2
    ORDER BY 1,parent_node_id,child_node_id asc) t where  t.QNAME_LOCALNAME in (''admin'')
    UNION ALL
    Select parent_node_id,child_node_id  from (Select LEVEL,ch.* from alf_child_assoc'||V_DB_LINK||' ch  START WITH  ch.parent_node_id in (Select root_node_id from alf_store'||V_DB_LINK||' where protocol=''workspace'' and IDENTIFIER=''SpacesStore'')
    CONNECT BY PRIOR  ch.child_node_id = ch.parent_node_id
    and ch.parent_node_id not in (Select t.CHILD_NODE_ID from (Select ch.* from alf_child_assoc'||V_DB_LINK||' ch  START WITH  ch.parent_node_id in (Select root_node_id from alf_store'||V_DB_LINK||' where protocol=''workspace'' and IDENTIFIER=''SpacesStore'')
    CONNECT BY PRIOR  ch.child_node_id = ch.parent_node_id and level>2) t where t.qname_localname in (''company_home'',''system'')) -- Skip child for company_home,system
    ORDER BY 1,parent_node_id,child_node_id asc) t';

    EXECUTE IMMEDIATE V_SQL BULK COLLECT INTO v_parent_node_id,v_child_node_id;

    begin
        for i in 1..v_child_node_id.COUNT loop
            --t_num :=t_num+1;
            INSERT_NODE(v_child_node_id(i),v_parent_node_id(i),'child',Childcascade);
            --if MOD(t_num,100)=0 then COMMIT; end if;
        end loop;
        commit;
--        dbms_output.put_line('Processing Completed for system And committed record count for c1: '||t_num );
    end;
EXCEPTION WHEN OTHERS
THEN
	V_END_TIME:=SYSDATE;
	V_REMARKS:='Not Processed';
 SP_MIGRATION_PROCESS_LOG('SP_INSERT_STORE_DATA', V_START_TIME, V_END_TIME,V_REF_NAME, null, null,null,SQLCODE, SQLERRM, V_REMARKS,V_TABLE_NAME) ;
END SP_INSERT_STORE_DATA;

PROCEDURE SP_INSERT_STORE_SUBDATA_PART1 IS
V_START_TIME DATE;
V_END_TIME DATE;
V_REMARKS VARCHAR2(100 CHAR);
BEGIN
    V_REMARKS:='Completed successfully';
	V_START_TIME:=SYSDATE;
    SP_INSERT_SUBDATA_PART1;
    SP_INSERT_SUBDATA_PART2;
    SP_INSERT_SUBDATA_PART3;
    SP_INSERT_SUBDATA_PART4;
    SP_INSERT_SUBDATA_PART5;
    SP_INSERT_SUBDATA_PART6;
    SP_INSERT_SUBDATA_PART7;
    SP_INSERT_SUBDATA_PART8;
    SP_INSERT_SUBDATA_PART9;
    SP_INSERT_SUBDATA_PART10;
	V_END_TIME:=SYSDATE;
	SP_MIGRATION_PROCESS_LOG('SP_INSERT_STORE_SUBDATA_PART1', V_START_TIME, V_END_TIME,NULL, NULL, NULL,NULL, NULL, NULL, V_REMARKS, NULL) ;
EXCEPTION WHEN OTHERS
THEN V_REMARKS:='Not Processed';
SP_MIGRATION_PROCESS_LOG('SP_INSERT_STORE_SUBDATA_PART1', V_START_TIME, V_END_TIME,NULL, null, null,null,SQLCODE, SQLERRM, V_REMARKS,NULL) ;
END SP_INSERT_STORE_SUBDATA_PART1;

PROCEDURE SP_INSERT_SUBDATA_PART1 IS
   t_num NUMBER :=0;
    Childcascade VARCHAR2(100) :='false'; --Change this to true if child cascade required
    type t_parent_id is table of alf_child_assoc.parent_node_id%type;
    type t_child_id is table of alf_child_assoc.child_node_id%type;
    v_parent_node_id t_parent_id;
    v_child_node_id t_child_id;
    V_SQL CLOB;
	V_START_TIME DATE;
	V_END_TIME DATE;
	V_REMARKS VARCHAR2(100 CHAR);

BEGIN
	V_START_TIME:=SYSDATE;
	V_REMARKS:='Completed successfully';
    V_SQL:='Select parent_node_id,child_node_id from (Select LEVEL,SYS_CONNECT_BY_PATH(ch.qname_localname, ''/'') "Path",ch.* from alf_child_assoc'||V_DB_LINK||' ch  START WITH  ch.parent_node_id in
(Select t.CHILD_NODE_ID from (Select LEVEL,SYS_CONNECT_BY_PATH(ch.qname_localname, ''/'') "Path",ch.* from alf_child_assoc'||V_DB_LINK||' ch START WITH ch.parent_node_id in (Select root_node_id from alf_store'||V_DB_LINK||' where protocol=''workspace'' and IDENTIFIER=''SpacesStore'')
CONNECT By PRIOR  ch.child_node_id = ch.parent_node_id AND LEVEL <= 1) t where t."Path" in (''/company_home''))
CONNECT BY PRIOR  ch.child_node_id = ch.parent_node_id
and ch.parent_node_id not in (Select t.CHILD_NODE_ID from (Select LEVEL,SYS_CONNECT_BY_PATH(ch.qname_localname, ''/'') "Path",ch.* from alf_child_assoc'||V_DB_LINK||' ch START WITH ch.parent_node_id in (Select root_node_id from alf_store'||V_DB_LINK||' where protocol=''workspace'' and IDENTIFIER=''SpacesStore'')
CONNECT By PRIOR  ch.child_node_id = ch.parent_node_id AND LEVEL <= 2) t
where t."Path" in (''/company_home/SafeDx'',''/company_home/sites'',''/company_home/user_homes'')) -- Skip child for user_homes,sites,SafeDx
ORDER BY 1,parent_node_id,child_node_id asc) t';

    EXECUTE IMMEDIATE V_SQL BULK COLLECT INTO v_parent_node_id,v_child_node_id;

    begin
        for i in 1..v_child_node_id.COUNT loop
            ----t_num :=t_num+1;
            INSERT_NODE(v_child_node_id(i),v_parent_node_id(i),'child',Childcascade);
            ----if MOD(t_num,100)=0 then COMMIT; end if;
        end loop;
        commit;
--    dbms_output.put_line('Processing Completed for system And committed record count for c1: '||t_num );
    end;

	V_END_TIME:=SYSDATE;
	SP_MIGRATION_PROCESS_LOG('SP_INSERT_SUBDATA_PART1', V_START_TIME, V_END_TIME,NULL, NULL, NULL,NULL, NULL, NULL, V_REMARKS, NULL) ;
EXCEPTION WHEN OTHERS
THEN V_REMARKS:='Not Processed';
SP_MIGRATION_PROCESS_LOG('SP_INSERT_SUBDATA_PART1', V_START_TIME, V_END_TIME,NULL, null, null,null,SQLCODE, SQLERRM, V_REMARKS,NULL) ;
END SP_INSERT_SUBDATA_PART1;
PROCEDURE SP_INSERT_SUBDATA_PART2 IS
    t_num NUMBER :=0;
    Childcascade VARCHAR2(100) :='false'; --Change this to true if child cascade required
    type t_parent_id is table of alf_child_assoc.parent_node_id%type;
    type t_child_id is table of alf_child_assoc.child_node_id%type;
    v_parent_node_id t_parent_id;
    v_child_node_id t_child_id;
    V_SQL CLOB;
	V_START_TIME DATE;
	V_END_TIME DATE;
	V_REMARKS VARCHAR2(100 CHAR);

BEGIN
	V_START_TIME:=SYSDATE;
	V_REMARKS:='Completed successfully';
	V_SQL:='Select parent_node_id,child_node_id from (Select LEVEL,SYS_CONNECT_BY_PATH(ch.qname_localname, ''/'') "Path",ch.* from alf_child_assoc'||V_DB_LINK||' ch  START WITH  ch.parent_node_id in (Select t.CHILD_NODE_ID from (Select LEVEL,SYS_CONNECT_BY_PATH(ch.qname_localname, ''/'') "Path",ch.* from alf_child_assoc'||V_DB_LINK||' ch START WITH ch.parent_node_id in (Select root_node_id from alf_store'||V_DB_LINK||' where protocol=''workspace'' and IDENTIFIER=''SpacesStore'')
CONNECT By PRIOR  ch.child_node_id = ch.parent_node_id AND LEVEL <= 2) t where t."Path" in (''/company_home/user_homes''))
CONNECT BY PRIOR  ch.child_node_id = ch.parent_node_id
ORDER BY 1,parent_node_id,child_node_id asc) t
where t.child_node_id in (Select p.node_id from alf_node_properties p
join alf_qname'||V_DB_LINK||' q on p.qname_id=q.id
where p.STRING_VALUE in (''admin'',''guest'',''abeecher'',''mjackson'',''API_User'',''arender'')
and p.qname_id in (Select id from alf_qname'||V_DB_LINK||' where LOCAL_NAME=''name''))';

    EXECUTE IMMEDIATE V_SQL BULK COLLECT INTO v_parent_node_id,v_child_node_id;
    begin
        for i in 1..v_child_node_id.COUNT loop
         --   --t_num :=t_num+1;
            INSERT_NODE(v_child_node_id(i),v_parent_node_id(i),'child',Childcascade);
         --   --if MOD(t_num,100)=0 then COMMIT; end if;
        end loop;
        commit;
--    dbms_output.put_line('Processing Completed for system And committed record count for c2: '||t_num );
    end;

	V_END_TIME:=SYSDATE;
	SP_MIGRATION_PROCESS_LOG('SP_INSERT_SUBDATA_PART2', V_START_TIME, V_END_TIME,NULL, NULL, NULL,NULL, NULL, NULL, V_REMARKS, NULL) ;
EXCEPTION WHEN OTHERS
THEN V_REMARKS:='Not Processed';
SP_MIGRATION_PROCESS_LOG('SP_INSERT_SUBDATA_PART2', V_START_TIME, V_END_TIME,NULL, null, null,null,SQLCODE, SQLERRM, V_REMARKS,NULL) ;
END SP_INSERT_SUBDATA_PART2;
PROCEDURE SP_INSERT_SUBDATA_PART3 IS
    t_num NUMBER :=0;
    Childcascade VARCHAR2(100) :='false'; --Change this to true if child cascade required
    type t_parent_id is table of alf_child_assoc.parent_node_id%type;
    type t_child_id is table of alf_child_assoc.child_node_id%type;
    v_parent_node_id t_parent_id;
    v_child_node_id t_child_id;
    V_SQL CLOB;
	V_START_TIME DATE;
	V_END_TIME DATE;
	V_REMARKS VARCHAR2(100 CHAR);
BEGIN
V_START_TIME:=SYSDATE;
V_REMARKS:='Completed successfully';
V_SQL:='Select parent_node_id,child_node_id from (Select LEVEL,SYS_CONNECT_BY_PATH(ch.qname_localname, ''/'') "Path",ch.* from alf_child_assoc'||V_DB_LINK||' ch  START WITH  ch.parent_node_id in (Select t.CHILD_NODE_ID from (Select LEVEL,SYS_CONNECT_BY_PATH(ch.qname_localname, ''/'') "Path",ch.* from alf_child_assoc'||V_DB_LINK||' ch START WITH ch.parent_node_id in (Select root_node_id from alf_store'||V_DB_LINK||' where protocol=''workspace'' and IDENTIFIER=''SpacesStore'')
CONNECT By PRIOR  ch.child_node_id = ch.parent_node_id AND LEVEL <= 2) t where t."Path" in (''/company_home/SafeDx''))
CONNECT BY PRIOR  ch.child_node_id = ch.parent_node_id
and ch.parent_node_id not in (Select id from tmp_alf_ids'||V_DB_LINK||' where protocol=''workspace'' and IDENTIFIER=''SpacesStore'' and path=''/company_home/SafeDx/Sponsors'') -- Skip child for Sponsors
ORDER BY 1,parent_node_id,child_node_id asc) t';
    EXECUTE IMMEDIATE V_SQL BULK COLLECT INTO v_parent_node_id,v_child_node_id;
    begin
        for i in 1..v_child_node_id.COUNT loop
            --t_num :=t_num+1;
            INSERT_NODE(v_child_node_id(i),v_parent_node_id(i),'child',Childcascade);
        --if MOD(t_num,100)=0 then COMMIT; end if;
        end loop;
    COMMIT;
    --dbms_output.put_line('Processing Completed for system And committed record count for c3: '||t_num );
    end;

	V_END_TIME:=SYSDATE;
	SP_MIGRATION_PROCESS_LOG('SP_INSERT_SUBDATA_PART3', V_START_TIME, V_END_TIME,NULL, NULL, NULL,NULL, NULL, NULL, V_REMARKS, NULL) ;
EXCEPTION WHEN OTHERS
THEN V_REMARKS:='Not Processed';
SP_MIGRATION_PROCESS_LOG('SP_INSERT_SUBDATA_PART3', V_START_TIME, V_END_TIME,NULL, null, null,null,SQLCODE, SQLERRM, V_REMARKS,NULL) ;
END SP_INSERT_SUBDATA_PART3;
PROCEDURE SP_INSERT_SUBDATA_PART4 IS
    t_num NUMBER :=0;
    Childcascade VARCHAR2(100) :='false'; --Change this to true if child cascade required
    type t_parent_id is table of alf_child_assoc.parent_node_id%type;
    type t_child_id is table of alf_child_assoc.child_node_id%type;
    v_parent_node_id t_parent_id;
    v_child_node_id t_child_id;
    V_SQL CLOB;
	V_START_TIME DATE;
	V_END_TIME DATE;
	V_REMARKS VARCHAR2(100 CHAR);
BEGIN
V_START_TIME:=SYSDATE;
V_REMARKS:='Completed successfully';
    V_SQL:=' Select parent_node_id,child_node_id from (Select LEVEL,SYS_CONNECT_BY_PATH(ch.qname_localname, ''/'') "Path",ch.* from alf_child_assoc'||V_DB_LINK||' ch  START WITH  ch.parent_node_id in (Select t.CHILD_NODE_ID from (Select LEVEL,SYS_CONNECT_BY_PATH(ch.qname_localname, ''/'') "Path",ch.* from alf_child_assoc'||V_DB_LINK||' ch  START WITH  ch.parent_node_id in
(Select root_node_id from alf_store'||V_DB_LINK||' where protocol=''workspace'' and IDENTIFIER=''SpacesStore'') CONNECT BY PRIOR  ch.child_node_id = ch.parent_node_id and level<=1) t
where t."Path" in (''/system'')) CONNECT BY PRIOR  ch.child_node_id = ch.parent_node_id
and ch.parent_node_id not in (Select t.CHILD_NODE_ID from (Select LEVEL,SYS_CONNECT_BY_PATH(ch.qname_localname, ''/'') "Path",ch.* from alf_child_assoc'||V_DB_LINK||' ch START WITH ch.parent_node_id in
(Select root_node_id from alf_store'||V_DB_LINK||' where protocol=''workspace'' and IDENTIFIER=''SpacesStore'') CONNECT By PRIOR  ch.child_node_id = ch.parent_node_id AND LEVEL <= 2) t
where t."Path" in (''/system/people'',''/system/workflow'',''/system/authorities'',''/system/zones'')) -- Skip child for people,workflow,authorities,zones
ORDER BY 1,parent_node_id,child_node_id asc) t';
    EXECUTE IMMEDIATE V_SQL BULK COLLECT INTO v_parent_node_id,v_child_node_id;
    begin
        for i in 1..v_child_node_id.COUNT loop
            --t_num :=t_num+1;
            INSERT_NODE(v_child_node_id(i),v_parent_node_id(i),'child',Childcascade);
        --if MOD(t_num,100)=0 then COMMIT; end if;
        end loop;
    COMMIT;
--    dbms_output.put_line('Processing Completed for system And committed record count for c4: '||t_num );
    end;

	V_END_TIME:=SYSDATE;
	SP_MIGRATION_PROCESS_LOG('SP_INSERT_SUBDATA_PART4', V_START_TIME, V_END_TIME,NULL, NULL, NULL,NULL, NULL, NULL, V_REMARKS, NULL) ;
EXCEPTION WHEN OTHERS
THEN V_REMARKS:='Not Processed';
SP_MIGRATION_PROCESS_LOG('SP_INSERT_SUBDATA_PART4', V_START_TIME, V_END_TIME,NULL, null, null,null,SQLCODE, SQLERRM, V_REMARKS,NULL) ;
END SP_INSERT_SUBDATA_PART4;
PROCEDURE SP_INSERT_SUBDATA_PART5 IS
    t_num NUMBER :=0;
    Childcascade VARCHAR2(100) :='false'; --Change this to true if child cascade required
    type t_parent_id is table of alf_child_assoc.parent_node_id%type;
    type t_child_id is table of alf_child_assoc.child_node_id%type;
    v_parent_node_id t_parent_id;
    v_child_node_id t_child_id;
    V_SQL CLOB;
	V_START_TIME DATE;
	V_END_TIME DATE;
	V_REMARKS VARCHAR2(100 CHAR);
BEGIN
V_START_TIME:=SYSDATE;
V_REMARKS:='Completed successfully';
    V_SQL:='Select parent_node_id,child_node_id from (Select LEVEL,SYS_CONNECT_BY_PATH(ch.qname_localname, ''/'') "Path",ch.* from alf_child_assoc'||V_DB_LINK||' ch  START WITH  ch.parent_node_id in (
Select t.CHILD_NODE_ID from (Select LEVEL,SYS_CONNECT_BY_PATH(ch.qname_localname, ''/'') "Path",ch.* from alf_child_assoc'||V_DB_LINK||' ch START WITH ch.parent_node_id in
(Select root_node_id from alf_store'||V_DB_LINK||' where protocol=''workspace'' and IDENTIFIER=''SpacesStore'') CONNECT By PRIOR  ch.child_node_id = ch.parent_node_id AND LEVEL <= 2) t where t."Path" in (''/system/people'')
)CONNECT BY PRIOR  ch.child_node_id = ch.parent_node_id
ORDER BY 1,parent_node_id,child_node_id asc) t where t.child_node_id in (
Select p.node_id from alf_node_properties p join alf_qname'||V_DB_LINK||' q on p.qname_id=q.id
where p.STRING_VALUE in (''admin'',''guest'',''abeecher'',''mjackson'',''API_User'')
and p.qname_id in (Select id from alf_qname'||V_DB_LINK||' where LOCAL_NAME in (''userName'',''username'')))';
    EXECUTE IMMEDIATE V_SQL BULK COLLECT INTO v_parent_node_id,v_child_node_id;
    begin
        for i in 1..v_child_node_id.COUNT loop
            --t_num :=t_num+1;
            INSERT_NODE(v_child_node_id(i),v_parent_node_id(i),'child',Childcascade);
        --if MOD(t_num,100)=0 then COMMIT; end if;
        end loop;
    COMMIT;
    --dbms_output.put_line('Processing Completed for system And committed record count for c5: '||t_num );
    end;

	V_END_TIME:=SYSDATE;
		SP_MIGRATION_PROCESS_LOG('SP_INSERT_SUBDATA_PART5', V_START_TIME, V_END_TIME,NULL, NULL, NULL,NULL, NULL, NULL, V_REMARKS, NULL) ;

EXCEPTION WHEN OTHERS
THEN V_REMARKS:='Not Processed';
SP_MIGRATION_PROCESS_LOG('SP_INSERT_SUBDATA_PART5', V_START_TIME, V_END_TIME,NULL, null, null,null,SQLCODE, SQLERRM, V_REMARKS,NULL) ;
END SP_INSERT_SUBDATA_PART5;
PROCEDURE SP_INSERT_SUBDATA_PART6 IS
    t_num NUMBER :=0;
    Childcascade VARCHAR2(100) :='false'; --Change this to true if child cascade required
    type t_parent_id is table of alf_child_assoc.parent_node_id%type;
    type t_child_id is table of alf_child_assoc.child_node_id%type;
    v_parent_node_id t_parent_id;
    v_child_node_id t_child_id;
    V_SQL CLOB;
	V_START_TIME DATE;
	V_END_TIME DATE;
	V_REMARKS VARCHAR2(100 CHAR);
BEGIN
	V_START_TIME:=SYSDATE;
	V_REMARKS:='Completed successfully';
    V_SQL:='Select parent_node_id,child_node_id from (Select LEVEL,SYS_CONNECT_BY_PATH(ch.qname_localname, ''/'') "Path",ch.* from alf_child_assoc'||V_DB_LINK||' ch START WITH ch.parent_node_id in
(Select root_node_id from alf_store'||V_DB_LINK||' where protocol=''workspace'' and IDENTIFIER=''SpacesStore'')
CONNECT By PRIOR  ch.child_node_id = ch.parent_node_id AND LEVEL <= 3) t where t."Path" in (''/system/workflow/packages'')';
    EXECUTE IMMEDIATE V_SQL BULK COLLECT INTO v_parent_node_id,v_child_node_id;
    begin
        for i in 1..v_child_node_id.COUNT loop
            --t_num :=t_num+1;
            INSERT_NODE(v_child_node_id(i),v_parent_node_id(i),'child',Childcascade);
        --if MOD(t_num,100)=0 then COMMIT; end if;
        end loop;
    COMMIT;
--    dbms_output.put_line('Processing Completed for system And committed record count for c6: '||t_num );
    end;
	V_END_TIME:=SYSDATE;
	SP_MIGRATION_PROCESS_LOG('SP_INSERT_SUBDATA_PART6', V_START_TIME, V_END_TIME,NULL, NULL, NULL,NULL, NULL, NULL, V_REMARKS, NULL) ;
EXCEPTION WHEN OTHERS
THEN V_REMARKS:='Not Processed';
SP_MIGRATION_PROCESS_LOG('SP_INSERT_SUBDATA_PART6', V_START_TIME, V_END_TIME,NULL, null, null,null,SQLCODE, SQLERRM, V_REMARKS,NULL) ;
END SP_INSERT_SUBDATA_PART6;
PROCEDURE SP_INSERT_SUBDATA_PART7 IS
    t_num NUMBER :=0;
    Childcascade VARCHAR2(100) :='false'; --Change this to true if child cascade required
    type t_parent_id is table of alf_child_assoc.parent_node_id%type;
    type t_child_id is table of alf_child_assoc.child_node_id%type;
    v_parent_node_id t_parent_id;
    v_child_node_id t_child_id;
    V_SQL CLOB;
	V_START_TIME DATE;
	V_END_TIME DATE;
	V_REMARKS VARCHAR2(100 CHAR);
BEGIN
	V_START_TIME:=SYSDATE;
	V_REMARKS:='Completed successfully';
    V_SQL:='Select parent_node_id,child_node_id from (Select LEVEL,SYS_CONNECT_BY_PATH(ch.qname_localname, ''/'') "Path",ch.* from alf_child_assoc'||V_DB_LINK||' ch START WITH ch.parent_node_id in
(Select id from tmp_alf_ids'||V_DB_LINK||' where protocol=''workspace'' and IDENTIFIER=''SpacesStore'' and  Path=''/system/authorities'')
CONNECT By PRIOR  ch.child_node_id = ch.parent_node_id AND LEVEL <= 1) t
where t."Path" in (''/GROUP_ALFRESCO_ADMINISTRATORS'',''/GROUP_EMAIL_CONTRIBUTORS'',''/GROUP_SITE_ADMINISTRATORS'',
''/GROUP_ALFRESCO_SEARCH_ADMINISTRATORS'',''/GROUP_ALFRESCO_MODEL_ADMINISTRATORS'',''/GROUP_ALFRESCO_SYSTEM_ADMINISTRATORS'')';
    EXECUTE IMMEDIATE V_SQL BULK COLLECT INTO v_parent_node_id,v_child_node_id;
    begin
        for i in 1..v_child_node_id.COUNT loop
            --t_num :=t_num+1;
            INSERT_NODE(v_child_node_id(i),v_parent_node_id(i),'child',Childcascade);
        --if MOD(t_num,100)=0 then COMMIT; end if;
        end loop;
    COMMIT;

  --  dbms_output.put_line('Processing Completed for system And committed record count for c7: '||t_num );
    end;
	V_END_TIME:=SYSDATE;
	SP_MIGRATION_PROCESS_LOG('SP_INSERT_SUBDATA_PART7', V_START_TIME, V_END_TIME,NULL, NULL, NULL,NULL, NULL, NULL, V_REMARKS, NULL) ;
EXCEPTION WHEN OTHERS
THEN V_REMARKS:='Not Processed';
SP_MIGRATION_PROCESS_LOG('SP_INSERT_SUBDATA_PART7', V_START_TIME, V_END_TIME,NULL, null, null,null,SQLCODE, SQLERRM, V_REMARKS,NULL) ;
END SP_INSERT_SUBDATA_PART7;
PROCEDURE SP_INSERT_SUBDATA_PART8 IS
    t_num NUMBER :=0;
    Childcascade VARCHAR2(100) :='false'; --Change this to true if child cascade required
    type t_parent_id is table of alf_child_assoc.parent_node_id%type;
    type t_child_id is table of alf_child_assoc.child_node_id%type;
    v_parent_node_id t_parent_id;
    v_child_node_id t_child_id;
    V_SQL CLOB;
	V_START_TIME DATE;
	V_END_TIME DATE;
	V_REMARKS VARCHAR2(100 CHAR);
BEGIN
	V_START_TIME:=SYSDATE;
	V_REMARKS:='Completed successfully';
    V_SQL:='Select parent_node_id,child_node_id from (Select LEVEL,SYS_CONNECT_BY_PATH(ch.qname_localname, ''/'') "Path",ch.* from alf_child_assoc'||V_DB_LINK||' ch  START WITH  ch.parent_node_id in (
Select id from tmp_alf_ids'||V_DB_LINK||' where protocol=''workspace'' and IDENTIFIER=''SpacesStore'' and path in (''/system/authorities/GROUP_ALFRESCO_ADMINISTRATORS'',''/system/authorities/GROUP_EMAIL_CONTRIBUTORS'',''/system/authorities/GROUP_SITE_ADMINISTRATORS'',
''/system/authorities/GROUP_ALFRESCO_SEARCH_ADMINISTRATORS'',''/system/authorities/GROUP_ALFRESCO_MODEL_ADMINISTRATORS'',''/system/authorities/GROUP_ALFRESCO_SYSTEM_ADMINISTRATORS''))
CONNECT BY PRIOR  ch.child_node_id = ch.parent_node_id  ORDER BY 1,parent_node_id,child_node_id asc) t
where t.child_node_id in (Select p.node_id from alf_node_properties p
join alf_qname'||V_DB_LINK||' q on p.qname_id=q.id
where p.STRING_VALUE in (''admin'',''guest'',''abeecher'',''mjackson'',''API_User'')
and p.qname_id=(Select id from alf_qname'||V_DB_LINK||' where LOCAL_NAME=''userName''))';
    EXECUTE IMMEDIATE V_SQL BULK COLLECT INTO v_parent_node_id,v_child_node_id;
    begin
        for i in 1..v_child_node_id.COUNT loop
            --t_num :=t_num+1;
            INSERT_NODE(v_child_node_id(i),v_parent_node_id(i),'child',Childcascade);
        --if MOD(t_num,100)=0 then COMMIT; end if;
        end loop;
    COMMIT;

    --dbms_output.put_line('Processing Completed for system And committed record count for c8: '||t_num );
    end;
	V_END_TIME:=SYSDATE;
	SP_MIGRATION_PROCESS_LOG('SP_INSERT_SUBDATA_PART8', V_START_TIME, V_END_TIME,NULL, NULL, NULL,NULL, NULL, NULL, V_REMARKS, NULL) ;
EXCEPTION WHEN OTHERS
THEN V_REMARKS:='Not Processed';
SP_MIGRATION_PROCESS_LOG('SP_INSERT_SUBDATA_PART8', V_START_TIME, V_END_TIME,NULL, null, null,null,SQLCODE, SQLERRM, V_REMARKS,NULL) ;
END SP_INSERT_SUBDATA_PART8;
PROCEDURE SP_INSERT_SUBDATA_PART9 IS
    t_num NUMBER :=0;
    Childcascade VARCHAR2(100) :='false'; --Change this to true if child cascade required
    type t_parent_id is table of alf_child_assoc.parent_node_id%type;
    type t_child_id is table of alf_child_assoc.child_node_id%type;
    v_parent_node_id t_parent_id;
    v_child_node_id t_child_id;
    V_SQL CLOB;
	V_START_TIME DATE;
	V_END_TIME DATE;
	V_REMARKS VARCHAR2(100 CHAR);
BEGIN
	V_START_TIME:=SYSDATE;
	V_REMARKS:='Completed successfully';
    V_SQL:='Select parent_node_id,child_node_id from (Select LEVEL,SYS_CONNECT_BY_PATH(ch.qname_localname, ''/'') "Path",ch.* from alf_child_assoc'||V_DB_LINK||' ch  START WITH  ch.parent_node_id in
(Select t.CHILD_NODE_ID from (Select LEVEL,SYS_CONNECT_BY_PATH(ch.qname_localname, ''/'') "Path",ch.* from alf_child_assoc'||V_DB_LINK||' ch START WITH ch.parent_node_id in
(Select root_node_id from alf_store'||V_DB_LINK||' where protocol=''workspace'' and IDENTIFIER=''SpacesStore'')
CONNECT By PRIOR  ch.child_node_id = ch.parent_node_id AND LEVEL <= 2) t where t."Path" in (''/system/zones''))
CONNECT BY PRIOR  ch.child_node_id = ch.parent_node_id and level<2
ORDER BY 1,parent_node_id,child_node_id asc) t';
    EXECUTE IMMEDIATE V_SQL BULK COLLECT INTO v_parent_node_id,v_child_node_id;
    begin
        for i in 1..v_child_node_id.COUNT loop
            --t_num :=t_num+1;
            INSERT_NODE(v_child_node_id(i),v_parent_node_id(i),'child',Childcascade);
        --if MOD(t_num,100)=0 then COMMIT; end if;
        end loop;
    COMMIT;

    --dbms_output.put_line('Processing Completed for system And committed record count for c9: '||t_num );
    end;
	V_END_TIME:=SYSDATE;
	SP_MIGRATION_PROCESS_LOG('SP_INSERT_SUBDATA_PART9', V_START_TIME, V_END_TIME,NULL, NULL, NULL,NULL, NULL, NULL, V_REMARKS, NULL) ;
EXCEPTION WHEN OTHERS
THEN V_REMARKS:='Not Processed';
SP_MIGRATION_PROCESS_LOG('SP_INSERT_SUBDATA_PART9', V_START_TIME, V_END_TIME,NULL, null, null,null,SQLCODE, SQLERRM, V_REMARKS,NULL) ;
END SP_INSERT_SUBDATA_PART9;
PROCEDURE SP_INSERT_SUBDATA_PART10 IS
    t_num NUMBER :=0;
    Childcascade VARCHAR2(100) :='false'; --Change this to true if child cascade required
    type t_parent_id is table of alf_child_assoc.parent_node_id%type;
    type t_child_id is table of alf_child_assoc.child_node_id%type;
    v_parent_node_id t_parent_id;
    v_child_node_id t_child_id;
    V_SQL CLOB;
	V_START_TIME DATE;
	V_END_TIME DATE;
	V_REMARKS VARCHAR2(100 CHAR);
BEGIN
	V_START_TIME:=SYSDATE;
	V_REMARKS:='Completed successfully';
    V_SQL:='Select parent_node_id,child_node_id from (Select LEVEL,SYS_CONNECT_BY_PATH(ch.qname_localname, ''/'') "Path",ch.* from alf_child_assoc'||V_DB_LINK||'  ch  START WITH  ch.parent_node_id in (
Select id from tmp_alf_ids'||V_DB_LINK||'  where protocol=''workspace'' and IDENTIFIER=''SpacesStore'' and path in (''/system/zones/AUTH.ALF'',''/system/zones/APP.DEFAULT'',''/system/zones/APP.SHARE'')
)CONNECT BY PRIOR  ch.child_node_id = ch.parent_node_id and level<2
ORDER BY 1,parent_node_id,child_node_id asc) t where t."Path" in
(''/admin'',''/guest'',''/API_User'',''/GROUP_ALFRESCO_ADMINISTRATORS'',''/GROUP_EMAIL_CONTRIBUTORS'',''/GROUP_SITE_ADMINISTRATORS'',''/GROUP_ALFRESCO_MODEL_ADMINISTRATORS'',''/GROUP_ALFRESCO_SYSTEM_ADMINISTRATORS'',''/GROUP_ALFRESCO_SEARCH_ADMINISTRATORS'')';
    EXECUTE IMMEDIATE V_SQL BULK COLLECT INTO v_parent_node_id,v_child_node_id;
    begin
        for i in 1..v_child_node_id.COUNT loop
            --t_num :=t_num+1;
            INSERT_NODE(v_child_node_id(i),v_parent_node_id(i),'child',Childcascade);
        --if MOD(t_num,100)=0 then COMMIT; end if;
        end loop;
    COMMIT;
    --dbms_output.put_line('Processing Completed for system And committed record count for c10: '||t_num );
    end;
	V_END_TIME:=SYSDATE;
	SP_MIGRATION_PROCESS_LOG('SP_INSERT_SUBDATA_PART10', V_START_TIME, V_END_TIME,NULL, NULL, NULL,NULL, NULL, NULL, V_REMARKS, NULL) ;
EXCEPTION WHEN OTHERS
THEN V_REMARKS:='Not Processed';
SP_MIGRATION_PROCESS_LOG('SP_INSERT_SUBDATA_PART10', V_START_TIME, V_END_TIME,NULL, null, null,null,SQLCODE, SQLERRM, V_REMARKS,NULL) ;
END SP_INSERT_SUBDATA_PART10;
PROCEDURE SP_INSERT_STORE_SUBDATA_PART2 IS
    t_num NUMBER :=0;
    Childcascade VARCHAR2(100) :='true'; --Change this to true if child cascade required
    type t_parent_id is table of alf_child_assoc.parent_node_id%type;
    type t_child_id is table of alf_child_assoc.child_node_id%type;
    v_parent_node_id t_parent_id;
    v_child_node_id t_child_id;
    V_SQL CLOB;
	V_START_TIME DATE;
	V_END_TIME DATE;
	V_REMARKS VARCHAR2(100 CHAR);
BEGIN
	V_START_TIME:=SYSDATE;
	V_REMARKS:='Completed successfully';
    V_SQL:='Select parent_node_id,child_node_id from (Select LEVEL,SYS_CONNECT_BY_PATH(ch.qname_localname, ''/'') "Path",ch.* from alf_child_assoc'||V_DB_LINK||' ch  START WITH  ch.parent_node_id in (Select id from tmp_alf_ids'||V_DB_LINK||'  where protocol=''workspace'' and IDENTIFIER=''SpacesStore'' and path in (''/company_home/sites''))CONNECT BY PRIOR  ch.child_node_id = ch.parent_node_id  and level < 2) t
where t."Path"  not in (Select ''/''||p.string_value from alf_node_properties'||V_DB_LINK||' p join alf_node'||V_DB_LINK||' n on n.id=p.node_id and n.type_qname_id in (Select id from alf_qname'||V_DB_LINK||' where local_name=''site'') where p.qname_id in (Select id from alf_qname'||V_DB_LINK||' where local_name=''name''))';
    EXECUTE IMMEDIATE V_SQL BULK COLLECT INTO v_parent_node_id,v_child_node_id;
    begin
        for i in 1..v_child_node_id.COUNT loop
            --t_num :=t_num+1;
            INSERT_NODE(v_child_node_id(i),v_parent_node_id(i),'child',Childcascade);
        --if MOD(t_num,100)=0 then COMMIT; end if;
        end loop;
    COMMIT;
--        dbms_output.put_line('Processing Completed for system And committed record count for c1: '||t_num );
    end;
	V_END_TIME:=SYSDATE;
	SP_MIGRATION_PROCESS_LOG('SP_INSERT_STORE_SUBDATA_PART2', V_START_TIME, V_END_TIME,NULL, NULL, NULL,NULL, NULL, NULL, V_REMARKS, NULL) ;
EXCEPTION WHEN OTHERS
THEN V_REMARKS:='Not Processed';
SP_MIGRATION_PROCESS_LOG('SP_INSERT_STORE_SUBDATA_PART2', V_START_TIME, V_END_TIME,NULL, null, null,null,SQLCODE, SQLERRM, V_REMARKS,NULL) ;
END SP_INSERT_STORE_SUBDATA_PART2;


PROCEDURE SP_INSERT_SYSTEM_AUDITMODEL_FEED_LOCK IS
V_START_TIME DATE;
V_END_TIME DATE;
V_REF_NAME VARCHAR2(100 CHAR);
V_REF_ID NUMBER(38,0);
V_TABLE_NAME VARCHAR2(100 CHAR);
V_PRE_DATA_COUNT NUMBER(38,0);
V_POST_DATA_COUNT NUMBER(38,0);
V_REMARKS VARCHAR2(100 CHAR);
V_SQL CLOB;
BEGIN
	V_START_TIME:=SYSDATE;
    V_REF_NAME:='SYSTEM_AUDITMODEL_FEED_LOCK';
    V_REF_ID:=0;
    V_REMARKS:='Completed successfully';
-- Audit Model (Make sure all the audit data is copied to custom table as it will copy the model only. the audit entries will be skipped)
    BEGIN
		V_SQL:='Select COUNT (1) from alf_content_url'||V_DB_LINK||' a where a.id in
		(Select CONTENT_URL_ID from alf_content_data'||V_DB_LINK||' where id in (select CONTENT_DATA_ID from ALF_AUDIT_MODEL'||V_DB_LINK||'))
		and not exists (Select * from alf_content_url e where e.id=a.id)';
		EXECUTE IMMEDIATE V_SQL INTO V_PRE_DATA_COUNT;
		V_TABLE_NAME:='alf_content_url';
		V_SQL:='insert into alf_content_url
		Select * from alf_content_url'||V_DB_LINK||' a where a.id in
		(Select CONTENT_URL_ID from alf_content_data'||V_DB_LINK||' where id in (select CONTENT_DATA_ID from ALF_AUDIT_MODEL'||V_DB_LINK||'))
		and not exists (Select * from alf_content_url e where e.id=a.id)';
		EXECUTE IMMEDIATE V_SQL;
		V_SQL:='select count(1) from alf_content_url a where a.id in
		(Select CONTENT_URL_ID from alf_content_data where id in (select CONTENT_DATA_ID from ALF_AUDIT_MODEL))';
		EXECUTE IMMEDIATE V_SQL INTO V_POST_DATA_COUNT;
		V_END_TIME:=SYSDATE;
			SP_MIGRATION_PROCESS_LOG('SP_INSERT_SYSTEM_AUDITMODEL_FEED_LOCK', V_START_TIME, V_END_TIME,V_REF_NAME, V_REF_ID, V_PRE_DATA_COUNT, V_POST_DATA_COUNT,NULL,NULL,NULL, V_TABLE_NAME);
	EXCEPTION
		WHEN OTHERS THEN
			V_REMARKS:='Not Processed';
			SP_MIGRATION_PROCESS_LOG('SP_INSERT_SYSTEM_AUDITMODEL_FEED_LOCK', V_START_TIME, V_END_TIME,V_REF_NAME, V_REF_ID, V_PRE_DATA_COUNT,NULL, SQLCODE, SQLERRM, V_REMARKS, V_TABLE_NAME) ;
    END;

	BEGIN
		V_REMARKS:='Completed successfully';
		V_START_TIME:=V_END_TIME;
		V_SQL:='Select count (1) from alf_content_data'||V_DB_LINK||' a where a.id in (select CONTENT_DATA_ID from ALF_AUDIT_MODEL'||V_DB_LINK||')
		and not exists (Select * from alf_content_data e where e.id=a.id)';
		EXECUTE IMMEDIATE V_SQL INTO V_PRE_DATA_COUNT;
		V_TABLE_NAME:='alf_content_data';
		V_SQL:='insert into alf_content_data
		Select * from alf_content_data'||V_DB_LINK||' a where a.id in (select CONTENT_DATA_ID from ALF_AUDIT_MODEL'||V_DB_LINK||')
		and not exists (Select * from alf_content_data e where e.id=a.id)';
		EXECUTE IMMEDIATE V_SQL;
		V_SQL:='select count(1) from alf_content_data a where a.id in (select CONTENT_DATA_ID from ALF_AUDIT_MODEL)';
		EXECUTE IMMEDIATE V_SQL INTO V_POST_DATA_COUNT;
		V_END_TIME:=SYSDATE;
			SP_MIGRATION_PROCESS_LOG('SP_INSERT_SYSTEM_AUDITMODEL_FEED_LOCK', V_START_TIME, V_END_TIME,V_REF_NAME, V_REF_ID, V_PRE_DATA_COUNT, V_POST_DATA_COUNT,NULL,NULL,NULL, V_TABLE_NAME);
	EXCEPTION
		WHEN OTHERS THEN
			V_REMARKS:='Not Processed';
			SP_MIGRATION_PROCESS_LOG('SP_INSERT_SYSTEM_AUDITMODEL_FEED_LOCK', V_START_TIME, V_END_TIME,V_REF_NAME, V_REF_ID, V_PRE_DATA_COUNT,NULL, SQLCODE, SQLERRM, V_REMARKS, V_TABLE_NAME) ;
    END;

	BEGIN
		V_REMARKS:='Completed successfully';
		V_START_TIME:=V_END_TIME;
		V_SQL:='select count (1) from ALF_AUDIT_MODEL'||V_DB_LINK||' a
		where not exists (Select * from ALF_AUDIT_MODEL e where e.id=a.id)';
		EXECUTE IMMEDIATE V_SQL INTO V_PRE_DATA_COUNT;
		V_TABLE_NAME:='ALF_AUDIT_MODEL';
		V_SQL:='insert into ALF_AUDIT_MODEL
		select * from ALF_AUDIT_MODEL'||V_DB_LINK||' a
		where not exists (Select * from ALF_AUDIT_MODEL e where e.id=a.id)';
		EXECUTE IMMEDIATE V_SQL;
		V_SQL:='select count(1) from ALF_AUDIT_MODEL a';
		EXECUTE IMMEDIATE V_SQL INTO V_POST_DATA_COUNT;
		V_END_TIME:=SYSDATE;
			SP_MIGRATION_PROCESS_LOG('SP_INSERT_SYSTEM_AUDITMODEL_FEED_LOCK', V_START_TIME, V_END_TIME,V_REF_NAME, V_REF_ID, V_PRE_DATA_COUNT, V_POST_DATA_COUNT,NULL,NULL,NULL, V_TABLE_NAME);
	EXCEPTION
		WHEN OTHERS THEN
			V_REMARKS:='Not Processed';
			SP_MIGRATION_PROCESS_LOG('SP_INSERT_SYSTEM_AUDITMODEL_FEED_LOCK', V_START_TIME, V_END_TIME,V_REF_NAME, V_REF_ID, V_PRE_DATA_COUNT,NULL, SQLCODE, SQLERRM, V_REMARKS, V_TABLE_NAME) ;
    END;

	BEGIN
		V_REMARKS:='Completed successfully';
		V_START_TIME:=V_END_TIME;
		V_SQL:='select count (1) from ALF_PROP_STRING_VALUE'||V_DB_LINK||'';
		EXECUTE IMMEDIATE V_SQL INTO V_PRE_DATA_COUNT;
		V_TABLE_NAME:='ALF_PROP_STRING_VALUE';
		V_SQL:='insert into ALF_PROP_STRING_VALUE
		select * from ALF_PROP_STRING_VALUE'||V_DB_LINK||'';
		EXECUTE IMMEDIATE V_SQL;
		V_SQL:='select count(1)from ALF_PROP_STRING_VALUE';
		EXECUTE IMMEDIATE V_SQL INTO V_POST_DATA_COUNT;
		V_END_TIME:=SYSDATE;
			SP_MIGRATION_PROCESS_LOG('SP_INSERT_SYSTEM_AUDITMODEL_FEED_LOCK', V_START_TIME, V_END_TIME,V_REF_NAME, V_REF_ID, V_PRE_DATA_COUNT, V_POST_DATA_COUNT,NULL,NULL,NULL, V_TABLE_NAME);
	EXCEPTION
		WHEN OTHERS THEN
			V_REMARKS:='Not Processed';
			SP_MIGRATION_PROCESS_LOG('SP_INSERT_SYSTEM_AUDITMODEL_FEED_LOCK', V_START_TIME, V_END_TIME,V_REF_NAME, V_REF_ID, V_PRE_DATA_COUNT,NULL, SQLCODE, SQLERRM, V_REMARKS, V_TABLE_NAME) ;
    END;

    BEGIN
		V_REMARKS:='Completed successfully';
		V_START_TIME:=V_END_TIME;
		V_SQL:='select count (1) from ALF_PROP_CLASS'||V_DB_LINK||' a
		where not exists (Select * from ALF_PROP_CLASS e where e.id=a.id)';
		EXECUTE IMMEDIATE V_SQL INTO V_PRE_DATA_COUNT;
		V_TABLE_NAME:='ALF_PROP_CLASS';
		V_SQL:='insert into ALF_PROP_CLASS
		select * from ALF_PROP_CLASS'||V_DB_LINK||' a
		where not exists (Select * from ALF_PROP_CLASS e where e.id=a.id)';
		EXECUTE IMMEDIATE V_SQL;
		V_SQL:='select count(1) from ALF_PROP_CLASS a';
		EXECUTE IMMEDIATE V_SQL INTO V_POST_DATA_COUNT;
		V_END_TIME:=SYSDATE;
			SP_MIGRATION_PROCESS_LOG('SP_INSERT_SYSTEM_AUDITMODEL_FEED_LOCK', V_START_TIME, V_END_TIME,V_REF_NAME, V_REF_ID, V_PRE_DATA_COUNT, V_POST_DATA_COUNT,NULL,NULL,NULL, V_TABLE_NAME);
	EXCEPTION
		WHEN OTHERS THEN
			V_REMARKS:='Not Processed';
			SP_MIGRATION_PROCESS_LOG('SP_INSERT_SYSTEM_AUDITMODEL_FEED_LOCK', V_START_TIME, V_END_TIME,V_REF_NAME, V_REF_ID, V_PRE_DATA_COUNT,NULL, SQLCODE, SQLERRM, V_REMARKS, V_TABLE_NAME) ;
    END;

    --Lock (Copy as it is)
	BEGIN
		V_REMARKS:='Completed successfully';
		V_START_TIME:=V_END_TIME;
		V_SQL:='Select count (1) from ALF_LOCK_RESOURCE'||V_DB_LINK||'';
		EXECUTE IMMEDIATE V_SQL INTO V_PRE_DATA_COUNT;
		V_TABLE_NAME:='ALF_LOCK_RESOURCE';
		V_SQL:='insert into ALF_LOCK_RESOURCE Select * from ALF_LOCK_RESOURCE'||V_DB_LINK||'';
		EXECUTE IMMEDIATE V_SQL;
		V_SQL:='select count(1) from ALF_LOCK_RESOURCE';
		EXECUTE IMMEDIATE V_SQL INTO V_POST_DATA_COUNT;
		V_END_TIME:=SYSDATE;
			SP_MIGRATION_PROCESS_LOG('SP_INSERT_SYSTEM_AUDITMODEL_FEED_LOCK', V_START_TIME, V_END_TIME,V_REF_NAME, V_REF_ID, V_PRE_DATA_COUNT, V_POST_DATA_COUNT,NULL,NULL,NULL, V_TABLE_NAME);
	EXCEPTION
		WHEN OTHERS THEN
			V_REMARKS:='Not Processed';
			SP_MIGRATION_PROCESS_LOG('SP_INSERT_SYSTEM_AUDITMODEL_FEED_LOCK', V_START_TIME, V_END_TIME,V_REF_NAME, V_REF_ID, V_PRE_DATA_COUNT,NULL, SQLCODE, SQLERRM, V_REMARKS, V_TABLE_NAME) ;
    END;

	BEGIN
		V_REMARKS:='Completed successfully';
		V_START_TIME:=V_END_TIME;
		V_SQL:='Select count (1) from ALF_LOCK'||V_DB_LINK||'';
		EXECUTE IMMEDIATE V_SQL INTO V_PRE_DATA_COUNT;
		V_TABLE_NAME:='ALF_LOCK';
		V_SQL:='insert into ALF_LOCK Select * from ALF_LOCK'||V_DB_LINK||'';
		EXECUTE IMMEDIATE V_SQL;
		V_SQL:='select count(1) from ALF_LOCK';
		EXECUTE IMMEDIATE V_SQL INTO V_POST_DATA_COUNT;
		V_END_TIME:=SYSDATE;
			SP_MIGRATION_PROCESS_LOG('SP_INSERT_SYSTEM_AUDITMODEL_FEED_LOCK', V_START_TIME, V_END_TIME,V_REF_NAME, V_REF_ID, V_PRE_DATA_COUNT, V_POST_DATA_COUNT,NULL,NULL,NULL, V_TABLE_NAME);
	EXCEPTION
		WHEN OTHERS THEN
			V_REMARKS:='Not Processed';
			SP_MIGRATION_PROCESS_LOG('SP_INSERT_SYSTEM_AUDITMODEL_FEED_LOCK', V_START_TIME, V_END_TIME,V_REF_NAME, V_REF_ID, V_PRE_DATA_COUNT,NULL, SQLCODE, SQLERRM, V_REMARKS, V_TABLE_NAME) ;
    END;

    --Activity Feed (Copy as it is)
    BEGIN
		V_REMARKS:='Completed successfully';
		V_START_TIME:=V_END_TIME;
		V_SQL:='Select count (1) from ALF_ACTIVITY_FEED'||V_DB_LINK||' ';
		EXECUTE IMMEDIATE V_SQL INTO V_PRE_DATA_COUNT;
		V_TABLE_NAME:='ALF_ACTIVITY_FEED';
		V_SQL:='insert into ALF_ACTIVITY_FEED Select * from ALF_ACTIVITY_FEED'||V_DB_LINK||' ';
		EXECUTE IMMEDIATE V_SQL;
		V_SQL:='select count(1) from ALF_ACTIVITY_FEED';
		EXECUTE IMMEDIATE V_SQL INTO V_POST_DATA_COUNT;
		V_END_TIME:=SYSDATE;
			SP_MIGRATION_PROCESS_LOG('SP_INSERT_SYSTEM_AUDITMODEL_FEED_LOCK', V_START_TIME, V_END_TIME,V_REF_NAME, V_REF_ID, V_PRE_DATA_COUNT, V_POST_DATA_COUNT,NULL,NULL,NULL, V_TABLE_NAME);
	EXCEPTION
		WHEN OTHERS THEN
			V_REMARKS:='Not Processed';
			SP_MIGRATION_PROCESS_LOG('SP_INSERT_SYSTEM_AUDITMODEL_FEED_LOCK', V_START_TIME, V_END_TIME,V_REF_NAME, V_REF_ID, V_PRE_DATA_COUNT,NULL, SQLCODE, SQLERRM, V_REMARKS, V_TABLE_NAME) ;
    END;

	BEGIN
		V_REMARKS:='Completed successfully';
		V_START_TIME:=V_END_TIME;
		V_SQL:='Select count (1) from ALF_ACTIVITY_POST'||V_DB_LINK||'';
		EXECUTE IMMEDIATE V_SQL INTO V_PRE_DATA_COUNT;
		V_TABLE_NAME:='ALF_ACTIVITY_POST';
		V_SQL:='insert into ALF_ACTIVITY_POST Select * from ALF_ACTIVITY_POST'||V_DB_LINK||'';
		EXECUTE IMMEDIATE V_SQL;
		V_SQL:='select count(1) from ALF_ACTIVITY_POST';
		EXECUTE IMMEDIATE V_SQL INTO V_POST_DATA_COUNT;
			V_END_TIME:=SYSDATE;
				SP_MIGRATION_PROCESS_LOG('SP_INSERT_SYSTEM_AUDITMODEL_FEED_LOCK', V_START_TIME, V_END_TIME,V_REF_NAME, V_REF_ID, V_PRE_DATA_COUNT, V_POST_DATA_COUNT,NULL,NULL,NULL, V_TABLE_NAME);
	EXCEPTION
		WHEN OTHERS THEN
			V_REMARKS:='Not Processed';
			SP_MIGRATION_PROCESS_LOG('SP_INSERT_SYSTEM_AUDITMODEL_FEED_LOCK', V_START_TIME, V_END_TIME,V_REF_NAME, V_REF_ID, V_PRE_DATA_COUNT,NULL, SQLCODE, SQLERRM, V_REMARKS, V_TABLE_NAME) ;
    END;

    COMMIT;
EXCEPTION
	WHEN OTHERS THEN
		V_REMARKS:='Not Processed';
		SP_MIGRATION_PROCESS_LOG('SP_INSERT_SYSTEM_AUDITMODEL_FEED_LOCK', NULL, NULL,NULL, NULL, NULL,NULL, SQLCODE, SQLERRM, V_REMARKS, NULL) ;
END SP_INSERT_SYSTEM_AUDITMODEL_FEED_LOCK;

PROCEDURE INSERT_NODE(nodeId NUMBER,parentNodeId number, type VARCHAR2,Childcascade VARCHAR2) AS
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
    type t_parent_id is table of alf_child_assoc.parent_node_id%type;
    type t_child_id is table of alf_child_assoc.child_node_id%type;
	TYPE T_LONG_VALUE IS TABLE OF alf_node_properties.long_value%TYPE;
    v_parent_node_id t_parent_id;
    v_child_node_id t_child_id;
    v_sc_parent_node_id t_parent_id;
    v_sc_child_node_id t_child_id;
	V_LONG_VALUE T_LONG_VALUE;
    V_SQL CLOB;
	V_COUNT NUMBER;
	V_START_TIME DATE;
    V_END_TIME DATE;
    V_REF_NAME VARCHAR2(100 CHAR);
    V_REF_ID NUMBER(38,0);
    V_TABLE_NAME VARCHAR2(100 CHAR);
    V_PRE_DATA_COUNT NUMBER(38,0);
    V_post_DATA_COUNT NUMBER(38,0);
    V_REMARKS VARCHAR2(100 CHAR);
cursor c1 is
Select id from alf_node where id=nodeId;

begin
    V_START_TIME:=SYSDATE;
    V_REF_NAME:='NODE_ID';
    V_REF_ID:=nodeId;
    V_REMARKS:='Completed successfully';

	open c1;
	FETCH c1 into c_nodeid;

	if c1%notfound then
	BEGIN
		--dbms_output.put_line(''Processing Child:''||nodeId ||'' Parent:''||parentNodeId||'' Type:''||type);
		V_SQL:='SELECT COUNT(1) FROM alf_transaction'||V_DB_LINK||' a WHERE a.ID IN (Select  n.transaction_id from alf_node'||V_DB_LINK||' n WHERE n.id in ('||nodeId ||')) and not EXISTS (select 1 from alf_transaction e where e.id=a.id)';
		EXECUTE IMMEDIATE V_SQL INTO V_PRE_DATA_COUNT;
		V_TABLE_NAME:='alf_transaction';
		V_SQL:='insert into alf_transaction Select * FROM alf_transaction'||V_DB_LINK||' a WHERE a.ID IN (Select  n.transaction_id from alf_node'||V_DB_LINK||' n WHERE n.id in ('||nodeId ||')) and not EXISTS (select 1 from alf_transaction e where e.id=a.id)';
		EXECUTE IMMEDIATE V_SQL;
		V_SQL:='select count(1) FROM alf_transaction a WHERE a.ID IN (Select  n.transaction_id from alf_node n WHERE n.id in ('||nodeId ||'))' ;
		EXECUTE IMMEDIATE V_SQL INTO V_post_DATA_COUNT;
		V_END_TIME:=SYSDATE;
        SP_MIGRATION_PROCESS_LOG('INSERT_NODE', V_START_TIME, V_END_TIME,V_REF_NAME,V_REF_ID,V_PRE_DATA_COUNT,V_post_DATA_COUNT,null,null,null, V_TABLE_NAME );
    EXCEPTION
	WHEN OTHERS THEN
        V_REMARKS:='Not Processed';
        SP_MIGRATION_PROCESS_LOG('INSERT_NODE', V_START_TIME, V_END_TIME,V_REF_NAME, V_REF_ID, V_PRE_DATA_COUNT,null,SQLCODE, SQLERRM, V_REMARKS,V_TABLE_NAME) ;
    END;


		V_SQL:='Select acl.Id from alf_access_control_list'||V_DB_LINK||'  acl START WITH
		acl.id in (Select  n.acl_id from alf_node'||V_DB_LINK||' n WHERE n.id in ('||nodeId ||'))
		CONNECT BY NOCYCLE  acl.id = PRIOR acl.INHERITED_ACL';
		EXECUTE IMMEDIATE V_SQL BULK COLLECT into v_acl_ids;
		SP_ALF_POPULATE_NUM_FILTER_LIST(nodeId,v_acl_ids,V_SEQ);

    BEGIN
		V_REMARKS:='Completed successfully';
		V_START_TIME:=V_END_TIME;
		V_SQL:='Select count(1) from ALF_ACL_CHANGE_SET'||V_DB_LINK||' a where a.id in (Select DISTINCT acl.ACL_CHANGE_SET from alf_access_control_list'||V_DB_LINK||' acl where acl.id in (Select FILTER_VALUES from TBL_ALF_NUM_FILTER where SEQUENCE_NO ='||V_SEQ||'))
		and not EXISTS (select 1 from ALF_ACL_CHANGE_SET e where e.ID=a.ID)';
		EXECUTE IMMEDIATE V_SQL INTO V_PRE_DATA_COUNT;
		V_TABLE_NAME:='ALF_ACL_CHANGE_SET';
		V_SQL:='insert into ALF_ACL_CHANGE_SET
		Select * from ALF_ACL_CHANGE_SET'||V_DB_LINK||' a where a.id in (Select DISTINCT acl.ACL_CHANGE_SET from alf_access_control_list'||V_DB_LINK||' acl where acl.id in (Select FILTER_VALUES from TBL_ALF_NUM_FILTER where SEQUENCE_NO ='||V_SEQ||'))
		and not EXISTS (select 1 from ALF_ACL_CHANGE_SET e where e.ID=a.ID)';
		EXECUTE IMMEDIATE V_SQL;
		V_SQL:='select count(1)  from ALF_ACL_CHANGE_SET a where a.id in (Select DISTINCT acl.ACL_CHANGE_SET from alf_access_control_list acl where acl.id in (Select FILTER_VALUES from TBL_ALF_NUM_FILTER where SEQUENCE_NO ='||V_SEQ||'))';
        EXECUTE IMMEDIATE V_SQL INTO V_post_DATA_COUNT;
	    V_END_TIME:=SYSDATE;
        SP_MIGRATION_PROCESS_LOG('INSERT_NODE', V_START_TIME, V_END_TIME,V_REF_NAME,V_REF_ID,V_PRE_DATA_COUNT,V_post_DATA_COUNT,null,null,null, V_TABLE_NAME );
    EXCEPTION
	WHEN OTHERS THEN
        V_REMARKS:='Not Processed';
        SP_MIGRATION_PROCESS_LOG('INSERT_NODE', V_START_TIME, V_END_TIME,V_REF_NAME, V_REF_ID, V_PRE_DATA_COUNT,null,SQLCODE, SQLERRM, V_REMARKS,V_TABLE_NAME) ;
    END;

	BEGIN
		V_REMARKS:='Completed successfully';
		V_START_TIME:=V_END_TIME;
		V_SQL:='Select COUNT(1) from (Select * from alf_access_control_list'||V_DB_LINK||' where id in (Select FILTER_VALUES from TBL_ALF_NUM_FILTER where SEQUENCE_NO ='||V_SEQ||')) a
		where not EXISTS (select 1 from alf_access_control_list e where e.id=a.id)';
		EXECUTE IMMEDIATE V_SQL INTO V_PRE_DATA_COUNT;
		V_TABLE_NAME:='alf_access_control_list';
		V_SQL:='insert into alf_access_control_list
		Select * from (Select * from alf_access_control_list'||V_DB_LINK||' where id in (Select FILTER_VALUES from TBL_ALF_NUM_FILTER where SEQUENCE_NO ='||V_SEQ||')) a
		where not EXISTS (select 1 from alf_access_control_list e where e.id=a.id)';
		EXECUTE IMMEDIATE V_SQL;
		V_SQL:='select count(1) from (Select * from alf_access_control_list where id in (Select FILTER_VALUES from TBL_ALF_NUM_FILTER where SEQUENCE_NO ='||V_SEQ||')) a';
		EXECUTE IMMEDIATE V_SQL INTO V_post_DATA_COUNT;
	    V_END_TIME:=SYSDATE;
        SP_MIGRATION_PROCESS_LOG('INSERT_NODE', V_START_TIME, V_END_TIME,V_REF_NAME,V_REF_ID,V_PRE_DATA_COUNT,V_post_DATA_COUNT,null,null,null, V_TABLE_NAME );
    EXCEPTION
	WHEN OTHERS THEN
        V_REMARKS:='Not Processed';
        SP_MIGRATION_PROCESS_LOG('INSERT_NODE', V_START_TIME, V_END_TIME,V_REF_NAME, V_REF_ID, V_PRE_DATA_COUNT,null,SQLCODE, SQLERRM, V_REMARKS,V_TABLE_NAME) ;
    END;



	 begin
		V_REMARKS:='Completed successfully';
		V_START_TIME:=V_END_TIME;
		V_SQL:='Select COUNT(1) from alf_node'||V_DB_LINK||' WHERE id in ('||nodeId ||')';
		EXECUTE IMMEDIATE V_SQL INTO V_PRE_DATA_COUNT;
		V_TABLE_NAME:='alf_node';
		V_SQL:='insert into alf_node Select * from alf_node'||V_DB_LINK||' WHERE id in ('||nodeId ||')';
		EXECUTE IMMEDIATE V_SQL;
		V_SQL:='select count(1) from alf_node WHERE id in ('||nodeId ||')';
		EXECUTE IMMEDIATE V_SQL INTO V_post_DATA_COUNT;
	    V_END_TIME:=SYSDATE;
        SP_MIGRATION_PROCESS_LOG('INSERT_NODE', V_START_TIME, V_END_TIME,V_REF_NAME,V_REF_ID,V_PRE_DATA_COUNT,V_post_DATA_COUNT,null,null,null, V_TABLE_NAME );
    EXCEPTION
	WHEN OTHERS THEN
        V_REMARKS:='Not Processed';
        SP_MIGRATION_PROCESS_LOG('INSERT_NODE', V_START_TIME, V_END_TIME,V_REF_NAME, V_REF_ID, V_PRE_DATA_COUNT,null,SQLCODE, SQLERRM, V_REMARKS,V_TABLE_NAME) ;
    END;


	BEGIN
		V_REMARKS:='Completed successfully';
		V_START_TIME:=V_END_TIME;
		V_SQL:='Select count(1) from alf_node_properties'||V_DB_LINK||'  where node_id in ('||nodeId ||')';
		EXECUTE IMMEDIATE V_SQL INTO V_PRE_DATA_COUNT;
		V_TABLE_NAME:='alf_node_properties';
		V_SQL:='insert into alf_node_properties Select * from alf_node_properties'||V_DB_LINK||'  where node_id in ('||nodeId ||')';
		EXECUTE IMMEDIATE V_SQL;
		V_SQL:='select count(1)  from alf_node_properties  where node_id in ('||nodeId ||')';
        EXECUTE IMMEDIATE V_SQL INTO V_post_DATA_COUNT;
	    V_END_TIME:=SYSDATE;
        SP_MIGRATION_PROCESS_LOG('INSERT_NODE', V_START_TIME, V_END_TIME,V_REF_NAME,V_REF_ID,V_PRE_DATA_COUNT,V_post_DATA_COUNT,null,null,null, V_TABLE_NAME );
    EXCEPTION
	    WHEN OTHERS THEN
            V_REMARKS:='Not Processed';
            SP_MIGRATION_PROCESS_LOG('INSERT_NODE', V_START_TIME, V_END_TIME,V_REF_NAME, V_REF_ID, V_PRE_DATA_COUNT,null,SQLCODE, SQLERRM, V_REMARKS,V_TABLE_NAME) ;
    END;

	BEGIN
		V_REMARKS:='Completed successfully';
		V_START_TIME:=V_END_TIME;
     	V_SQL:='Select count(1) from ALF_NODE_ASPECTS'||V_DB_LINK||' where node_id in ('||nodeId ||')';
		EXECUTE IMMEDIATE V_SQL INTO V_PRE_DATA_COUNT;
		V_TABLE_NAME:='ALF_NODE_ASPECTS';
		V_SQL:='insert into ALF_NODE_ASPECTS Select * from ALF_NODE_ASPECTS'||V_DB_LINK||' where node_id in ('||nodeId ||')';
		EXECUTE IMMEDIATE V_SQL;
        V_SQL:='select count(1)  from ALF_NODE_ASPECTS where node_id in ('||nodeId ||')';
		EXECUTE IMMEDIATE V_SQL INTO V_post_DATA_COUNT;
	    V_END_TIME:=SYSDATE;
        SP_MIGRATION_PROCESS_LOG('INSERT_NODE', V_START_TIME, V_END_TIME,V_REF_NAME,V_REF_ID,V_PRE_DATA_COUNT,V_post_DATA_COUNT,null,null,null, V_TABLE_NAME );
    EXCEPTION
	    WHEN OTHERS THEN
            V_REMARKS:='Not Processed';
            SP_MIGRATION_PROCESS_LOG('INSERT_NODE', V_START_TIME, V_END_TIME,V_REF_NAME, V_REF_ID, V_PRE_DATA_COUNT,null,SQLCODE, SQLERRM, V_REMARKS,V_TABLE_NAME) ;
    END;

	BEGIN
		V_REMARKS:='Completed successfully';
		V_START_TIME:=V_END_TIME;
		V_SQL:='Select count(1) from ALF_NODE_ASSOC'||V_DB_LINK||'  where TARGET_NODE_ID in ('||nodeId ||')';
		EXECUTE IMMEDIATE V_SQL INTO V_PRE_DATA_COUNT;
		V_TABLE_NAME:='ALF_NODE_ASSOC';
		V_SQL:='insert into ALF_NODE_ASSOC Select * from ALF_NODE_ASSOC'||V_DB_LINK||'  where TARGET_NODE_ID in ('||nodeId ||')';
		EXECUTE IMMEDIATE V_SQL;
		V_SQL:='select count(1)  from ALF_NODE_ASSOC  where TARGET_NODE_ID in ('||nodeId ||')';
		EXECUTE IMMEDIATE V_SQL INTO V_post_DATA_COUNT;
	    V_END_TIME:=SYSDATE;
        SP_MIGRATION_PROCESS_LOG('INSERT_NODE', V_START_TIME, V_END_TIME,V_REF_NAME,V_REF_ID,V_PRE_DATA_COUNT,V_post_DATA_COUNT,null,null,null, V_TABLE_NAME );
        EXCEPTION
	          WHEN OTHERS THEN
                  V_REMARKS:='Not Processed';
                  if SQLCODE <>'-2291' then
                  SP_MIGRATION_PROCESS_LOG('INSERT_NODE', V_START_TIME, V_END_TIME,V_REF_NAME, V_REF_ID, V_PRE_DATA_COUNT,null,SQLCODE, SQLERRM, V_REMARKS,V_TABLE_NAME) ;
                  end if;

	end;


		--###Authority
	BEGIN
		V_REMARKS:='Completed successfully';
		V_START_TIME:=V_END_TIME;
		V_SQL:='Select count(1) from ALF_AUTHORITY'||V_DB_LINK||' a where a.id in (Select authority_id from ALF_ACCESS_CONTROL_ENTRY'||V_DB_LINK||' where ID in
		(SElect ace_id from ALF_ACL_MEMBER'||V_DB_LINK||' where acl_id in (Select FILTER_VALUES from TBL_ALF_NUM_FILTER where SEQUENCE_NO ='||V_SEQ||')))
		and not EXISTS (select 1 from ALF_AUTHORITY e where e.id=a.id)'	;
		EXECUTE IMMEDIATE V_SQL INTO V_PRE_DATA_COUNT;
		V_TABLE_NAME:='ALF_AUTHORITY';
		V_SQL:='insert into ALF_AUTHORITY
		Select * from ALF_AUTHORITY'||V_DB_LINK||' a where a.id in (Select authority_id from ALF_ACCESS_CONTROL_ENTRY'||V_DB_LINK||' where ID in
		(SElect ace_id from ALF_ACL_MEMBER'||V_DB_LINK||' where acl_id in (Select FILTER_VALUES from TBL_ALF_NUM_FILTER where SEQUENCE_NO ='||V_SEQ||')))
		and not EXISTS (select 1 from ALF_AUTHORITY e where e.id=a.id)';
		EXECUTE IMMEDIATE V_SQL;
		V_SQL:='select count(1)  from ALF_AUTHORITY a where a.id in (Select authority_id from ALF_ACCESS_CONTROL_ENTRY where ID in
         (SElect ace_id from ALF_ACL_MEMBER where acl_id in (Select FILTER_VALUES from TBL_ALF_NUM_FILTER where SEQUENCE_NO ='||V_SEQ||')))';
     	EXECUTE IMMEDIATE V_SQL INTO V_post_DATA_COUNT;
	    V_END_TIME:=SYSDATE;
        SP_MIGRATION_PROCESS_LOG('INSERT_NODE', V_START_TIME, V_END_TIME,V_REF_NAME,V_REF_ID,V_PRE_DATA_COUNT,V_post_DATA_COUNT,null,null,null, V_TABLE_NAME );
    EXCEPTION
	    WHEN OTHERS THEN
            V_REMARKS:='Not Processed';
            SP_MIGRATION_PROCESS_LOG('INSERT_NODE', V_START_TIME, V_END_TIME,V_REF_NAME, V_REF_ID, V_PRE_DATA_COUNT,null,SQLCODE, SQLERRM, V_REMARKS,V_TABLE_NAME) ;
    END;

	BEGIN
		V_REMARKS:='Completed successfully';
		V_START_TIME:=V_END_TIME;
    	V_SQL:='Select count(1) from ALF_ACCESS_CONTROL_ENTRY'||V_DB_LINK||' a where a.ID in (SElect ace_id from ALF_ACL_MEMBER'||V_DB_LINK||' where acl_id in (Select FILTER_VALUES from TBL_ALF_NUM_FILTER where SEQUENCE_NO ='||V_SEQ||'))
		and not EXISTS (select 1 from ALF_ACCESS_CONTROL_ENTRY e where e.id=a.id)';
		EXECUTE IMMEDIATE V_SQL INTO V_PRE_DATA_COUNT;
		V_TABLE_NAME:='ALF_ACCESS_CONTROL_ENTRY';
		V_SQL:='insert into ALF_ACCESS_CONTROL_ENTRY
		Select * from ALF_ACCESS_CONTROL_ENTRY'||V_DB_LINK||' a where a.ID in (SElect ace_id from ALF_ACL_MEMBER'||V_DB_LINK||' where acl_id in (Select FILTER_VALUES from TBL_ALF_NUM_FILTER where SEQUENCE_NO ='||V_SEQ||'))
		and not EXISTS (select 1 from ALF_ACCESS_CONTROL_ENTRY e where e.id=a.id)';
		EXECUTE IMMEDIATE V_SQL;
		V_SQL:='select count(1)  from ALF_ACCESS_CONTROL_ENTRY a where a.ID in (SElect ace_id from ALF_ACL_MEMBER where acl_id in (Select FILTER_VALUES from TBL_ALF_NUM_FILTER where SEQUENCE_NO ='||V_SEQ||'))';
		EXECUTE IMMEDIATE V_SQL INTO V_post_DATA_COUNT;
	    V_END_TIME:=SYSDATE;
        SP_MIGRATION_PROCESS_LOG('INSERT_NODE', V_START_TIME, V_END_TIME,V_REF_NAME,V_REF_ID,V_PRE_DATA_COUNT,V_post_DATA_COUNT,null,null,null, V_TABLE_NAME );
    EXCEPTION
	    WHEN OTHERS THEN
            V_REMARKS:='Not Processed';
            SP_MIGRATION_PROCESS_LOG('INSERT_NODE', V_START_TIME, V_END_TIME,V_REF_NAME, V_REF_ID, V_PRE_DATA_COUNT,null,SQLCODE, SQLERRM, V_REMARKS,V_TABLE_NAME) ;
    END;

	BEGIN
		V_REMARKS:='Completed successfully';
		V_START_TIME:=V_END_TIME;
    	V_SQL:='Select count(1) from ALF_ACL_MEMBER'||V_DB_LINK||' a where a.acl_id in (Select FILTER_VALUES from TBL_ALF_NUM_FILTER where SEQUENCE_NO ='||V_SEQ||')
		and not EXISTS (select 1 from ALF_ACL_MEMBER e where e.ID=a.ID)';
		EXECUTE IMMEDIATE V_SQL INTO V_PRE_DATA_COUNT;
		V_TABLE_NAME:='ALF_ACL_MEMBER';
		V_SQL:='insert into ALF_ACL_MEMBER
		Select * from ALF_ACL_MEMBER'||V_DB_LINK||' a where a.acl_id in (Select FILTER_VALUES from TBL_ALF_NUM_FILTER where SEQUENCE_NO ='||V_SEQ||')
		and not EXISTS (select 1 from ALF_ACL_MEMBER e where e.ID=a.ID)';
		EXECUTE IMMEDIATE V_SQL;
		V_SQL:='select count(1)  from ALF_ACL_MEMBER a where a.acl_id in (Select FILTER_VALUES from TBL_ALF_NUM_FILTER where SEQUENCE_NO ='||V_SEQ||')';
		EXECUTE IMMEDIATE V_SQL INTO V_post_DATA_COUNT;
	    V_END_TIME:=SYSDATE;
        SP_MIGRATION_PROCESS_LOG('INSERT_NODE', V_START_TIME, V_END_TIME,V_REF_NAME,V_REF_ID,V_PRE_DATA_COUNT,V_post_DATA_COUNT,null,null,null, V_TABLE_NAME );
    EXCEPTION
	     WHEN OTHERS THEN
             V_REMARKS:='Not Processed';
             SP_MIGRATION_PROCESS_LOG('INSERT_NODE', V_START_TIME, V_END_TIME,V_REF_NAME, V_REF_ID, V_PRE_DATA_COUNT,null,SQLCODE, SQLERRM, V_REMARKS,V_TABLE_NAME) ;
    END;

		--End Authority

		--###Content
		V_START_TIME:=SYSDATE;
		V_SQL:='Select long_value from alf_node_properties'||V_DB_LINK||' p
		join alf_qname'||V_DB_LINK||' q on q.id=p.qname_id
		where node_id in ('||nodeId ||') and q.local_name in (''content'',''preferenceValues'',''versionProperties'',''versionEdition'',''keyStore'')';
		EXECUTE IMMEDIATE V_SQL BULK COLLECT INTO V_LONG_VALUE;
		if V_LONG_VALUE IS NOT NULL then
			V_REF_NAME:='content_id';
			for i in 1..V_LONG_VALUE.COUNT loop
				--dbms_output.put_line(''Prcessing content_id : ''||content_id);
				V_REF_ID:=V_LONG_VALUE(i);
				BEGIN
					V_REMARKS:='Completed successfully';
				    V_SQL:='Select count(1) from ALF_CONTENT_URL'||V_DB_LINK||' a where a.id in (Select  DISTINCT content_URL_Id from ALF_CONTENT_DATA'||V_DB_LINK||' where id in ('||V_LONG_VALUE(i)||'))
				    and not EXISTS (select 1 from ALF_CONTENT_URL e where e.ID=a.ID)';
				    EXECUTE IMMEDIATE V_SQL INTO V_PRE_DATA_COUNT;
		            V_TABLE_NAME:='ALF_CONTENT_URL';
				    V_SQL:='insert into ALF_CONTENT_URL Select * from ALF_CONTENT_URL'||V_DB_LINK||' a where a.id in (Select  DISTINCT content_URL_Id from ALF_CONTENT_DATA'||V_DB_LINK||' where id in ('||V_LONG_VALUE(i)||')
				    and not EXISTS (select 1 from ALF_CONTENT_URL e where e.ID=a.ID))';
				    EXECUTE IMMEDIATE V_SQL;
				    V_SQL:='select count(1)  from ALF_CONTENT_URL a where a.id in (Select  DISTINCT content_URL_Id from ALF_CONTENT_DATA where id in ('||V_LONG_VALUE(i)||'))';
				    EXECUTE IMMEDIATE V_SQL INTO V_post_DATA_COUNT;
	                V_END_TIME:=SYSDATE;
                    SP_MIGRATION_PROCESS_LOG('INSERT_NODE', V_START_TIME, V_END_TIME,V_REF_NAME,V_REF_ID,V_PRE_DATA_COUNT,V_post_DATA_COUNT,null,null,null, V_TABLE_NAME );
                EXCEPTION
	                 WHEN OTHERS THEN
                         V_REMARKS:='Not Processed';
                         SP_MIGRATION_PROCESS_LOG('INSERT_NODE', V_START_TIME, V_END_TIME,V_REF_NAME, V_REF_ID, V_PRE_DATA_COUNT,null,SQLCODE, SQLERRM, V_REMARKS,V_TABLE_NAME) ;
                END;

				BEGIN
					V_REMARKS:='Completed successfully';
					V_START_TIME:=V_END_TIME;
       				V_SQL:='Select count(1) from ALF_CONTENT_DATA'||V_DB_LINK||' a where a.id in ('||V_LONG_VALUE(i)||')
				    and not EXISTS (select 1 from ALF_CONTENT_DATA e where e.ID=a.ID)';
				    EXECUTE IMMEDIATE V_SQL INTO V_PRE_DATA_COUNT;
		            V_TABLE_NAME:='ALF_CONTENT_DATA';
				    V_SQL:='insert into ALF_CONTENT_DATA Select * from ALF_CONTENT_DATA'||V_DB_LINK||' a where a.id in ('||V_LONG_VALUE(i)||')
				    and not EXISTS (select 1 from ALF_CONTENT_DATA e where e.ID=a.ID)';
				    EXECUTE IMMEDIATE V_SQL;
				    V_SQL:='select count(1) from ALF_CONTENT_DATA a where a.id in ('||V_LONG_VALUE(i)||')';
				    EXECUTE IMMEDIATE V_SQL INTO V_post_DATA_COUNT;
	                V_END_TIME:=SYSDATE;
                    SP_MIGRATION_PROCESS_LOG('INSERT_NODE', V_START_TIME, V_END_TIME,V_REF_NAME,V_REF_ID,V_PRE_DATA_COUNT,V_post_DATA_COUNT,null,null,null, V_TABLE_NAME );
                EXCEPTION
	                WHEN OTHERS THEN
                        V_REMARKS:='Not Processed';
                        SP_MIGRATION_PROCESS_LOG('INSERT_NODE', V_START_TIME, V_END_TIME,V_REF_NAME, V_REF_ID, V_PRE_DATA_COUNT,null,SQLCODE, SQLERRM, V_REMARKS,V_TABLE_NAME) ;
                END;

				BEGIN
					V_REMARKS:='Completed successfully';
					V_START_TIME:=V_END_TIME;
     				V_SQL:='Select count(1) from alf_audit_model'||V_DB_LINK||' a where a.CONTENT_DATA_ID in ('||V_LONG_VALUE(i)||')
				    and not EXISTS (select 1 from alf_audit_model e where e.ID=a.ID)';
				    EXECUTE IMMEDIATE V_SQL INTO V_PRE_DATA_COUNT;
		            V_TABLE_NAME:='alf_audit_model';
				    V_SQL:='insert into alf_audit_model Select * from alf_audit_model'||V_DB_LINK||' a where a.CONTENT_DATA_ID in ('||V_LONG_VALUE(i)||')
				    and not EXISTS (select 1 from alf_audit_model e where e.ID=a.ID)';
				    EXECUTE IMMEDIATE V_SQL;
				    V_SQL:='select count(1)  from alf_audit_model a where a.CONTENT_DATA_ID in ('||V_LONG_VALUE(i)||')';
				    EXECUTE IMMEDIATE V_SQL INTO V_post_DATA_COUNT;
	                V_END_TIME:=SYSDATE;
                    SP_MIGRATION_PROCESS_LOG('INSERT_NODE', V_START_TIME, V_END_TIME,V_REF_NAME,V_REF_ID,V_PRE_DATA_COUNT,V_post_DATA_COUNT,null,null,null, V_TABLE_NAME );
                EXCEPTION
	                WHEN OTHERS THEN
                        V_REMARKS:='Not Processed';
                        SP_MIGRATION_PROCESS_LOG('INSERT_NODE', V_START_TIME, V_END_TIME,V_REF_NAME, V_REF_ID, V_PRE_DATA_COUNT,null,SQLCODE, SQLERRM, V_REMARKS,V_TABLE_NAME) ;
                END;
			end loop;
		end if;
	--End content

	else null ;
	c_nodeid :=nodeId;
	end if;
	V_REF_NAME:='NODE_ID';
    V_REF_ID:=nodeId;
	V_SQL:='select local_name from alf_qname'||V_DB_LINK||' where id=(select type_qname_id from alf_node'||V_DB_LINK||' where id='||nodeId||')';
	EXECUTE IMMEDIATE V_SQL into node_type;
if(node_type='person') then

		BEGIN
			V_REMARKS:='Completed successfully';
			V_START_TIME:=V_END_TIME;
    		V_SQL:='Select count(1) from alf_auth_status'||V_DB_LINK||' a where a.username in
		    (Select p.STRING_VALUE from alf_node_properties'||V_DB_LINK||' p join alf_qname'||V_DB_LINK||' q on p.qname_id=q.id
		    where p.node_id='||nodeId||' and p.qname_id=(Select id from alf_qname'||V_DB_LINK||' where LOCAL_NAME=''userName''))
		    and not EXISTS (select 1 from alf_auth_status e where e.id=a.id)';
		     EXECUTE IMMEDIATE V_SQL INTO V_PRE_DATA_COUNT;
		     V_TABLE_NAME:='alf_auth_status';
		    V_SQL:='insert into alf_auth_status Select * from alf_auth_status'||V_DB_LINK||' a where a.username in
		    (Select p.STRING_VALUE from alf_node_properties'||V_DB_LINK||' p join alf_qname'||V_DB_LINK||' q on p.qname_id=q.id
		    where p.node_id='||nodeId||' and p.qname_id=(Select id from alf_qname'||V_DB_LINK||' where LOCAL_NAME=''userName''))
		    and not EXISTS (select 1 from alf_auth_status e where e.id=a.id)';
		    EXECUTE IMMEDIATE V_SQL;
		    V_SQL:='select count(1)  from alf_auth_status a where a.username in
            (Select p.STRING_VALUE from alf_node_properties p join alf_qname q on p.qname_id=q.id
             where p.node_id='||nodeId||' and p.qname_id=(Select id from alf_qname where LOCAL_NAME=''userName''))';
		    EXECUTE IMMEDIATE V_SQL INTO V_post_DATA_COUNT;
	        V_END_TIME:=SYSDATE;
            SP_MIGRATION_PROCESS_LOG('INSERT_NODE', V_START_TIME, V_END_TIME,V_REF_NAME,V_REF_ID,V_PRE_DATA_COUNT,V_post_DATA_COUNT,null,null,null, V_TABLE_NAME );
        EXCEPTION
	        WHEN OTHERS THEN
                V_REMARKS:='Not Processed';
                SP_MIGRATION_PROCESS_LOG('INSERT_NODE', V_START_TIME, V_END_TIME,V_REF_NAME, V_REF_ID, V_PRE_DATA_COUNT,null,SQLCODE, SQLERRM, V_REMARKS,V_TABLE_NAME) ;
        END;

		    --Associte to all the parents
		BEGIN
			V_REMARKS:='Completed successfully';
			V_START_TIME:=V_END_TIME;
		    V_SQL:='Select count(1) from  (Select ch.* from alf_child_assoc'||V_DB_LINK||' ch  START WITH  ch.child_node_id ='||nodeId||'
		    and ch.parent_node_id in (Select id from tmp_alf_ids'||V_DB_LINK||' where protocol=''workspace'' and IDENTIFIER=''SpacesStore''
		    and path in (''/system/zones/AUTH.ALF'',''/system/zones/APP.DEFAULT'',''/system/authorities''))
		    CONNECT BY  ch.child_node_id = PRIOR ch.parent_node_id and LEVEL <2) a
		    where not EXISTS (select 1 from alf_child_assoc e where e.id=a.id)';
		    EXECUTE IMMEDIATE V_SQL INTO V_PRE_DATA_COUNT;
		    V_TABLE_NAME:='alf_child_assoc';
		    V_SQL:='insert into alf_child_assoc Select * from  (Select ch.* from alf_child_assoc'||V_DB_LINK||' ch  START WITH  ch.child_node_id ='||nodeId||'
		    and ch.parent_node_id in (Select id from tmp_alf_ids'||V_DB_LINK||' where protocol=''workspace'' and IDENTIFIER=''SpacesStore''
		    and path in (''/system/zones/AUTH.ALF'',''/system/zones/APP.DEFAULT'',''/system/authorities''))
		    CONNECT BY  ch.child_node_id = PRIOR ch.parent_node_id and LEVEL <2) a
		    where not EXISTS (select 1 from alf_child_assoc e where e.id=a.id)';
		    EXECUTE IMMEDIATE V_SQL;
            V_SQL:='select count(1)  from  (Select ch.* from alf_child_assoc ch  START WITH  ch.child_node_id ='||nodeId||'
            and ch.parent_node_id in (Select id from tmp_alf_ids where protocol=''workspace'' and IDENTIFIER=''SpacesStore''
            and path in (''/system/zones/AUTH.ALF'',''/system/zones/APP.DEFAULT'',''/system/authorities''))
            CONNECT BY  ch.child_node_id = PRIOR ch.parent_node_id and LEVEL <2) a ';
		    EXECUTE IMMEDIATE V_SQL INTO V_post_DATA_COUNT;
	        V_END_TIME:=SYSDATE;
            SP_MIGRATION_PROCESS_LOG('INSERT_NODE', V_START_TIME, V_END_TIME,V_REF_NAME,V_REF_ID,V_PRE_DATA_COUNT,V_post_DATA_COUNT,null,null,null, V_TABLE_NAME );
        EXCEPTION
	        WHEN OTHERS THEN
                V_REMARKS:='Not Processed';
                SP_MIGRATION_PROCESS_LOG('INSERT_NODE', V_START_TIME, V_END_TIME,V_REF_NAME, V_REF_ID, V_PRE_DATA_COUNT,null,SQLCODE, SQLERRM, V_REMARKS,V_TABLE_NAME) ;
        END;


            V_SQL:='Select id from tmp_alf_ids'||V_DB_LINK||' where protocol=''workspace'' and IDENTIFIER=''SpacesStore''
		    and path in (''/company_home/user_homes'')';
		    EXECUTE IMMEDIATE V_SQL into user_homes_id;
		    V_SQL:='Select id from tmp_alf_ids'||V_DB_LINK||' where protocol=''user'' and IDENTIFIER=''alfrescoUserStore''
		    and path in (''/system/people'')';
		    EXECUTE IMMEDIATE V_SQL into people_id;
		    V_SQL:='Select p.STRING_VALUE from alf_node_properties'||V_DB_LINK||' p join alf_qname'||V_DB_LINK||' q on q.id=p.qname_id
		    where node_id in ('||nodeId ||') and q.local_name in (''userName'')';
		    EXECUTE IMMEDIATE V_SQL into v_trans_id;
		    --Associate to System User and User home folder
		    V_SQL:='Select case when q.local_name=''username'' then '||people_id ||' when q.local_name=''name'' then '||user_homes_id ||' end PARENT_NODE_ID,p.node_id CHILD_NODE_ID
		    from alf_node_properties'||V_DB_LINK||' p join alf_qname'||V_DB_LINK||' q on q.id=p.qname_id where p.STRING_VALUE in ('''||v_trans_id||''') and q.local_name in (''name'',''username'')';
		    EXECUTE IMMEDIATE V_SQL BULK COLLECT INTO v_parent_node_id,v_child_node_id;
		    begin
		    		for i in 1..v_child_node_id.COUNT loop
		    			--t_num :=t_num+1;
		    			INSERT_NODE(v_child_node_id(i),v_parent_node_id(i),'systemUser',Childcascade);
		    		--if MOD(t_num,100)=0 then COMMIT; end if;
		    		end loop;
		    	COMMIT;
		    	--	dbms_output.put_line('Processing Completed for system And committed record count for c1: '||t_num );
		    	end;
elsif(node_type='authorityContainer') then

	BEGIN
		V_REMARKS:='Completed successfully';
		V_START_TIME:=sysdate;
	    V_SQL:=' Select COUNT(1) from ALF_AUTHORITY'||V_DB_LINK||' a where authority in
		(Select p.STRING_VALUE  from alf_node_properties'||V_DB_LINK||' p join alf_qname'||V_DB_LINK||' q on p.qname_id=q.id
		where p.node_id='||nodeId||' and p.qname_id=(Select id from alf_qname'||V_DB_LINK||' where LOCAL_NAME=''authorityName''))
		and not EXISTS (select 1 from ALF_AUTHORITY e where e.id=a.id)';
		EXECUTE IMMEDIATE V_SQL INTO V_PRE_DATA_COUNT;
		V_TABLE_NAME:='ALF_AUTHORITY';
    	V_SQL:='insert into ALF_AUTHORITY Select * from ALF_AUTHORITY'||V_DB_LINK||' a where authority in
		(Select p.STRING_VALUE  from alf_node_properties'||V_DB_LINK||' p join alf_qname'||V_DB_LINK||' q on p.qname_id=q.id
		where p.node_id='||nodeId||' and p.qname_id=(Select id from alf_qname'||V_DB_LINK||' where LOCAL_NAME=''authorityName''))
		and not EXISTS (select 1 from ALF_AUTHORITY e where e.id=a.id)';
		EXECUTE IMMEDIATE V_SQL;
		V_SQL:='select count(1) from ALF_AUTHORITY a where authority in
        (Select p.STRING_VALUE  from alf_node_properties p join alf_qname q on p.qname_id=q.id
        where p.node_id='||nodeId||' and p.qname_id=(Select id from alf_qname where LOCAL_NAME=''authorityName''))';
		EXECUTE IMMEDIATE V_SQL INTO V_post_DATA_COUNT;
	    V_END_TIME:=SYSDATE;
        SP_MIGRATION_PROCESS_LOG('INSERT_NODE', V_START_TIME, V_END_TIME,V_REF_NAME,V_REF_ID,V_PRE_DATA_COUNT,V_post_DATA_COUNT,null,null,null, V_TABLE_NAME );
    EXCEPTION
	    WHEN OTHERS THEN
            V_REMARKS:='Not Processed';
            SP_MIGRATION_PROCESS_LOG('INSERT_NODE', V_START_TIME, V_END_TIME,V_REF_NAME, V_REF_ID, V_PRE_DATA_COUNT,null,SQLCODE, SQLERRM, V_REMARKS,V_TABLE_NAME) ;
    END;

	BEGIN
		V_REMARKS:='Completed successfully';
		V_START_TIME:=V_END_TIME;
	    V_SQL:='Select COUNT(1) from (Select ch.* from alf_child_assoc'||V_DB_LINK||' ch  START WITH  ch.child_node_id ='||nodeId||'
		and ch.parent_node_id in (Select id from tmp_alf_ids'||V_DB_LINK||' where protocol=''workspace'' and IDENTIFIER=''SpacesStore''
		and path in (''/system/zones/AUTH.ALF'',''/system/zones/APP.DEFAULT'',''/system/authorities''))
		CONNECT BY  ch.child_node_id = PRIOR ch.parent_node_id and LEVEL <2) a
		where not EXISTS (select 1 from alf_child_assoc e where e.id=a.id)';
		EXECUTE IMMEDIATE V_SQL INTO V_PRE_DATA_COUNT;
		V_TABLE_NAME:='alf_child_assoc';
		V_SQL:='insert into alf_child_assoc Select * from (Select ch.* from alf_child_assoc'||V_DB_LINK||' ch  START WITH  ch.child_node_id ='||nodeId||'
		and ch.parent_node_id in (Select id from tmp_alf_ids'||V_DB_LINK||' where protocol=''workspace'' and IDENTIFIER=''SpacesStore''
		and path in (''/system/zones/AUTH.ALF'',''/system/zones/APP.DEFAULT'',''/system/authorities''))
		CONNECT BY  ch.child_node_id = PRIOR ch.parent_node_id and LEVEL <2) a
		where not EXISTS (select 1 from alf_child_assoc e where e.id=a.id)';
		EXECUTE IMMEDIATE V_SQL;
		V_SQL:='select count(1)  from (Select ch.* from alf_child_assoc ch  START WITH  ch.child_node_id ='||nodeId||'
        and ch.parent_node_id in (Select id from tmp_alf_ids where protocol=''workspace'' and IDENTIFIER=''SpacesStore''
        and path in (''/system/zones/AUTH.ALF'',''/system/zones/APP.DEFAULT'',''/system/authorities''))
        CONNECT BY  ch.child_node_id = PRIOR ch.parent_node_id and LEVEL <2) a ';
		EXECUTE IMMEDIATE V_SQL INTO V_post_DATA_COUNT;
	    V_END_TIME:=SYSDATE;
        SP_MIGRATION_PROCESS_LOG('INSERT_NODE', V_START_TIME, V_END_TIME,V_REF_NAME,V_REF_ID,V_PRE_DATA_COUNT,V_post_DATA_COUNT,null,null,null, V_TABLE_NAME );
    EXCEPTION
	    WHEN OTHERS THEN
            V_REMARKS:='Not Processed';
            SP_MIGRATION_PROCESS_LOG('INSERT_NODE', V_START_TIME, V_END_TIME,V_REF_NAME, V_REF_ID, V_PRE_DATA_COUNT,null,SQLCODE, SQLERRM, V_REMARKS,V_TABLE_NAME) ;
    END;
end if;


    BEGIN
	    V_REMARKS:='Completed successfully';
		V_START_TIME:=V_END_TIME;
		V_SQL:=' Select COUNT(1) from alf_child_assoc'||V_DB_LINK||' a where (a.child_node_id in ('||nodeId ||') and a.PARENT_NODE_ID in ('||parentNodeId||'))
		and not EXISTS (select 1 from alf_child_assoc e where e.id=a.id)';
		EXECUTE IMMEDIATE V_SQL INTO V_PRE_DATA_COUNT;
		V_TABLE_NAME:='alf_child_assoc';
		V_SQL:='insert into alf_child_assoc Select * from alf_child_assoc'||V_DB_LINK||' a where (a.child_node_id in ('||nodeId ||') and a.PARENT_NODE_ID in ('||parentNodeId||'))
		and not EXISTS (select 1 from alf_child_assoc e where e.id=a.id)';
		EXECUTE IMMEDIATE V_SQL;
		V_SQL:='select count(1)  from alf_child_assoc a where (a.child_node_id in ('||nodeId ||') and a.PARENT_NODE_ID in  ('||parentNodeId||'))';
		EXECUTE IMMEDIATE V_SQL INTO V_post_DATA_COUNT;
		V_END_TIME:=SYSDATE;
		SP_MIGRATION_PROCESS_LOG('INSERT_NODE', V_START_TIME, V_END_TIME,V_REF_NAME,V_REF_ID,V_PRE_DATA_COUNT,V_post_DATA_COUNT,null,null,null, V_TABLE_NAME );
    EXCEPTION
	    WHEN OTHERS THEN
            V_REMARKS:='Not Processed';
            SP_MIGRATION_PROCESS_LOG('INSERT_NODE', V_START_TIME, V_END_TIME,V_REF_NAME, V_REF_ID, V_PRE_DATA_COUNT,null,SQLCODE, SQLERRM, V_REMARKS,V_TABLE_NAME) ;
    END;


	--Sub Child
	if Childcascade='true' then
		V_SQL:='select parent_node_id, child_node_id from (Select LEVEL,ch.* from alf_child_assoc'||V_DB_LINK||' ch  START WITH  ch.parent_node_id ='||nodeId||'
		CONNECT BY PRIOR  ch.child_node_id = ch.parent_node_id
		ORDER BY 1,parent_node_id,child_node_id asc)';
		EXECUTE IMMEDIATE V_SQL BULK COLLECT INTO v_sc_parent_node_id,v_sc_child_node_id;
		begin
			for i in 1..v_sc_child_node_id.COUNT loop
				--t_num :=t_num+1;
				INSERT_NODE(v_sc_child_node_id(i),v_sc_parent_node_id(i),'subchild','false');
				--if MOD(t_num,100)=0 then COMMIT; end if;
			end loop;
		end;
		COMMIT;
	end if;
	close c1;
	COMMIT;
EXCEPTION
    WHEN OTHERS THEN
	SP_MIGRATION_PROCESS_LOG('INSERT_NODE', NULL, NULL,NULL, NULL, NULL,NULL, SQLCODE, SQLERRM, V_REMARKS, NULL) ;

END INSERT_NODE;


PROCEDURE INSERT_WF(PROC_DEF_ID VARCHAR2) AS
    V_START_TIME DATE;
	V_END_TIME DATE;
	V_REF_NAME VARCHAR2(100 CHAR);
	V_REF_ID NUMBER(38,0);
	V_TABLE_NAME VARCHAR2(100 CHAR);
	V_PRE_DATA_COUNT NUMBER(38,0);
	V_POST_DATA_COUNT NUMBER(38,0);
	V_REMARKS VARCHAR2(100 CHAR);
	V_SQL CLOB;
BEGIN

	V_START_TIME:=SYSDATE;
    V_REF_NAME:='PROC_DEF_ID';
    V_REF_ID:=PROC_DEF_ID;
    V_REMARKS:='Completed successfully';
	----------Workflow insert steps
	BEGIN
		V_SQL:='Select count (1) from act_re_deployment'||V_DB_LINK||' a where a.id_ in (select DEPLOYMENT_ID_ from ACT_RE_PROCDEF'||V_DB_LINK||'  where id_ in (select PROC_DEF_ID_ from ACT_HI_PROCINST'||V_DB_LINK||' where Id_='||PROC_DEF_ID||'))
		and not EXISTS (select * from act_re_deployment e where e.id_=a.id_)';
		EXECUTE IMMEDIATE V_SQL INTO V_PRE_DATA_COUNT;
		V_TABLE_NAME:='ACT_RE_DEPLOYMENT';
		V_SQL:='Insert into act_re_deployment
		Select * from act_re_deployment'||V_DB_LINK||' a where a.id_ in (select DEPLOYMENT_ID_ from ACT_RE_PROCDEF'||V_DB_LINK||'  where id_ in (select PROC_DEF_ID_ from ACT_HI_PROCINST'||V_DB_LINK||' where Id_='||PROC_DEF_ID||'))
		and not EXISTS (select * from act_re_deployment e where e.id_=a.id_)';
		EXECUTE IMMEDIATE V_SQL;
		V_SQL:='Select count (1) from act_re_deployment a where a.id_ in (select DEPLOYMENT_ID_ from ACT_RE_PROCDEF  where id_ in (select PROC_DEF_ID_ from ACT_HI_PROCINST where Id_='||PROC_DEF_ID||'))';
		EXECUTE IMMEDIATE V_SQL INTO V_POST_DATA_COUNT;
		V_END_TIME:=SYSDATE;
			SP_MIGRATION_PROCESS_LOG('INSERT_WF', V_START_TIME, V_END_TIME,V_REF_NAME, V_REF_ID, V_PRE_DATA_COUNT, V_POST_DATA_COUNT,NULL,NULL,NULL, V_TABLE_NAME);
	EXCEPTION
		WHEN OTHERS THEN
			V_REMARKS:='Not Processed';
			SP_MIGRATION_PROCESS_LOG('INSERT_WF', V_START_TIME, V_END_TIME,V_REF_NAME, V_REF_ID, V_PRE_DATA_COUNT,NULL, SQLCODE, SQLERRM, V_REMARKS, V_TABLE_NAME) ;
    END;


	BEGIN
		V_REMARKS:='Completed successfully';
		V_START_TIME:=V_END_TIME;
		V_SQL:='Select count (1) from ACT_GE_BYTEARRAY'||V_DB_LINK||' a where a.deployment_id_ in (select DEPLOYMENT_ID_ from ACT_RE_PROCDEF'||V_DB_LINK||'  where id_ in (select PROC_DEF_ID_ from ACT_HI_PROCINST'||V_DB_LINK||' where Id_='||PROC_DEF_ID||'))
		and not EXISTS (select * from ACT_GE_BYTEARRAY e where e.id_=a.id_)';
		EXECUTE IMMEDIATE V_SQL INTO V_PRE_DATA_COUNT;
		V_TABLE_NAME:='ACT_GE_BYTEARRAY';
		V_SQL:='Insert into ACT_GE_BYTEARRAY
		Select * from ACT_GE_BYTEARRAY'||V_DB_LINK||' a where a.deployment_id_ in (select DEPLOYMENT_ID_ from ACT_RE_PROCDEF'||V_DB_LINK||'  where id_ in (select PROC_DEF_ID_ from ACT_HI_PROCINST'||V_DB_LINK||' where Id_='||PROC_DEF_ID||'))
		and not EXISTS (select * from ACT_GE_BYTEARRAY e where e.id_=a.id_)';
		EXECUTE IMMEDIATE V_SQL;
		V_SQL:='Select count (1) from ACT_GE_BYTEARRAY a where a.deployment_id_ in (select DEPLOYMENT_ID_ from ACT_RE_PROCDEF  where id_ in (select PROC_DEF_ID_ from ACT_HI_PROCINST where Id_='||PROC_DEF_ID||'))';
		EXECUTE IMMEDIATE V_SQL INTO V_POST_DATA_COUNT;
		V_END_TIME:=SYSDATE;
			SP_MIGRATION_PROCESS_LOG('INSERT_WF', V_START_TIME, V_END_TIME,V_REF_NAME, V_REF_ID, V_PRE_DATA_COUNT, V_POST_DATA_COUNT,NULL,NULL,NULL, V_TABLE_NAME);
	EXCEPTION
		WHEN OTHERS THEN
			V_REMARKS:='Not Processed';
			SP_MIGRATION_PROCESS_LOG('INSERT_WF', V_START_TIME, V_END_TIME,V_REF_NAME, V_REF_ID, V_PRE_DATA_COUNT,NULL, SQLCODE, SQLERRM, V_REMARKS, V_TABLE_NAME) ;
    END;

	BEGIN
		V_REMARKS:='Completed successfully';
		V_START_TIME:=V_END_TIME;
		V_SQL:='select count (1) from ACT_RE_PROCDEF'||V_DB_LINK||' a  where a.id_ in (select PROC_DEF_ID_ from ACT_HI_PROCINST'||V_DB_LINK||' where Id_='||PROC_DEF_ID||') and not EXISTS (select * from ACT_RE_PROCDEF e where e.id_=a.id_)';
		EXECUTE IMMEDIATE V_SQL INTO V_PRE_DATA_COUNT;
		V_TABLE_NAME:='ACT_RE_PROCDEF';
		V_SQL:='Insert into ACT_RE_PROCDEF
		select * from ACT_RE_PROCDEF'||V_DB_LINK||' a  where a.id_ in (select PROC_DEF_ID_ from ACT_HI_PROCINST'||V_DB_LINK||' where Id_='||PROC_DEF_ID||') and not EXISTS (select * from ACT_RE_PROCDEF e where e.id_=a.id_)';
		EXECUTE IMMEDIATE V_SQL;
		V_SQL:='select count (1) from ACT_RE_PROCDEF a  where a.id_ in (select PROC_DEF_ID_ from ACT_HI_PROCINST where Id_='||PROC_DEF_ID||')';
		EXECUTE IMMEDIATE V_SQL INTO V_POST_DATA_COUNT;
		V_END_TIME:=SYSDATE;
			SP_MIGRATION_PROCESS_LOG('INSERT_WF', V_START_TIME, V_END_TIME,V_REF_NAME, V_REF_ID, V_PRE_DATA_COUNT, V_POST_DATA_COUNT,NULL,NULL,NULL, V_TABLE_NAME);
	EXCEPTION
		WHEN OTHERS THEN
			V_REMARKS:='Not Processed';
			SP_MIGRATION_PROCESS_LOG('INSERT_WF', V_START_TIME, V_END_TIME,V_REF_NAME, V_REF_ID, V_PRE_DATA_COUNT,NULL, SQLCODE, SQLERRM, V_REMARKS, V_TABLE_NAME) ;
	END;

	BEGIN
		V_REMARKS:='Completed successfully';
		V_START_TIME:=V_END_TIME;
		V_SQL:='select count (1) from ACT_HI_PROCINST'||V_DB_LINK||' a  where a.Id_='||PROC_DEF_ID||'
		and not EXISTS (select * from ACT_HI_PROCINST e where e.id_=a.id_)';
		EXECUTE IMMEDIATE V_SQL INTO V_PRE_DATA_COUNT;
		V_TABLE_NAME:='ACT_HI_PROCINST';
		V_SQL:='Insert into ACT_HI_PROCINST
		select * from ACT_HI_PROCINST'||V_DB_LINK||' a  where a.Id_='||PROC_DEF_ID||'
		and not EXISTS (select * from ACT_HI_PROCINST e where e.id_=a.id_)';
		EXECUTE IMMEDIATE V_SQL;
		V_SQL:='select count (1) from ACT_HI_PROCINST a  where a.Id_='||PROC_DEF_ID||'';
		EXECUTE IMMEDIATE V_SQL INTO V_POST_DATA_COUNT;
		V_END_TIME:=SYSDATE;
			SP_MIGRATION_PROCESS_LOG('INSERT_WF', V_START_TIME, V_END_TIME,V_REF_NAME, V_REF_ID, V_PRE_DATA_COUNT, V_POST_DATA_COUNT,NULL,NULL,NULL, V_TABLE_NAME);
	EXCEPTION
		WHEN OTHERS THEN
			V_REMARKS:='Not Processed';
			SP_MIGRATION_PROCESS_LOG('INSERT_WF', V_START_TIME, V_END_TIME,V_REF_NAME, V_REF_ID, V_PRE_DATA_COUNT,NULL, SQLCODE, SQLERRM, V_REMARKS, V_TABLE_NAME) ;
	END;

	--V_SQL:='Insert into ACT_RU_EXECUTION
	--Select * from ACT_RU_EXECUTION'||V_DB_LINK||' a where PROC_INST_ID_='||PROC_DEF_ID||'
	--and not EXISTS (select * from ACT_RU_EXECUTION e where e.id_=a.id_);
	BEGIN
		V_REMARKS:='Completed successfully';
		V_START_TIME:=V_END_TIME;
		V_SQL:='SElect count (1) from (Select * from act_ru_execution'||V_DB_LINK||' re start with
		re.proc_inst_id_='||PROC_DEF_ID||' connect by nocycle re.ID_= prior re.SUPER_EXEC_
		order by 1) a where not EXISTS (select * from ACT_RU_EXECUTION e where e.id_=a.id_)';
		EXECUTE IMMEDIATE V_SQL INTO V_PRE_DATA_COUNT;
		V_TABLE_NAME:='ACT_RU_EXECUTION';
		V_SQL:='Insert into ACT_RU_EXECUTION
		SElect * from (Select * from act_ru_execution'||V_DB_LINK||' re start with
		re.proc_inst_id_='||PROC_DEF_ID||' connect by nocycle re.ID_= prior re.SUPER_EXEC_
		order by 1) a where not EXISTS (select * from ACT_RU_EXECUTION e where e.id_=a.id_)';
		EXECUTE IMMEDIATE V_SQL;
		V_SQL:='SElect count (1) from (Select * from act_ru_execution re start with
		re.proc_inst_id_='||PROC_DEF_ID||' connect by nocycle re.ID_= prior re.SUPER_EXEC_ order by 1) a';
		EXECUTE IMMEDIATE V_SQL INTO V_POST_DATA_COUNT;
		V_END_TIME:=SYSDATE;
			SP_MIGRATION_PROCESS_LOG('INSERT_WF', V_START_TIME, V_END_TIME,V_REF_NAME, V_REF_ID, V_PRE_DATA_COUNT, V_POST_DATA_COUNT,NULL,NULL,NULL, V_TABLE_NAME);
	EXCEPTION
		WHEN OTHERS THEN
			V_REMARKS:='Not Processed';
			SP_MIGRATION_PROCESS_LOG('INSERT_WF', V_START_TIME, V_END_TIME,V_REF_NAME, V_REF_ID, V_PRE_DATA_COUNT,NULL, SQLCODE, SQLERRM, V_REMARKS, V_TABLE_NAME) ;
	END;

	BEGIN
		V_REMARKS:='Completed successfully';
		V_START_TIME:=V_END_TIME;
		V_SQL:='Select count (1) from ACT_HI_TASKINST'||V_DB_LINK||' a where a.proc_inst_id_ in ('||PROC_DEF_ID||')
		and not EXISTS (select * from ACT_HI_TASKINST e where e.id_=a.id_)';
		EXECUTE IMMEDIATE V_SQL INTO V_PRE_DATA_COUNT;
		V_TABLE_NAME:='ACT_HI_TASKINST';
		V_SQL:='Insert into ACT_HI_TASKINST
		Select * from ACT_HI_TASKINST'||V_DB_LINK||' a where a.proc_inst_id_ in ('||PROC_DEF_ID||')
		and not EXISTS (select * from ACT_HI_TASKINST e where e.id_=a.id_)';
		EXECUTE IMMEDIATE V_SQL;
		V_SQL:='Select count (1) from ACT_HI_TASKINST a where a.proc_inst_id_ in ('||PROC_DEF_ID||')';
		EXECUTE IMMEDIATE V_SQL INTO V_POST_DATA_COUNT;
		V_END_TIME:=SYSDATE;
			SP_MIGRATION_PROCESS_LOG('INSERT_WF', V_START_TIME, V_END_TIME,V_REF_NAME, V_REF_ID, V_PRE_DATA_COUNT, V_POST_DATA_COUNT,NULL,NULL,NULL, V_TABLE_NAME);
	EXCEPTION
		WHEN OTHERS THEN
			V_REMARKS:='Not Processed';
			SP_MIGRATION_PROCESS_LOG('INSERT_WF', V_START_TIME, V_END_TIME,V_REF_NAME, V_REF_ID, V_PRE_DATA_COUNT,NULL, SQLCODE, SQLERRM, V_REMARKS, V_TABLE_NAME) ;
	END;


	BEGIN
		V_REMARKS:='Completed successfully';
		V_START_TIME:=V_END_TIME;
		V_SQL:='Select count (1) from ACT_RU_TASK'||V_DB_LINK||' a where a.proc_inst_id_ in ('||PROC_DEF_ID||')
		and not EXISTS (select * from ACT_RU_TASK e where e.id_=a.id_)';
		EXECUTE IMMEDIATE V_SQL INTO V_PRE_DATA_COUNT;
		V_TABLE_NAME:='ACT_RU_TASK';
		V_SQL:='Insert into ACT_RU_TASK
		Select * from ACT_RU_TASK'||V_DB_LINK||' a where a.proc_inst_id_ in ('||PROC_DEF_ID||')
		and not EXISTS (select * from ACT_RU_TASK e where e.id_=a.id_)';
		EXECUTE IMMEDIATE V_SQL;
		V_SQL:='Select count (1) from ACT_RU_TASK a where a.proc_inst_id_ in ('||PROC_DEF_ID||')';
		EXECUTE IMMEDIATE V_SQL INTO V_POST_DATA_COUNT;
		V_END_TIME:=SYSDATE;
			SP_MIGRATION_PROCESS_LOG('INSERT_WF', V_START_TIME, V_END_TIME,V_REF_NAME, V_REF_ID, V_PRE_DATA_COUNT, V_POST_DATA_COUNT,NULL,NULL,NULL, V_TABLE_NAME);
	EXCEPTION
		WHEN OTHERS THEN
			V_REMARKS:='Not Processed';
			SP_MIGRATION_PROCESS_LOG('INSERT_WF', V_START_TIME, V_END_TIME,V_REF_NAME, V_REF_ID, V_PRE_DATA_COUNT,NULL, SQLCODE, SQLERRM, V_REMARKS, V_TABLE_NAME) ;
	END;

	BEGIN
		V_REMARKS:='Completed successfully';
		V_START_TIME:=V_END_TIME;
		V_SQL:='Select count (1) from ACT_HI_COMMENT'||V_DB_LINK||' a where a.task_id_ in (Select id_ from ACT_RU_TASK where proc_inst_id_ in ('||PROC_DEF_ID||'))
		and not EXISTS (select * from ACT_HI_COMMENT e where e.id_=a.id_)';
		EXECUTE IMMEDIATE V_SQL INTO V_PRE_DATA_COUNT;
		V_TABLE_NAME:='ACT_HI_COMMENT';
		V_SQL:='Insert into ACT_HI_COMMENT
		Select * from ACT_HI_COMMENT'||V_DB_LINK||' a where a.task_id_ in (Select id_ from ACT_RU_TASK where proc_inst_id_ in ('||PROC_DEF_ID||'))
		and not EXISTS (select * from ACT_HI_COMMENT e where e.id_=a.id_)';
		EXECUTE IMMEDIATE V_SQL;
		V_SQL:='Select count (1) from ACT_HI_COMMENT a where a.task_id_ in (Select id_ from ACT_RU_TASK where proc_inst_id_ in ('||PROC_DEF_ID||'))';
		EXECUTE IMMEDIATE V_SQL INTO V_POST_DATA_COUNT;
		V_END_TIME:=SYSDATE;
			SP_MIGRATION_PROCESS_LOG('INSERT_WF', V_START_TIME, V_END_TIME,V_REF_NAME, V_REF_ID, V_PRE_DATA_COUNT, V_POST_DATA_COUNT,NULL,NULL,NULL, V_TABLE_NAME);
	EXCEPTION
		WHEN OTHERS THEN
			V_REMARKS:='Not Processed';
			SP_MIGRATION_PROCESS_LOG('INSERT_WF', V_START_TIME, V_END_TIME,V_REF_NAME, V_REF_ID, V_PRE_DATA_COUNT,NULL, SQLCODE, SQLERRM, V_REMARKS, V_TABLE_NAME) ;
	END;

	BEGIN
		V_REMARKS:='Completed successfully';
		V_START_TIME:=V_END_TIME;
		V_SQL:='Select count (1) from ACT_RU_JOB'||V_DB_LINK||' a where a.execution_id_ in (Select id_ from ACT_RU_EXECUTION where PROC_INST_ID_='||PROC_DEF_ID||')
		and not EXISTS (select * from ACT_RU_JOB e where e.id_=a.id_)';
		EXECUTE IMMEDIATE V_SQL INTO V_PRE_DATA_COUNT;
		V_TABLE_NAME:='ACT_RU_JOB';
		V_SQL:='Insert into ACT_RU_JOB
		Select * from ACT_RU_JOB'||V_DB_LINK||' a where a.execution_id_ in (Select id_ from ACT_RU_EXECUTION where PROC_INST_ID_='||PROC_DEF_ID||')
		and not EXISTS (select * from ACT_RU_JOB e where e.id_=a.id_)';
		EXECUTE IMMEDIATE V_SQL;
		V_SQL:='Select count (1) from ACT_RU_JOB a where a.execution_id_ in (Select id_ from ACT_RU_EXECUTION where PROC_INST_ID_='||PROC_DEF_ID||')';
		EXECUTE IMMEDIATE V_SQL INTO V_POST_DATA_COUNT;
		V_END_TIME:=SYSDATE;
			SP_MIGRATION_PROCESS_LOG('INSERT_WF', V_START_TIME, V_END_TIME,V_REF_NAME, V_REF_ID, V_PRE_DATA_COUNT, V_POST_DATA_COUNT,NULL,NULL,NULL, V_TABLE_NAME);
	EXCEPTION
		WHEN OTHERS THEN
			V_REMARKS:='Not Processed';
			SP_MIGRATION_PROCESS_LOG('INSERT_WF', V_START_TIME, V_END_TIME,V_REF_NAME, V_REF_ID, V_PRE_DATA_COUNT,NULL, SQLCODE, SQLERRM, V_REMARKS, V_TABLE_NAME) ;
	END;

	BEGIN
		V_REMARKS:='Completed successfully';
		V_START_TIME:=V_END_TIME;
		V_SQL:='Select count (1) from ACT_HI_ACTINST'||V_DB_LINK||' a where a.proc_inst_id_ in ('||PROC_DEF_ID||')
		and not EXISTS (select * from ACT_HI_ACTINST e where e.id_=a.id_)';
		EXECUTE IMMEDIATE V_SQL INTO V_PRE_DATA_COUNT;
		V_TABLE_NAME:='ACT_HI_ACTINST';
		V_SQL:='Insert into ACT_HI_ACTINST
		Select * from ACT_HI_ACTINST'||V_DB_LINK||' a where a.proc_inst_id_ in ('||PROC_DEF_ID||')
		and not EXISTS (select * from ACT_HI_ACTINST e where e.id_=a.id_)';
		EXECUTE IMMEDIATE V_SQL;
		V_SQL:='Select count (1) from ACT_HI_ACTINST a where a.proc_inst_id_ in ('||PROC_DEF_ID||')';
		EXECUTE IMMEDIATE V_SQL INTO V_POST_DATA_COUNT;
		V_END_TIME:=SYSDATE;
			SP_MIGRATION_PROCESS_LOG('INSERT_WF', V_START_TIME, V_END_TIME,V_REF_NAME, V_REF_ID, V_PRE_DATA_COUNT, V_POST_DATA_COUNT,NULL,NULL,NULL, V_TABLE_NAME);
	EXCEPTION
		WHEN OTHERS THEN
			V_REMARKS:='Not Processed';
			SP_MIGRATION_PROCESS_LOG('INSERT_WF', V_START_TIME, V_END_TIME,V_REF_NAME, V_REF_ID, V_PRE_DATA_COUNT,NULL, SQLCODE, SQLERRM, V_REMARKS, V_TABLE_NAME) ;
	END;

	BEGIN
		V_REMARKS:='Completed successfully';
		V_START_TIME:=V_END_TIME;
		V_SQL:='Select count (1) from ACT_GE_BYTEARRAY'||V_DB_LINK||' a where a.ID_ in (
		Select BYTEARRAY_ID_ from ACT_RU_VARIABLE'||V_DB_LINK||' where proc_inst_id_ in ('||PROC_DEF_ID||') and  BYTEARRAY_ID_ is not null
		UNION
		Select BYTEARRAY_ID_ from ACT_HI_VARINST'||V_DB_LINK||' where proc_inst_id_ in ('||PROC_DEF_ID||') and  BYTEARRAY_ID_ is not null
		UNION
		Select BYTEARRAY_ID_ from ACT_HI_DETAIL'||V_DB_LINK||' where proc_inst_id_ in ('||PROC_DEF_ID||') and  BYTEARRAY_ID_ is not null)
		and not EXISTS (select * from ACT_GE_BYTEARRAY e where e.id_=a.id_)';
		EXECUTE IMMEDIATE V_SQL INTO V_PRE_DATA_COUNT;
		V_TABLE_NAME:='ACT_GE_BYTEARRAY';
		V_SQL:='Insert into ACT_GE_BYTEARRAY
		Select * from ACT_GE_BYTEARRAY'||V_DB_LINK||' a where a.ID_ in (
		Select BYTEARRAY_ID_ from ACT_RU_VARIABLE'||V_DB_LINK||' where proc_inst_id_ in ('||PROC_DEF_ID||') and  BYTEARRAY_ID_ is not null
		UNION
		Select BYTEARRAY_ID_ from ACT_HI_VARINST'||V_DB_LINK||' where proc_inst_id_ in ('||PROC_DEF_ID||') and  BYTEARRAY_ID_ is not null
		UNION
		Select BYTEARRAY_ID_ from ACT_HI_DETAIL'||V_DB_LINK||' where proc_inst_id_ in ('||PROC_DEF_ID||') and  BYTEARRAY_ID_ is not null)
		and not EXISTS (select * from ACT_GE_BYTEARRAY e where e.id_=a.id_)';
		EXECUTE IMMEDIATE V_SQL;
		V_SQL:='Select count (1) from ACT_GE_BYTEARRAY a where a.ID_ in (
		Select BYTEARRAY_ID_ from ACT_RU_VARIABLE where proc_inst_id_ in ('||PROC_DEF_ID||') and  BYTEARRAY_ID_ is not null
		UNION
		Select BYTEARRAY_ID_ from ACT_HI_VARINST where proc_inst_id_ in ('||PROC_DEF_ID||') and  BYTEARRAY_ID_ is not null
		UNION
		Select BYTEARRAY_ID_ from ACT_HI_DETAIL where proc_inst_id_ in ('||PROC_DEF_ID||') and  BYTEARRAY_ID_ is not null)';
		EXECUTE IMMEDIATE V_SQL INTO V_POST_DATA_COUNT;
		V_END_TIME:=SYSDATE;
			SP_MIGRATION_PROCESS_LOG('INSERT_WF', V_START_TIME, V_END_TIME,V_REF_NAME, V_REF_ID, V_PRE_DATA_COUNT, V_POST_DATA_COUNT,NULL,NULL,NULL, V_TABLE_NAME);
	EXCEPTION
		WHEN OTHERS THEN
			V_REMARKS:='Not Processed';
			SP_MIGRATION_PROCESS_LOG('INSERT_WF', V_START_TIME, V_END_TIME,V_REF_NAME, V_REF_ID, V_PRE_DATA_COUNT,NULL, SQLCODE, SQLERRM, V_REMARKS, V_TABLE_NAME) ;
	END;

	BEGIN
		V_REMARKS:='Completed successfully';
		V_START_TIME:=V_END_TIME;
		V_SQL:='Select count (1) from  ACT_RU_VARIABLE'||V_DB_LINK||' a where a.proc_inst_id_ in ('||PROC_DEF_ID||')
		and not EXISTS (select * from ACT_RU_VARIABLE e where e.id_=a.id_)';
		EXECUTE IMMEDIATE V_SQL INTO V_PRE_DATA_COUNT;
		V_TABLE_NAME:='ACT_RU_VARIABLE';
		V_SQL:='Insert into ACT_RU_VARIABLE
		Select * from  ACT_RU_VARIABLE'||V_DB_LINK||' a where a.proc_inst_id_ in ('||PROC_DEF_ID||')
		and not EXISTS (select * from ACT_RU_VARIABLE e where e.id_=a.id_)';
		EXECUTE IMMEDIATE V_SQL;
		V_SQL:='Select count (1) from  ACT_RU_VARIABLE a where a.proc_inst_id_ in ('||PROC_DEF_ID||')';
		EXECUTE IMMEDIATE V_SQL INTO V_POST_DATA_COUNT;
		V_END_TIME:=SYSDATE;
			SP_MIGRATION_PROCESS_LOG('INSERT_WF', V_START_TIME, V_END_TIME,V_REF_NAME, V_REF_ID, V_PRE_DATA_COUNT, V_POST_DATA_COUNT,NULL,NULL,NULL, V_TABLE_NAME);
	EXCEPTION
		WHEN OTHERS THEN
			V_REMARKS:='Not Processed';
			SP_MIGRATION_PROCESS_LOG('INSERT_WF', V_START_TIME, V_END_TIME,V_REF_NAME, V_REF_ID, V_PRE_DATA_COUNT,NULL, SQLCODE, SQLERRM, V_REMARKS, V_TABLE_NAME) ;
	END;

	BEGIN
		V_REMARKS:='Completed successfully';
		V_START_TIME:=V_END_TIME;
		V_SQL:='Select count (1) from ACT_HI_VARINST'||V_DB_LINK||' a where a.proc_inst_id_ in ('||PROC_DEF_ID||')
		and not EXISTS (select * from ACT_HI_VARINST e where e.id_=a.id_)';
		EXECUTE IMMEDIATE V_SQL INTO V_PRE_DATA_COUNT;
		V_TABLE_NAME:='ACT_HI_VARINST';
		V_SQL:='Insert into ACT_HI_VARINST
		Select * from ACT_HI_VARINST'||V_DB_LINK||' a where a.proc_inst_id_ in ('||PROC_DEF_ID||')
		and not EXISTS (select * from ACT_HI_VARINST e where e.id_=a.id_)';
		EXECUTE IMMEDIATE V_SQL;
		V_SQL:='Select count (1) from ACT_HI_VARINST a where a.proc_inst_id_ in ('||PROC_DEF_ID||')';
		EXECUTE IMMEDIATE V_SQL INTO V_POST_DATA_COUNT;
		V_END_TIME:=SYSDATE;
			SP_MIGRATION_PROCESS_LOG('INSERT_WF', V_START_TIME, V_END_TIME,V_REF_NAME, V_REF_ID, V_PRE_DATA_COUNT, V_POST_DATA_COUNT,NULL,NULL,NULL, V_TABLE_NAME);
	EXCEPTION
		WHEN OTHERS THEN
			V_REMARKS:='Not Processed';
			SP_MIGRATION_PROCESS_LOG('INSERT_WF', V_START_TIME, V_END_TIME,V_REF_NAME, V_REF_ID, V_PRE_DATA_COUNT,NULL, SQLCODE, SQLERRM, V_REMARKS, V_TABLE_NAME) ;
	END;

	BEGIN
		V_REMARKS:='Completed successfully';
		V_START_TIME:=V_END_TIME;
		V_SQL:='Select count (1) from ACT_HI_DETAIL'||V_DB_LINK||' a where a.proc_inst_id_ in ('||PROC_DEF_ID||')
		and not EXISTS (select * from ACT_HI_DETAIL e where e.id_=a.id_)';
		EXECUTE IMMEDIATE V_SQL INTO V_PRE_DATA_COUNT;
		V_TABLE_NAME:='ACT_HI_DETAIL';
		V_SQL:='Insert into ACT_HI_DETAIL
		Select * from ACT_HI_DETAIL'||V_DB_LINK||' a where a.proc_inst_id_ in ('||PROC_DEF_ID||')
		and not EXISTS (select * from ACT_HI_DETAIL e where e.id_=a.id_)';
		EXECUTE IMMEDIATE V_SQL;
		V_SQL:='Select count (1) from ACT_HI_DETAIL a where a.proc_inst_id_ in ('||PROC_DEF_ID||')';
		EXECUTE IMMEDIATE V_SQL INTO V_POST_DATA_COUNT;
		V_END_TIME:=SYSDATE;
			SP_MIGRATION_PROCESS_LOG('INSERT_WF', V_START_TIME, V_END_TIME,V_REF_NAME, V_REF_ID, V_PRE_DATA_COUNT, V_POST_DATA_COUNT,NULL,NULL,NULL, V_TABLE_NAME);
		EXCEPTION
			WHEN OTHERS THEN
				V_REMARKS:='Not Processed';
				SP_MIGRATION_PROCESS_LOG('INSERT_WF', V_START_TIME, V_END_TIME,V_REF_NAME, V_REF_ID, V_PRE_DATA_COUNT,NULL, SQLCODE, SQLERRM, V_REMARKS, V_TABLE_NAME) ;
	END;

	BEGIN
		V_REMARKS:='Completed successfully';
		V_START_TIME:=V_END_TIME;
		V_SQL:='Select count (1) from ACT_RU_IDENTITYLINK'||V_DB_LINK||' a where a.task_id_ in
		(Select id_ from ACT_RU_TASK'||V_DB_LINK||' where proc_inst_id_ in ('||PROC_DEF_ID||'))
		and not EXISTS (select * from ACT_RU_IDENTITYLINK e where e.id_=a.id_)';
		EXECUTE IMMEDIATE V_SQL INTO V_PRE_DATA_COUNT;
		V_TABLE_NAME:='ACT_RU_IDENTITYLINK';
		V_SQL:='Insert into ACT_RU_IDENTITYLINK
		Select * from ACT_RU_IDENTITYLINK'||V_DB_LINK||' a where a.task_id_ in
		(Select id_ from ACT_RU_TASK'||V_DB_LINK||' where proc_inst_id_ in ('||PROC_DEF_ID||'))
		and not EXISTS (select * from ACT_RU_IDENTITYLINK e where e.id_=a.id_)';
		EXECUTE IMMEDIATE V_SQL;
		V_SQL:='Select count (1) from ACT_RU_IDENTITYLINK a where a.task_id_ in
		(Select id_ from ACT_RU_TASK where proc_inst_id_ in ('||PROC_DEF_ID||'))';
		EXECUTE IMMEDIATE V_SQL INTO V_POST_DATA_COUNT;
		V_END_TIME:=SYSDATE;
			SP_MIGRATION_PROCESS_LOG('INSERT_WF', V_START_TIME, V_END_TIME,V_REF_NAME, V_REF_ID, V_PRE_DATA_COUNT, V_POST_DATA_COUNT,NULL,NULL,NULL, V_TABLE_NAME);
	EXCEPTION
		WHEN OTHERS THEN
			V_REMARKS:='Not Processed';
			SP_MIGRATION_PROCESS_LOG('INSERT_WF', V_START_TIME, V_END_TIME,V_REF_NAME, V_REF_ID, V_PRE_DATA_COUNT,NULL, SQLCODE, SQLERRM, V_REMARKS, V_TABLE_NAME) ;
	END;

	BEGIN
		V_REMARKS:='Completed successfully';
		V_START_TIME:=V_END_TIME;
		V_SQL:='Select count (1) from ACT_RU_IDENTITYLINK'||V_DB_LINK||' a where a.proc_inst_id_ in ('||PROC_DEF_ID||')
		and not EXISTS (select * from ACT_RU_IDENTITYLINK e where e.id_=a.id_)';
		EXECUTE IMMEDIATE V_SQL INTO V_PRE_DATA_COUNT;
		V_TABLE_NAME:='ACT_RU_IDENTITYLINK';
		V_SQL:='Insert into ACT_RU_IDENTITYLINK
		Select * from ACT_RU_IDENTITYLINK'||V_DB_LINK||' a where a.proc_inst_id_ in ('||PROC_DEF_ID||')
		and not EXISTS (select * from ACT_RU_IDENTITYLINK e where e.id_=a.id_)';
		EXECUTE IMMEDIATE V_SQL;
		V_SQL:='Select count (1) from ACT_RU_IDENTITYLINK a where a.proc_inst_id_ in ('||PROC_DEF_ID||')';
		EXECUTE IMMEDIATE V_SQL INTO V_POST_DATA_COUNT;
		V_END_TIME:=SYSDATE;
			SP_MIGRATION_PROCESS_LOG('INSERT_WF', V_START_TIME, V_END_TIME,V_REF_NAME, V_REF_ID, V_PRE_DATA_COUNT, V_POST_DATA_COUNT,NULL,NULL,NULL, V_TABLE_NAME);
	EXCEPTION
		WHEN OTHERS THEN
			V_REMARKS:='Not Processed';
			SP_MIGRATION_PROCESS_LOG('INSERT_WF', V_START_TIME, V_END_TIME,V_REF_NAME, V_REF_ID, V_PRE_DATA_COUNT,NULL, SQLCODE, SQLERRM, V_REMARKS, V_TABLE_NAME) ;
	END;


	BEGIN
		V_REMARKS:='Completed successfully';
		V_START_TIME:=V_END_TIME;
		V_SQL:='Select count (1) from ACT_HI_IDENTITYLINK'||V_DB_LINK||' a where a.task_id_ in
		(Select id_ from ACT_RU_TASK'||V_DB_LINK||' where proc_inst_id_ in ('||PROC_DEF_ID||'))
		and not EXISTS (select * from ACT_HI_IDENTITYLINK e where e.id_=a.id_)';
		EXECUTE IMMEDIATE V_SQL INTO V_PRE_DATA_COUNT;
		V_TABLE_NAME:='ACT_HI_IDENTITYLINK';
		V_SQL:='Insert into ACT_HI_IDENTITYLINK
		Select * from ACT_HI_IDENTITYLINK'||V_DB_LINK||' a where a.task_id_ in
		(Select id_ from ACT_RU_TASK'||V_DB_LINK||' where proc_inst_id_ in ('||PROC_DEF_ID||'))
		and not EXISTS (select * from ACT_HI_IDENTITYLINK e where e.id_=a.id_)';
		EXECUTE IMMEDIATE V_SQL;
		V_SQL:='Select count (1) from ACT_HI_IDENTITYLINK a where a.task_id_ in
		(Select id_ from ACT_RU_TASK where proc_inst_id_ in ('||PROC_DEF_ID||'))';
		EXECUTE IMMEDIATE V_SQL INTO V_POST_DATA_COUNT;
		V_END_TIME:=SYSDATE;
			SP_MIGRATION_PROCESS_LOG('INSERT_WF', V_START_TIME, V_END_TIME,V_REF_NAME, V_REF_ID, V_PRE_DATA_COUNT, V_POST_DATA_COUNT,NULL,NULL,NULL, V_TABLE_NAME);
	EXCEPTION
		WHEN OTHERS THEN
			V_REMARKS:='Not Processed';
			SP_MIGRATION_PROCESS_LOG('INSERT_WF', V_START_TIME, V_END_TIME,V_REF_NAME, V_REF_ID, V_PRE_DATA_COUNT,NULL, SQLCODE, SQLERRM, V_REMARKS, V_TABLE_NAME) ;
	END;

	BEGIN
		V_REMARKS:='Completed successfully';
		V_START_TIME:=V_END_TIME;
		V_SQL:='Select count (1) from ACT_HI_IDENTITYLINK'||V_DB_LINK||' a where a.proc_inst_id_ in ('||PROC_DEF_ID||')
		and not EXISTS (select * from ACT_HI_IDENTITYLINK e where e.id_=a.id_)';
		EXECUTE IMMEDIATE V_SQL INTO V_PRE_DATA_COUNT;
		V_TABLE_NAME:='ACT_HI_IDENTITYLINK';
		V_SQL:='Insert into ACT_HI_IDENTITYLINK
		Select * from ACT_HI_IDENTITYLINK'||V_DB_LINK||' a where a.proc_inst_id_ in ('||PROC_DEF_ID||')
		and not EXISTS (select * from ACT_HI_IDENTITYLINK e where e.id_=a.id_)';
		EXECUTE IMMEDIATE V_SQL;
		V_SQL:='Select count (1) from ACT_HI_IDENTITYLINK a where a.proc_inst_id_ in ('||PROC_DEF_ID||')';
		EXECUTE IMMEDIATE V_SQL INTO V_POST_DATA_COUNT;
		V_END_TIME:=SYSDATE;
			SP_MIGRATION_PROCESS_LOG('INSERT_WF', V_START_TIME, V_END_TIME,V_REF_NAME, V_REF_ID, V_PRE_DATA_COUNT, V_POST_DATA_COUNT,NULL,NULL,NULL, V_TABLE_NAME);
	EXCEPTION
		WHEN OTHERS THEN
			V_REMARKS:='Not Processed';
			SP_MIGRATION_PROCESS_LOG('INSERT_WF', V_START_TIME, V_END_TIME,V_REF_NAME, V_REF_ID, V_PRE_DATA_COUNT,NULL, SQLCODE, SQLERRM, V_REMARKS, V_TABLE_NAME) ;
	END;

	COMMIT;
EXCEPTION
	WHEN OTHERS THEN
		V_REMARKS:='Not Processed';
		SP_MIGRATION_PROCESS_LOG('INSERT_WF', NULL, NULL,NULL, NULL, NULL,NULL, SQLCODE, SQLERRM, V_REMARKS, NULL) ;
END INSERT_WF;

PROCEDURE SP_ALF_POPULATE_NUM_FILTER_LIST
(
IP_FILTER_TYPE  IN   Varchar2,
IP_FILTER       IN   ALF_NUM_ARRAY,
ip_sequence     OUT  Number
)
IS PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN

    ip_sequence := SEQ_ALF_NUM_FILTER.Nextval;

    FORALL i IN 1..IP_FILTER.count
                             INSERT into TBL_ALF_NUM_FILTER values (ip_sequence,IP_FILTER_TYPE,IP_FILTER(i));

    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
         null;--pkg_error_log.SP_ERROR_LOG('SP_POPULATE_NUM_FILTER_LIST');
END SP_ALF_POPULATE_NUM_FILTER_LIST;
PROCEDURE SP_ALF_POPULATE_NUM_FILTER_LIST
(
IP_FILTER_TYPE  IN   Varchar2,
IP_FILTER       IN   NUMBER,
ip_sequence     OUT  Number
)
IS PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN

    ip_sequence := SEQ_ALF_NUM_FILTER.Nextval;
    INSERT into TBL_ALF_NUM_FILTER values (ip_sequence,IP_FILTER_TYPE,IP_FILTER);

    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
         null;--pkg_error_log.SP_ERROR_LOG('SP_POPULATE_NUM_FILTER_LIST');
END SP_ALF_POPULATE_NUM_FILTER_LIST;
PROCEDURE SP_MIGRATION_PROCESS_LOG(IP_OBJECT_NAME  IN VARCHAR2,IP_START_TIME IN DATE, IP_END_TIME IN DATE,IP_REF_NAME IN VARCHAR2, IP_REF_ID IN NUMBER, IP_PRE_COUNT IN NUMBER,IP_POST_COUNT IN NUMBER,IP_ERROR_CODE IN VARCHAR2, IP_ERROR_MSG IN VARCHAR2, IP_REMARKS IN VARCHAR2,IP_TABLE_NAME IN VARCHAR2) IS
      -- This procedure is autonomous from the calling procedure.
      -- i.e The calling procedure does not have to be complete
      -- for this procedure to commit its changes.
      PRAGMA AUTONOMOUS_TRANSACTION;
  BEGIN
      INSERT
      INTO
        TBL_MIGRATION_PROCESS_LOG
        (
        MIGRATION_PROCESS_ID,
        OBJECT_NAME,
        EXEC_START,
        EXEC_END,
        TABLE_NAME,
        REF_NAME,
        REF_ID,
        PRE_MIG_COUNT,
        POST_MIG_COUNT,
        ERROR_CODE,
        ERROR_MSG,
        ERROR_STACK,
        CALL_STACK,
        ERROR_BACKTRACE,
        REMARKS
        )
        VALUES
        (
          SEQ_MIGRATION_PROCESS_LOG.NEXTVAL ,
          IP_OBJECT_NAME,
          IP_START_TIME,
          IP_END_TIME,
          IP_TABLE_NAME,
          IP_REF_NAME,
          IP_REF_ID,
          IP_PRE_COUNT,
          IP_POST_COUNT,
          IP_ERROR_CODE ,
          IP_ERROR_MSG ,
          DBMS_UTILITY.FORMAT_ERROR_STACK,
          DBMS_UTILITY.FORMAT_CALL_STACK,
          DBMS_UTILITY.FORMAT_ERROR_BACKTRACE,
          IP_REMARKS
        );

      COMMIT;

  EXCEPTION

    WHEN OTHERS THEN
      ROLLBACK;
      RETURN;
  END ;
END PKG_ALF_DB_MIGRATION;
/