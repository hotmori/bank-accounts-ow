whenever sqlerror continue
whenever oserror  continue

set echo on
set timing on
set serveroutput on
set verify off
set linesize 4000

define v_instance = &&1
define v_schema = &&2

set instance &&v_instance

spool main_&&v_instance._&&v_schema..log

connect system
@main/create_schema.sql
alter session set current_schema = &&v_schema;
------- ddl dml section ----------
@main/ddl_dml/create_tables.sql
@main/ddl_dml/create_sequences.sql
@main/ddl_dml/fill_dict.sql
------ packages section ----------
@main/packages/account_api_s.sql
@main/packages/account_api_b.sql

------- extra ddl dml section ----------
--@main/ddl_dml/create_test_data.sql

/********************************/

select * from user_errors;

--select * from all_errors where owner = upper('&&v_schema');

spool off
exit