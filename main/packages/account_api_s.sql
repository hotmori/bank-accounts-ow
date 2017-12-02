create or replace package account_api is

DAY_HOUR_OFFSET constant number := 8;

function to_days
           ( itvl in dsinterval_unconstrained ) return number;

-- get business day start for timestamp
function normalize_to_bs_day_start
           ( p_timestamp timestamp with local time zone,
             p_hour_offset number default DAY_HOUR_OFFSET ) return timestamp with local time zone;

procedure create_account
           ( p_accountid number,
             p_display_name nvarchar2 );

-- ATTENTION! 
-- p_effective_time is used for test only purposes ( withdraw, deposit, transfer )
--   to generate test data in the past
--   use carefully

procedure withdraw
            ( p_accountid number,
              p_amount number,
              p_do_commit boolean default false,
              p_effective_time timestamp with local time zone default null );

procedure deposit
            ( p_accountid number,
              p_amount number,
              p_do_commit boolean default false,
              p_effective_time timestamp with local time zone default null );

procedure transfer
            ( p_src_accountid number,
              p_trg_accountid number,
              p_amount number,
              p_commit boolean default false,
              p_effective_time timestamp with local time zone default null );

-- p_time_to can be set to future
--   last effective balance will be taken in that case
function calc_earned_percents
           ( p_accountid number,
             p_time_from timestamp with local time zone,
             p_time_to timestamp with local time zone,
             p_interest_rate number ) return number;

end;
/