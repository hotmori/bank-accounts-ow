-- accountid, transaction_time, amount
--      1010,         2015 jan,    100
--      1010,         2016 jan,     50

-- 1 transaction:2015 jan, 2: 2016 jan
-- period a: from 2015 sep till 2015 november => 60 days

-- earned percents v2
with
prm as (select to_timestamp_tz('2014/02/01 07:05:00', 'YYYY/MM/DD HH:MI:SS') time_from
             , to_timestamp_tz('2017/11/03 08:05:00', 'YYYY/MM/DD HH:MI:SS') time_to
             , 0.12 rate
          from dual ),
w1 as
( -- for every transaction calculate business day start
  -- for lower bound of period calculate business day start
  -- for upper bound of period calculate business day start
 select tr.accountid
       ,tr.amount
       ,tr.transaction_time
       ,sum(tr.amount) over(partition by tr.accountid order by tr.accountid, tr.transaction_time range unbounded preceding) calculated_balance
       ,account_api.normalize_to_bs_day_start ( tr.transaction_time ) effective_bday_start
       ,account_api.normalize_to_bs_day_start ( prm.time_from ) effective_time_from
       ,account_api.normalize_to_bs_day_start ( prm.time_to ) effective_time_to
       ,account_api.normalize_to_bs_day_start ( tr.transaction_time ) + numtodsinterval(1,'day') effective_balance_from
       ,prm.rate
   from account_transactions tr
   join prm on 1=1
  where tr.accountid in (1010 ,2020 ,3030 )
 --order by tr.accountid, tr.transaction_time
),
w2 as (
-- calculate effective balance business day start
-- calculate effective balance value
select distinct
       w1.accountid
      ,w1.effective_balance_from
      ,last_value(w1.calculated_balance)
       over(partition by w1.accountid, w1.effective_bday_start) effective_balance_value
      ,w1.effective_time_from
      ,w1.effective_time_to
      ,w1.rate
  from w1
),
w3 as
(
-- catch when effective balance was changed
select w2.accountid
      ,w2.effective_balance_value
      ,w2.effective_balance_from
      ,lead(w2.effective_balance_from, 1, w2.effective_time_to )
       over(partition by w2.accountid order by w2.effective_balance_from  ) effective_balance_to -- excluding
      ,w2.effective_time_from
      ,w2.effective_time_to
      ,w2.rate
  from w2
),
w4 as
( 
-- calculate days between crossed given period and effective balance periods
select w3.accountid
      ,w3.effective_balance_value
      ,w3.effective_balance_from
      ,w3.effective_balance_to
      ,w3.effective_time_from
      ,w3.effective_time_to
      ,greatest (w3.effective_balance_from, w3.effective_time_from) cross_effective_balance_from
      ,least (w3.effective_balance_to, w3.effective_time_to) cross_effective_balance_to
      ,account_api.to_days (  least (w3.effective_balance_to, w3.effective_time_to)
                             -  greatest (w3.effective_balance_from, w3.effective_time_from) ) days_in_period
      ,add_months ( cast( w3.effective_balance_from as date ), 12 ) - cast ( w3.effective_balance_from as date ) days_in_year_for_period
      ,w3.rate
  from w3
order by w3.effective_balance_from),
wfinal as (
select w4.accountid
      ,w4.effective_balance_value
      ,w4.effective_balance_from
      ,w4.effective_balance_to
      ,w4.cross_effective_balance_from
      ,w4.cross_effective_balance_to
      ,w4.days_in_period
      ,w4.days_in_year_for_period
      ,w4.rate
      ,round( w4.effective_balance_value * w4.rate * w4.days_in_period / w4.days_in_year_for_period ,2) earns 
  from w4
 where 1=1 
   and days_in_period > 0
order by w4.effective_balance_from
 )
select wfinal.*
      ,sum( wfinal.earns) over (partition by wfinal.accountid) earned_percents
      ,account_api.calc_earned_percents( p_accountid     => wfinal.accountid,
                                         p_time_from     => prm.time_from,
                                         p_time_to       => prm.time_to,
                                         p_interest_rate => prm.rate ) earned_percents_func
  from wfinal
  join prm on 1=1
 where 1=1
order by
 -- accountid, transaction_time -- w1
 accountid, effective_balance_from -- w2
/

/*
accountid, effective_balance_from, effective_balance_value
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
-- calculate against every business day effective_balance_value looks like: sum() over (range between...)
select w2.accountid
      ,w2.result_balance
      ,w2.transaction_time
      ,w2.effective_bday_start
      ,row_number() over(partition by w2.effective_bday_start order by w2.transaction_time desc) rn
  from w2
 order by w2.transaction_time),
w4 as (
select  w3.accountid
      , case when w3.rn = 1 then w3.result_balance end effective_balance_value
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
       sum ( 0.12 * w4.effective_balance_value * days_between / days_in_year ) sum_earned_procents
  from w4
 where 1=1
/
