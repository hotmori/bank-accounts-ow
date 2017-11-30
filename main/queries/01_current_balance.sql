-- current balance v1
select ac.accountid,
       ac.balance current_balance
  from accounts ac
 where ac.accountid in ( 1010, 2020, 3030 )
 order by ac.accountid
/

-- current balance v2
select ac.accountid,
       sum( nvl(tr.amount,0) ) current_balance
  from accounts ac
  left join account_transactions tr
    on tr.accountid = ac.accountid
 where ac.accountid in ( 1010, 2020, 3030 )
 group by ac.accountid
 order by ac.accountid
/