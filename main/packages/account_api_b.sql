create or replace package body account_api is

AC_DEBIT constant number := 1;
AC_CREDIT constant number := 2;

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

    select balance
      into v_balance
      from accounts ac
     where ac.accountid = p_accountid
       for update of ac.accountid;

  else

    select balance
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

procedure i_track_account_transaction
            ( p_accountid number,
              p_transaction_type number,
              p_amount number,
              p_result_balance number,
              p_transaction_time timestamp with local time zone,
              p_src_accountid number default null,
              p_trg_accountid number default null )
is
begin

  insert into account_transactions
              ( account_transactionid,
                accountid,
                transaction_type,
                amount,
                result_balance,
                src_accountid,
                trg_accountid,
                transaction_time )
  values ( account_transactions_seq.nextval,
           p_accountid,
           p_transaction_type,
           p_amount,
           p_result_balance,
           p_src_accountid,
           p_trg_accountid,
           p_transaction_time );

end i_track_account_transaction;

procedure i_assert_amount ( p_amount number )
is
begin
  if nvl ( p_amount, 0 ) < 0 then
    raise_application_error (-20000, 'Invalid amount value.');
  end if;
end i_assert_amount;

procedure i_assert_rate ( p_rate number )
is
begin
  if nvl ( p_rate, 0 ) < 0 then
    raise_application_error (-20000, 'Invalid amount value.');
  end if;
end i_assert_rate;

function create_account
           ( p_accountid number,
             p_display_name nvarchar2 )
return number
is
  v_accountid number := p_accountid;
begin

  insert into accounts( accountid,
                        display_name,
                        balance )
  values ( v_accountid,
           p_display_name,
           0 );

  return v_accountid;
exception when dup_val_on_index then
  rollback;
  raise_application_error (-20000, 'Account with this accountid already exists.');
end create_account;

-- @p_effective_time is used for test only purposes
--    to generate test data in the past
procedure withdraw
            ( p_accountid number,
              p_amount number,
              p_trg_accountid number default null,
              p_lock_flg boolean default true,
              p_do_commit boolean default false,
              p_effective_time timestamp with local time zone default null )
is
  v_current_balance number;
  v_result_balance number;
  v_effective_time timestamp with local time zone := nvl( p_effective_time, current_timestamp );
begin

  i_assert_amount ( p_amount );

  v_current_balance := i_get_account_balance ( p_accountid, p_lock_flg );

  if p_amount > v_current_balance then
    raise_application_error (-20000, 'Insufficient balance.');
  end if;

  v_result_balance := v_current_balance - p_amount;

  i_track_account_transaction ( p_accountid => p_accountid,
                                p_transaction_type => AC_DEBIT,
                                p_amount => p_amount,
                                p_trg_accountid => p_trg_accountid,
                                p_result_balance => v_result_balance,
                                p_transaction_time => v_effective_time );

  i_adjust_balance ( p_accountid => p_accountid,
                     p_balance => v_result_balance );

  i_commit ( p_do_commit );

end withdraw;

procedure deposit
            ( p_accountid number,
              p_amount number,
              p_src_accountid number default null,
              p_lock_flg boolean default true,
              p_do_commit boolean default false,
              p_effective_time timestamp with local time zone default null )
is
  v_current_balance number;
  v_result_balance number;
  v_effective_time timestamp with local time zone := nvl( p_effective_time, current_timestamp );
begin

  i_assert_amount ( p_amount );

  v_current_balance := i_get_account_balance ( p_accountid, p_lock_flg );

  v_result_balance := v_current_balance + p_amount;

  i_track_account_transaction ( p_accountid => p_accountid,
                                p_transaction_type => AC_CREDIT,
                                p_amount => p_amount,
                                p_src_accountid => p_src_accountid,
                                p_result_balance => v_result_balance,
                                p_transaction_time => v_effective_time );

  i_adjust_balance ( p_accountid => p_accountid,
                     p_balance => v_result_balance );

  i_commit ( p_do_commit );

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

begin

  i_assert_amount ( p_amount );
  -- there is need to lock two accounts simultaneously 
  --    avoid deadlock in case of opposit transfer at the same moment
  select ac.accountid
    bulk collect into v_ids
    from accounts ac
   where ac.accountid in ( p_src_accountid, p_trg_accountid )
   order by ac.accountid
     for update of ac.accountid;

  withdraw ( p_accountid => p_src_accountid,
             p_amount => p_amount,
             p_lock_flg => false,
             p_do_commit => false,
             p_effective_time => v_effective_time );  -- p_trg_accountid => p_trg_accountid

  deposit ( p_accountid => p_trg_accountid,
            p_amount => p_amount,
            p_lock_flg => false,
            p_do_commit => false,
            p_effective_time => v_effective_time ); -- p_src_accountid => p_src_accountid

  i_commit ( p_commit );

end transfer;

function calc_earned_percents
           ( p_accountid number,
             p_time_from timestamp with local time zone,
             p_time_to timestamp with local time zone,
             p_interest_rate number )
return number
is
begin
  null;
end calc_earned_percents;

/**/
end account_api;
/