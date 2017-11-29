begin
  for RS in (
    select sid ||','|| serial# as session_id
      from v$session
     where type = 'USER' and username = upper('&&v_schema')
  ) loop
    execute immediate 'alter system kill session '''|| RS.session_id ||''' immediate';
  end loop;
 
end;
/