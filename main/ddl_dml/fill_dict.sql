insert into transaction_types
              ( transaction_type, description )
select 'DEBIT',  'Debit' from dual union all
select 'CREDIT', 'Credit' from dual
/

commit
/