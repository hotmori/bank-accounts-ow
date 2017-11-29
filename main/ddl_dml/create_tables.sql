-- ==================== TABLE accounts ==================== --
create table accounts
               ( accountid number not null,
                 display_name nvarchar2(256) not null,
                 balance number not null )
/

comment on table accounts is 'Table stores attributes and current balance of an account.'
/
comment on column accounts.accountid is 'Account internal identifier. PK.'
/
comment on column accounts.display_name is 'Account display name.'
/
comment on column accounts.balance is 'Account current balance, overdraft is not allowed.'
/

-----------------------------
-- primary key and indexes --
-----------------------------
alter table accounts
  add constraint accounts_pk primary key (accountid)
  using index
/
-----------------------
-- check constraints --
-----------------------
alter table accounts
  add constraint accounts_bal_chk
  check ( balance >= 0 )
/

-- ==================== TABLE transaction_types ==================== --
create table transaction_types
               ( transaction_type number(1) not null,
                 description varchar2(32) not null)
/
comment on table transaction_types is 'Dictionary table.'
/
-----------------------------
-- primary key and indexes --
-----------------------------
alter table transaction_types
  add constraint transaction_types_st_pk primary key (transaction_type)
  using index
/

-- ==================== TABLE account_transactions ==================== --
create table account_transactions
               ( account_transactionid number not null,
                 accountid number not null,
                 transaction_type number(1),
                 amount number(10),
                 result_balance number,
                 src_accountid number,
                 trg_accountid number,
                 ref_transactionid number,
                 transaction_time timestamp with local time zone not null
               )
/
comment on table account_transactions is 'Stores all transactions against account.'
/
comment on column account_transactions.amount is 'Amount of that was involved in transaction. Strictly greater than zero.'
/
comment on column account_transactions.result_balance is 'Result balance on account after the transaction.'
/
comment on column account_transactions.src_accountid is 'Source accountid if transaction was credit (transfer from another account).'
/
comment on column account_transactions.trg_accountid is 'Target accountid if transaction was debit (transfer to another account).'
/
comment on column account_transactions.ref_transactionid is 'Rerence to parent transactionid for transfers. Not used for simplicity.'
/
-----------------------------
-- primary key and indexes --
-----------------------------
alter table account_transactions
  add constraint account_transactions_pk primary key (account_transactionid)
  using index
/
create index account_transaction_act_idx on account_transactions ( accountid, transaction_type )
/
-----------------------
-- check constraints --
-----------------------
alter table account_transactions
  add constraint account_transaction_am_chk
  check ( amount > 0 )
/
-- TODO
-- add checks for transfers