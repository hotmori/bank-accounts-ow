-- show debit and credits sums within arbitrary period
select distinct
       tr.accountid
      ,sum( case when tr.transaction_type = 'DEBIT' then  tr.amount else 0 end ) over ( partition by tr.accountid ) sum_debit
      ,sum( case when tr.transaction_type = 'CREDIT' then  tr.amount else 0 end ) over ( partition by tr.accountid ) sum_credit
      --,tr.transaction_type
      --,tr.amount
      --,tr.transaction_time
      --,tr.result_balance todo
  from account_transactions tr
 where tr.accountid in ( 1010, 2020, 3030 )
   and tr.transaction_time >= to_timestamp_tz('2015/11/01 09:05:00', 'YYYY/MM/DD HH:MI:SS') -- from
   and tr.transaction_time < to_timestamp_tz('2019/11/05 09:05:00', 'YYYY/MM/DD HH:MI:SS') -- to
 order by tr.accountid
         --,tr.transaction_time
/