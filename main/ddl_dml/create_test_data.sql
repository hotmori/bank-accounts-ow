declare 
  v_accountid number := 1010;

begin
  delete from account_transactions op where op.accountid = v_accountid;
  delete from accounts a where a.accountid = v_accountid;

  v_accountid := account_api.create_account( p_accountid => v_accountid, p_display_name => 'My First account');

  account_api.deposit(p_accountid => v_accountid, p_amount => 100, p_effective_time => to_timestamp('2016/01/01 10:00:00', 'YYYY/MM/DD HH:MI:SS'));
  account_api.deposit(p_accountid => v_accountid, p_amount => 750, p_effective_time => to_timestamp('2017/11/01 10:00:00', 'YYYY/MM/DD HH:MI:SS'));
  account_api.deposit(p_accountid => v_accountid, p_amount => 100, p_effective_time => to_timestamp('2017/11/03 07:30:00', 'YYYY/MM/DD HH:MI:SS'));
  account_api.deposit(p_accountid => v_accountid, p_amount => 100, p_effective_time => to_timestamp('2017/11/03 07:31:00', 'YYYY/MM/DD HH:MI:SS'));
  account_api.withdraw(p_accountid => v_accountid, p_amount => 20, p_effective_time => to_timestamp('2017/11/03 07:59:00', 'YYYY/MM/DD HH:MI:SS'));
  account_api.deposit(p_accountid => v_accountid, p_amount => 100, p_effective_time => to_timestamp('2017/11/03 07:59:59', 'YYYY/MM/DD HH:MI:SS'));
  account_api.deposit(p_accountid => v_accountid, p_amount => 100, p_effective_time => to_timestamp('2017/11/03 10:00:00', 'YYYY/MM/DD HH:MI:SS'));
  account_api.deposit(p_accountid => v_accountid, p_amount => 100, p_effective_time => to_timestamp('2017/11/03 10:01:00', 'YYYY/MM/DD HH:MI:SS'));
  account_api.deposit(p_accountid => v_accountid, p_amount => 150, p_effective_time => to_timestamp('2017/11/05 10:00:00', 'YYYY/MM/DD HH:MI:SS'));
  account_api.withdraw(p_accountid => v_accountid, p_amount => 100, p_effective_time => to_timestamp('2017/11/07 10:00:00', 'YYYY/MM/DD HH:MI:SS'));
  account_api.deposit(p_accountid => v_accountid, p_amount => 100, p_effective_time => to_timestamp('2017/11/07 10:30:00', 'YYYY/MM/DD HH:MI:SS'));
  account_api.deposit(p_accountid => v_accountid, p_amount => 100, p_effective_time => to_timestamp('2017/11/08 10:30:00', 'YYYY/MM/DD HH:MI:SS'));
  account_api.deposit(p_accountid => v_accountid, p_amount => 100, p_effective_time => to_timestamp('2017/11/09 07:30:00', 'YYYY/MM/DD HH:MI:SS'));
  account_api.deposit(p_accountid => v_accountid, p_amount => 100, p_effective_time => to_timestamp('2017/11/13 07:30:00', 'YYYY/MM/DD HH:MI:SS'));

end;
/

