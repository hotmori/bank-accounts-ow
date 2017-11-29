create user &&v_schema identified by &v_schema default tablespace USERS temporary tablespace TEMP;
 
grant unlimited tablespace to &&v_schema;
grant create session, alter session to &v_schema;
grant select any dictionary to &v_schema;
grant create table to &v_schema;
grant create sequence to &v_schema;
grant create procedure to &v_schema;
grant execute on dbms_lock to &v_schema;