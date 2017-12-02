-- show earned percents for arbitrary period
select ac.accountid,
       account_api.calc_earned_percents
         ( p_accountid     => ac.accountid,
           p_time_from     => to_timestamp_tz('2016/02/01 07:05:00', 'YYYY/MM/DD HH:MI:SS'),
           p_time_to       => to_timestamp_tz('2017/11/04 07:05:06', 'YYYY/MM/DD HH:MI:SS'),
           p_interest_rate => 0.12 ) earned_percents
  from accounts ac
 order by ac.accountid
/