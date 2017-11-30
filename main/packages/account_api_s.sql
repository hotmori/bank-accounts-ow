create or replace package account_api is

procedure create_account
           ( p_accountid number,
             p_display_name nvarchar2 );

-- p_effective_time is used for test only purposes
--   to generate test data in the past
procedure withdraw
            ( p_accountid number,
              p_amount number,
              p_do_commit boolean default false,
              p_effective_time timestamp with local time zone default null );

-- p_effective_time is used for test only purposes
--   to generate test data in the past
procedure deposit
            ( p_accountid number,
              p_amount number,
              p_do_commit boolean default false,
              p_effective_time timestamp with local time zone default null );

-- p_effective_time is used for test only purposes
--   to generate test data in the past
procedure transfer
            ( p_src_accountid number,
              p_trg_accountid number,
              p_amount number,
              p_commit boolean default false,
              p_effective_time timestamp with local time zone default null );

end;
/