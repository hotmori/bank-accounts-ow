-- account balance on arbitrary date
with r as
(select a_op.*,
        lead(a_op.transaction_time/*, 1,  to_timestamp_tz('9999/12/31 10:00:00', 'YYYY/MM/DD HH:MI:SS')  */) 
        over(partition by a_op.accountid order by a_op.transaction_time) next_transaction_time
   from account_transactions a_op
  order by a_op.transaction_time),
param_set as (
select --to_timestamp_tz('2017/11/05 09:05:00', 'YYYY/MM/DD HH:MI:SS') given_date
       --to_timestamp_tz('&given_date', 'YYYY/MM/DD HH:MI:SS') given_date
       current_timestamp given_date
  from dual
)
select r.result_balance, r.*
  from r
  join param_set on 1=1
 where 1=1
   and r.accountid = 6
   and param_set.given_date >= r.transaction_time
   and (param_set.given_date < r.next_transaction_time or r.next_transaction_time is null)
/

-- sum of debits and credits for arbitrary period
with
param_set as (
select to_timestamp_tz('2017/11/01 09:05:00', 'YYYY/MM/DD HH:MI:SS') date_from,
       to_timestamp_tz('2017/11/04 09:05:00', 'YYYY/MM/DD HH:MI:SS') date_to,
       6 accountid
  from dual
)
select a_op.accountid,
       sum(case when a_op.transaction_type = 1 then a_op.amount else 0 end) debit_amount,
       sum(case when a_op.transaction_type = 2 then a_op.amount else 0 end) credit_amount
  from account_transactions a_op
  join param_set on 1=1
 where 1=1
   and a_op.accountid = param_set.accountid
   and a_op.transaction_time >= param_set.date_from 
   and a_op.transaction_time < param_set.date_to
 group by a_op.accountid
/

-- earned percents v1

with r as
(select a_op.accountid
       ,a_op.result_balance
       ,lag(a_op.result_balance, 1, 0) over (partition by a_op.accountid order by a_op.transaction_time) prev_balance
       ,a_op.transaction_time
       ,cast ( trunc ( a_op.transaction_time ) as timestamp ) at local + numtodsinterval(1/*8-24*/, 'hour') business_day_start
       ,cast ( trunc ( a_op.transaction_time ) as timestamp ) at local + numtodsinterval(1/*8*/, 'hour') business_day_end
   from account_transactions a_op
  order by a_op.transaction_time),
x as (
select r.*
     , case when r.transaction_time >= r.business_day_start 
             and r.transaction_time < r.business_day_end 
            then 1 else 0 end incl
     , max ( case when r.transaction_time >= r.business_day_start 
             and r.transaction_time < r.business_day_end 
             then 1 else 0 end ) over (partition by r.business_day_end ) bal_chng_bsnss_day_flg
    , row_number() over(partition by r.business_day_start order by r.transaction_time) rn_transaction
  from r
 where 1=1
   and r.accountid = 1010
  order by r.transaction_time),
w1 as (
select x.result_balance,
       x.transaction_time,
       x.business_day_start,
       x.business_day_end,
       x.rn_transaction,
       lead(case when x.rn_transaction = 1 then x.business_day_start else null end ignore nulls,1, current_timestamp) over (order by x.transaction_time) nxt,
       x.incl,
       x.bal_chng_bsnss_day_flg,
       case when x.bal_chng_bsnss_day_flg = 1 and x.incl = 1 then last_value(result_balance) over ( partition by x.business_day_end, x.incl) end last_balance,
       case when x.bal_chng_bsnss_day_flg = 0 and x.incl = 0 then first_value(prev_balance) over ( partition by x.business_day_end,  x.incl) end xprev_balance,
       'x'
  from x
  order by x.transaction_time)
select w1.*,
       trunc(w1.nxt) - trunc(w1.business_day_start) days_between
   from w1
/

select current_timestamp, current_timestamp + numtodsinterval(1, 'hour'), zportal.dtrunc(current_timestamp) 
from dual;

create table t1(a number, b number);
insert into t1 values(1, 1);
insert into t1 values(1, 2);
insert into t1 values(1, 3);
with w1 as
( select t1.a,
         t1.b,
         row_number() over (partition by t1.a order by t1.a) rn
    from t1
   order by a, b )
select  w1.a
       , w1.b
       , lead(case when w1.rn = 1 then w1.a end ignore nulls) over( order by w1.a ) next_a
  from w1;

-- earned percents v2
with w1 as
( select a_op.accountid
       ,a_op.result_balance
       ,a_op.transaction_time
       ,(cast ( trunc ( a_op.transaction_time ) as timestamp ) at local + numtodsinterval(   +8, 'hour') ) bday_start
       ,(cast ( trunc ( a_op.transaction_time ) as timestamp ) at local + numtodsinterval(-24+8, 'hour') ) bday_start_prev
   from account_transactions a_op
  where a_op.accountid = 1010
   and a_op.transaction_time >= to_timestamp_tz('2015/11/01 09:05:00', 'YYYY/MM/DD HH:MI:SS') -- time_from
   and a_op.transaction_time < to_timestamp_tz('2018/11/01 09:05:00', 'YYYY/MM/DD HH:MI:SS') -- time_to
   --and a_op.transaction_time < current_timestamp + numtodsinterval (50, 'day')

  order by a_op.transaction_time),
w2 as (
select w1.accountid
      ,w1.result_balance
      ,w1.transaction_time
      ,case when w1.transaction_time >= w1.bday_start 
            then w1.bday_start
            else w1.bday_start_prev
       end effective_bday_start
  from w1),
w3 as
(select w2.accountid
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

with w1 as
(select level-10 rn
  from dual connect by level <= 100)
select current_date,
       add_months(current_date, 12*rn) future_date,
       add_months(current_date, 12*rn) - add_months(current_date, 12*(rn-1))
  from w1
/
           