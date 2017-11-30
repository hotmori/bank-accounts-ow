-- show remaining result on accounts for given date
with
  w1 as (
  select tr.accountid,
         tr.transaction_type,
         tr.amount,
         tr.transaction_time,
         sum(tr.amount) over(partition by tr.accountid order by tr.transaction_time range unbounded preceding) calc_result_balance,
         tr.result_balance -- todo
    from account_transactions tr
   where tr.accountid in ( 1010, 2020, 3030 )
     and tr.transaction_time <= to_timestamp_tz('2019/11/08 10:31:00', 'YYYY/MM/DD HH:MI:SS')
   order by tr.accountid, tr.transaction_time asc )
--
select distinct
       w1.accountid
      ,last_value(calc_result_balance) 
       over( partition by w1.accountid order by w1.accountid, w1.transaction_time
             range between unbounded preceding and unbounded following ) balance_on_given_time
      --, w1.transaction_type
      --, w1.amount
      --, w1.transaction_time
      --, w1.calc_result_balance
      --, w1.result_balance todo
  from w1
order by w1.accountid
/