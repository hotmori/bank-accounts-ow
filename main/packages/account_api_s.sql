create or replace package account_api is

function create_account
           ( p_accountid number,
             p_display_name nvarchar2 )
return number;

procedure withdraw
            ( p_accountid number,
              p_amount number,
              p_trg_accountid number default null,
              p_lock_flg boolean default true,
              p_do_commit boolean default false,
              p_effective_time timestamp with local time zone default null );

procedure deposit
            ( p_accountid number,
              p_amount number,
              p_src_accountid number default null,
              p_lock_flg boolean default true,
              p_do_commit boolean default false,
              p_effective_time timestamp with local time zone default null );

procedure transfer
            ( p_src_accountid number,
              p_trg_accountid number,
              p_amount number,
              p_commit boolean default false,
              p_effective_time timestamp with local time zone default null );

end;
/