whenever sqlerror continue
whenever oserror  continue
set echo on
set timing on
set serveroutput on
set verify off

define v_instance = &&1
define v_schema = &&2

set instance &&v_instance

spool rback_&&v_instance._&&v_schema..log

connect system
alter session set current_schema = &&v_schema;
------ packages section ----------
@rback/drop_packages.sql
------- ddl dml section ----------
@rback/drop_sequences.sql
@rback/drop_tables.sql

@rback/kill_sessions.sql
@rback/drop_schema.sql

/********************************/

select * from dba_errors where owner = upper('&&v_schema');

spool off
exit