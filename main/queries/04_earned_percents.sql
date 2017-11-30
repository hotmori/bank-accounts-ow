-- earned percents v2
with
w1 as
( -- for every transaction calc business day and previous business day
 select tr.accountid
       ,tr.amount
       --,tr.result_balance
       ,tr.transaction_time
       ,(cast ( trunc ( tr.transaction_time ) as timestamp ) at local + numtodsinterval(-24+8, 'hour') ) bday_start_prev
       ,(cast ( trunc ( tr.transaction_time ) as timestamp ) at local + numtodsinterval(   +8, 'hour') ) bday_start
   from account_transactions tr
  where tr.accountid = 1010
   --and tr.transaction_time >= to_timestamp_tz('2015/11/01 09:05:00', 'YYYY/MM/DD HH:MI:SS') -- time_from
   --and tr.transaction_time < to_timestamp_tz('2018/11/01 09:05:00', 'YYYY/MM/DD HH:MI:SS') -- time_to
  order by tr.transaction_time),
w2 as (
-- catch every transaction in appropriate business day
select w1.accountid
      --,w1.result_balance
      ,w1.amount
      ,w1.transaction_time
      ,case when w1.transaction_time >= w1.bday_start 
            then w1.bday_start
            else w1.bday_start_prev
       end effective_bday_start
  from w1)
select w2.accountid
      ,w2.transaction_time
      ,w2.effective_bday_start
      ,row_number() over(partition by w2.effective_bday_start order by w2.transaction_time desc) rn
  from w2
 order by w2.transaction_time
/
/*,
w3 as
(
-- calculate against every business day effective_balance looks like: sum() over (range between...)
select w2.accountid
      ,w2.result_balance
      ,w2.transaction_time
      ,w2.effective_bday_start
      ,row_number() over(partition by w2.effective_bday_start order by w2.transaction_time desc) rn
  from w2
 order by w2.transaction_time),
w4 as (
select  w3.accountid
      , case when w3.rn = 1 then w3.result_balance end effective_balance
      , w3.transaction_time
      , w3.effective_bday_start
      , add_months ( cast( w3.effective_bday_start as date ), 12 ) - cast ( w3.effective_bday_start as date ) days_in_year
      , trunc(lead(case when w3.rn = 1 then w3.effective_bday_start end ignore nulls, 1, current_timestamp + numtodsinterval (50, 'day') )  -- todo replace by param
              over(partition by w3.accountid order by w3.effective_bday_start ) )
        -  trunc(w3.effective_bday_start) days_between
   from w3
  where 1=1
    and w3.rn = 1)
select --w4.*
       sum ( 0.12 * w4.effective_balance * days_between / days_in_year ) sum_earned_procents
  from w4
 where 1=1
/
