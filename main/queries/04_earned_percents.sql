-- accountid, transaction_time, amount
--      1010,         2015 jan,    100
--      1010,         2016 jan,     50

-- 1 transaction:2015 jan, 2: 2016 jan
-- period a: from 2015 sep till 2015 november => 60 days

-- earned percents v2
with
prm as (select to_timestamp_tz('2017/02/01 09:05:00', 'YYYY/MM/DD HH:MI:SS') time_from
             , to_timestamp_tz('2017/03/10 09:05:00', 'YYYY/MM/DD HH:MI:SS') time_to
          from dual ),
w1 as
( -- for every transaction calc business day and previous business day
 select tr.accountid
       ,tr.amount
       ,tr.transaction_time
       ,sum(tr.amount) over(partition by tr.accountid order by tr.transaction_time range unbounded preceding) calculated_balance
       ,account_api.normalize_to_bs_day_start ( tr.transaction_time ) effective_bday_start
       ,account_api.normalize_to_bs_day_start ( prm.time_from ) effective_time_from
       ,account_api.normalize_to_bs_day_start ( prm.time_to ) + numtodsinterval(1, 'day') effective_time_to -- excluding
   from account_transactions tr
   join prm on 1=1
  where tr.accountid = 1010
  order by tr.transaction_time),
w2 as (
-- catch every transaction in appropriate business day
select w1.*
  from w1),
w3 as (
select distinct
       w2.accountid
      ,w2.effective_bday_start + numtodsinterval(24,'hour') effective_balance_from
      ,last_value(w2.calculated_balance)
       over(partition by w2.accountid, w2.effective_bday_start) effective_balance
      ,w2.effective_time_from
      ,w2.effective_time_to
  from w2
),
w4 as
(
select w3.accountid,
       w3.effective_balance,
       w3.effective_balance_from,
       lead(w3.effective_balance_from, 1, current_timestamp)
       over(partition by w3.accountid order by w3.effective_balance_from  ) effective_balance_to, -- excluding
       w3.effective_time_from,
       w3.effective_time_to
  from w3
),
w5 as
(select w4.accountid,
       w4.effective_balance,
       w4.effective_balance_from,
       w4.effective_balance_to,
       w4.effective_time_from,
       w4.effective_time_to,
       greatest (w4.effective_balance_from,w4.effective_time_from) cross_effective_balance_from,
       least (w4.effective_balance_to,w4.effective_time_to) cross_effective_balance_to
     ,-- account_api.to_days ( least (w4.effective_balance_to,prm.time_to + numtodsinterval (24, 'hour') )
       --                      - greatest (w4.effective_balance_from,prm.time_from ) )
       null xdays_in_period
  from w4
  join prm on 1=1
order by w4.effective_balance_from),
wfinal as (
select w5.accountid,
       w5.effective_balance,
       w5.effective_balance_from,
       w5.effective_balance_to,
       w5.cross_effective_balance_from,
       w5.cross_effective_balance_to,
       w5.xdays_in_period
  from w5
 where 1=1 
   and w5.cross_effective_balance_from >= w5.effective_balance_from
   and w5.cross_effective_balance_from <= w5.cross_effective_balance_to
order by w5.effective_balance_from )
select *
  from w5
order by
  --transaction_time -- w2
 effective_balance_from -- w3
/

/*
accountid, effective_balance_from, effective_balance
1010 02-JAN-16 08.00.00.000000000 AM +03:00 100
1010 02-NOV-17 08.00.00.000000000 AM +03:00 850
1010 03-NOV-17 08.00.00.000000000 AM +03:00 1130
1010 04-NOV-17 08.00.00.000000000 AM +03:00 1330
1010 06-NOV-17 08.00.00.000000000 AM +03:00 1480
1010 08-NOV-17 08.00.00.000000000 AM +03:00 1480
1010 09-NOV-17 08.00.00.000000000 AM +03:00 1680
1010 13-NOV-17 08.00.00.000000000 AM +03:00 1780

*/
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
