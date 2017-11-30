-- show debit and credits sums within arbitrary period
select distinct
       ac.accountid
      ,sum( decode(tr.transaction_type, 'DEBIT', tr.amount, 0) ) over ( partition by tr.accountid ) total_debit_in_period
      ,sum( decode(tr.transaction_type, 'CREDIT', tr.amount, 0) ) over ( partition by tr.accountid ) total_credit_in_period
      --,tr.transaction_type
      --,tr.amount
      --,tr.transaction_time
      --,tr.result_balance todo
  from accounts ac
  left join account_transactions tr
    on tr.accountid = ac.accountid
   and tr.transaction_time >= to_timestamp_tz('2017/11/01 09:05:00', 'YYYY/MM/DD HH:MI:SS') -- from
   and tr.transaction_time < to_timestamp_tz('2019/11/05 09:05:00', 'YYYY/MM/DD HH:MI:SS') -- to
 where ac.accountid in ( 1010, 2020, 3030 )
 order by ac.accountid
         --,tr.transaction_time
/