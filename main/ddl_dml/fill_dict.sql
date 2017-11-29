insert into transaction_types
              ( transaction_type, description )
select 1,  'Debit' from dual union all
select 2, 'Credit' from dual
/

commit
/