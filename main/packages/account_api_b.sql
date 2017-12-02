create or replace package body account_api is

TR_DEBIT constant varchar2(16) := 'DEBIT';
TR_CREDIT constant varchar2(16) := 'CREDIT';

ERR_INVALID_AMOUNT constant varchar2(64) := 'Invalid amount value.';
ERR_INVALID_PERIOD constant varchar2(64) := 'Invalid period. At least one day should be in between.';
ERR_INSUFFICIENT_BALANCE constant varchar2(64) := 'Insufficient balance.';

function to_days
          ( itvl in dsinterval_unconstrained ) return number
is
begin
  return round (extract( day from itvl )
                + extract( hour from itvl )/24
                + extract( minute from itvl )/1440
                + extract( second from itvl )/86400 );
end to_days;

function normalize_to_bs_day_start
           ( p_timestamp timestamp with local time zone,
             p_hour_offset number default DAY_HOUR_OFFSET ) return timestamp with local time zone
is
  v_bday timestamp with local time zone := cast ( trunc ( p_timestamp ) as timestamp ) at local
                                             + numtodsinterval(p_hour_offset, 'hour');
  v_bday_prev timestamp with local time zone := v_bday - numtodsinterval(1, 'day');
begin
  return case when p_timestamp >= v_bday
              then v_bday
              else v_bday_prev
         end;
end normalize_to_bs_day_start;

-- it assumed that default isolation level is set (read_commited)
-- so serialization is required for account transactions
-- function lock account balance and returns its value
function i_get_account_balance
           ( p_accountid number,
             p_lock_flg boolean )
return number
is
  v_balance number;
begin

  if p_lock_flg then

    select ac.balance
      into v_balance
      from accounts ac
     where ac.accountid = p_accountid
       for update of ac.accountid;

  else

    select ac.balance
      into v_balance
      from accounts ac
     where ac.accountid = p_accountid;

  end if;

  return v_balance;

end i_get_account_balance;

procedure i_adjust_balance
            ( p_accountid number,
              p_balance number )
is
begin

  update accounts ac
     set ac.balance = p_balance
   where ac.accountid = p_accountid;

end i_adjust_balance;

procedure i_commit
           ( p_do_commit boolean )
is
begin
  if p_do_commit then
    commit;
  end if;
end i_commit;

function i_create_account_transaction
           ( p_accountid number,
             p_transaction_type varchar2,
             p_amount number,
             p_transaction_time timestamp with local time zone ) return number
is
  v_transactionid number := account_transactions_seq.nextval;
begin

  insert into account_transactions
              ( account_transactionid,
                accountid,
                transaction_type,
                amount,
                transaction_time )
  values ( v_transactionid,
           p_accountid,
           p_transaction_type,
           p_amount,
           p_transaction_time );

  return v_transactionid;

end i_create_account_transaction;

procedure i_assert 
            ( p_result boolean,
              p_msg varchar2 )
is
begin
  if not p_result then
    raise_application_error (-20000, 'Assert failed: ' || p_msg );
  end if;
end i_assert;

function i_withdraw
            ( p_accountid number,
              p_amount number,
              p_lock_flg boolean,
              p_do_commit boolean,
              p_effective_time timestamp with local time zone )
return number
is
  v_current_balance number;
  v_result_balance number;
  v_effective_time timestamp with local time zone := nvl( p_effective_time, current_timestamp );

  v_transactionid number;
begin

  i_assert ( p_amount > 0, ERR_INVALID_AMOUNT );

  v_current_balance := i_get_account_balance ( p_accountid, p_lock_flg );

  i_assert ( p_amount > v_current_balance, ERR_INSUFFICIENT_BALANCE );

  v_result_balance := v_current_balance - p_amount;

  v_transactionid := i_create_account_transaction
                       ( p_accountid => p_accountid,
                         p_transaction_type => TR_DEBIT,
                         p_amount => -p_amount,
                         p_transaction_time => v_effective_time );

  i_adjust_balance ( p_accountid => p_accountid,
                     p_balance => v_result_balance );

  i_commit ( p_do_commit );

  return v_transactionid;
end i_withdraw;

function i_deposit
            ( p_accountid number,
              p_amount number,
              p_lock_flg boolean,
              p_do_commit boolean,
              p_effective_time timestamp with local time zone )
return number
is
  v_current_balance number;
  v_result_balance number;
  v_effective_time timestamp with local time zone := nvl( p_effective_time, current_timestamp );

  v_transactionid number;
begin

  i_assert ( p_amount > 0, ERR_INVALID_AMOUNT );

  v_current_balance := i_get_account_balance ( p_accountid, p_lock_flg );

  v_result_balance := v_current_balance + p_amount;

  v_transactionid := i_create_account_transaction
                       ( p_accountid => p_accountid,
                         p_transaction_type => TR_CREDIT,
                         p_amount => p_amount,
                         p_transaction_time => v_effective_time );

  i_adjust_balance ( p_accountid => p_accountid,
                     p_balance => v_result_balance );

  i_commit ( p_do_commit );

  return v_transactionid;

end i_deposit;

procedure i_set_ref_transactionid (p_transactionid number,
                                   p_src_transactionid number default null,
                                   p_trg_transactionid number default null)
is
begin

  update account_transactions tr
     set tr.src_transactionid = p_src_transactionid
       , tr.trg_transactionid = p_trg_transactionid
   where tr.account_transactionid = p_transactionid;

end i_set_ref_transactionid;

procedure create_account
           ( p_accountid number,
             p_display_name nvarchar2 )
is
begin

  insert into accounts( accountid,
                        display_name,
                        balance )
  values ( p_accountid,
           p_display_name,
           0 );

exception when dup_val_on_index then
  rollback;
  raise_application_error (-20000, 'Account with this accountid already exists.');
end create_account;

procedure withdraw
            ( p_accountid number,
              p_amount number,
              p_do_commit boolean default false,
              p_effective_time timestamp with local time zone default null )
is
  v_transactionid number;
begin
  v_transactionid := i_withdraw ( p_accountid => p_accountid,
                                  p_amount => p_amount,
                                  p_lock_flg => true,
                                  p_do_commit => p_do_commit,
                                  p_effective_time => p_effective_time );
exception when others then
  rollback;
  raise;
end withdraw;

procedure deposit
            ( p_accountid number,
              p_amount number,
              p_do_commit boolean default false,
              p_effective_time timestamp with local time zone default null )
is
  v_transactionid number;
begin
  v_transactionid := i_deposit ( p_accountid => p_accountid,
                                 p_amount => p_amount,
                                 p_lock_flg => true,
                                 p_do_commit => p_do_commit,
                                 p_effective_time => p_effective_time );
exception when others then
  rollback;
  raise;
end deposit;

procedure transfer
            ( p_src_accountid number,
              p_trg_accountid number,
              p_amount number,
              p_commit boolean default false,
              p_effective_time timestamp with local time zone default null )
is

  type number_t is table of number;
  v_ids  number_t;

  v_effective_time timestamp with local time zone := nvl( p_effective_time, current_timestamp );

  v_src_transactionid number := account_transactions_seq.nextval;
  v_trg_transactionid number := account_transactions_seq.nextval;
begin

  i_assert ( p_amount > 0, ERR_INVALID_AMOUNT );
  -- there is need to lock two accounts simultaneously
  --    avoid deadlock in case of opposit transfer at the same moment
  select ac.accountid
    bulk collect into v_ids
    from accounts ac
   where ac.accountid in ( p_src_accountid, p_trg_accountid )
   order by ac.accountid
     for update of ac.accountid;

  v_src_transactionid:= i_withdraw ( p_accountid => p_src_accountid,
                                     p_amount => p_amount,
                                     p_lock_flg => false,
                                     p_do_commit => false,
                                     p_effective_time => v_effective_time );

  v_trg_transactionid := i_deposit ( p_accountid => p_trg_accountid,
                                     p_amount => p_amount,
                                     p_lock_flg => false,
                                     p_do_commit => false,
                                     p_effective_time => v_effective_time );

  -- set cross reference between two transactions
  i_set_ref_transactionid ( p_transactionid => v_src_transactionid,
                            p_trg_transactionid => v_trg_transactionid );

  i_set_ref_transactionid ( p_transactionid => v_trg_transactionid,
                            p_src_transactionid => v_src_transactionid );

  i_commit ( p_commit );

exception when others then
  rollback;
  raise;
end transfer;

function calc_earned_percents
           ( p_accountid number,
             p_time_from timestamp with local time zone,
             p_time_to timestamp with local time zone,
             p_interest_rate number ) return number
is

  v_result number := 0;
  v_effective_time_from timestamp with local time zone;
  v_effective_time_to timestamp with local time zone;

begin

  v_effective_time_from := normalize_to_bs_day_start ( p_time_from );
  v_effective_time_to := normalize_to_bs_day_start ( p_time_to );
  i_assert ( v_effective_time_from < v_effective_time_to, ERR_INVALID_PERIOD );

  with
  w1 as (
   -- for every transaction calculate business day start
   -- for lower bound of period calculate business day start
   -- for upper bound of period calculate business day start
   select tr.amount
         ,tr.transaction_time
         ,sum(tr.amount) over(partition by tr.accountid order by tr.accountid, tr.transaction_time range unbounded preceding) calculated_balance
         ,account_api.normalize_to_bs_day_start ( tr.transaction_time ) effective_bday_start
         ,account_api.normalize_to_bs_day_start ( tr.transaction_time ) + numtodsinterval(1,'day') effective_balance_from
         ,v_effective_time_from effective_time_from
         ,v_effective_time_to effective_time_to
     from account_transactions tr
    where tr.accountid = p_accountid ),
  w2 as (
  -- calculate effective balance value
  select distinct
         w1.effective_balance_from
        ,last_value(w1.calculated_balance)
         over(partition by w1.effective_bday_start) effective_balance_value
        ,w1.effective_time_from
        ,w1.effective_time_to
    from w1 ),
  w3 as (
  -- catch when effective balance was changed
  select w2.effective_balance_value
        ,w2.effective_balance_from
        ,lead(w2.effective_balance_from, 1, w2.effective_time_to )
         over( order by w2.effective_balance_from  ) effective_balance_to -- excluding
        ,w2.effective_time_from
        ,w2.effective_time_to
    from w2 ),
  w4 as (
  -- calculate days between crossed given period and effective balance periods
  select w3.effective_balance_value
        ,account_api.to_days (  least (w3.effective_balance_to, w3.effective_time_to)
                               -  greatest (w3.effective_balance_from, w3.effective_time_from) ) days_in_period
        ,add_months ( cast( w3.effective_balance_from as date ), 12 )
         - cast ( w3.effective_balance_from as date ) days_in_year_for_period
    from w3 )
  -- round values before aggregating
  select nvl( sum( round( w4.effective_balance_value * p_interest_rate * w4.days_in_period /
                          w4.days_in_year_for_period, 2 ) ), 0 )
    into v_result
    from w4
   where w4.days_in_period > 0;

  return v_result;

end calc_earned_percents;

end account_api;
/