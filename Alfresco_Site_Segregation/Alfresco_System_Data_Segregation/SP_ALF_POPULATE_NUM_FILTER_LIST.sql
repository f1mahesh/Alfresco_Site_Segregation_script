CREATE OR REPLACE PROCEDURE SP_ALF_POPULATE_NUM_FILTER_LIST
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
/