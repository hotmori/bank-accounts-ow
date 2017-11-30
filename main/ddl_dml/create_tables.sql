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
               ( transaction_type varchar2(16) not null,
                 description varchar2(32) not null)
/
comment on table transaction_types is 'Dictionary table.'
/
-----------------------------
-- primary key and indexes --
-----------------------------
alter table transaction_types
  add constraint transaction_types_pk primary key ( transaction_type )
  using index
/
create unique index transaction_types_uk on transaction_types ( upper (transaction_type) )
/
-- ==================== TABLE account_transactions ==================== --
create table account_transactions
               ( account_transactionid number not null,
                 accountid number not null,
                 transaction_type varchar2(16) not null,
                 amount number,
                 result_balance number,
                 src_transactionid number,
                 trg_transactionid number,
                 transaction_time timestamp with local time zone not null
               )
/
comment on table account_transactions is 'Stores all transactions against account.'
/
comment on column account_transactions.amount is 'Amount of that was involved in transaction. Strictly greater than zero.'
/
comment on column account_transactions.result_balance is 'Result balance on account after the transaction.'
/
comment on column account_transactions.src_transactionid is 'Source transactionid if transaction was credit (transfer from another account). No FK for simplicity.'
/
comment on column account_transactions.trg_transactionid is 'Target transactionid if transaction was debit (transfer to another account). No FK for simplicity.'
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
------------------
-- foreign keys --
------------------
alter table account_transactions
  add constraint account_tr_fk foreign key ( accountid )
  references accounts ( accountid )
/
alter table account_transactions
  add constraint account_tr_type_fk foreign key ( transaction_type )
  references transaction_types ( transaction_type )
/
-----------------------
-- check constraints --
-----------------------
alter table account_transactions
  add constraint account_transaction_am_chk
  check ( (transaction_type = 'CREDIT' and amount > 0) or (transaction_type = 'DEBIT' and amount < 0) )
/

alter table account_transactions
  add constraint transaction_transfer_chk
  check ( case when transaction_type = 'DEBIT' and src_transactionid is not null then 0
               when transaction_type = 'CREDIT' and trg_transactionid is not null then 0
          else 1
          end <> 0 )
/

/*
alter table account_transactions
  add constraint transaction_cred_from_chk
  check ( case when transaction_type = 'CREDIT' and trg_transactionid is not null then 0
          else 1
          end <> 0 )
/
*/