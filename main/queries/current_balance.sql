-- current balance v1
select ac.accountid,
       ac.balance current_balance
  from accounts ac
 where ac.accountid in ( 1010, 2020, 3030 )
 order by ac.accountid
/

-- current balance v2
select tr.accountid,
       sum(tr.amount) current_balance
  from account_transactions tr
 where tr.accountid in ( 1010, 2020, 3030 )
 group by tr.accountid
 order by tr.accountid
/