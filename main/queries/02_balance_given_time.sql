-- show accounts result balances at a given time
select ac.accountid,
       sum( nvl(tr.amount,0) ) balance_at_given_time
  from accounts ac
  left join account_transactions tr
    on tr.accountid = ac.accountid
   and tr.transaction_time <= to_timestamp_tz('2019/11/03 08:31:00', 'YYYY/MM/DD HH:MI:SS')
 where ac.accountid in ( 1010, 2020, 3030 )
 group by ac.accountid
 order by ac.accountid
/