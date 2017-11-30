bank-accounts-ow:
Oracle database demo patch (bank accounts table structures, PL/SQL API, examples of queries)

Description
===========
1. Test schema will be created for all DB objects
2. Tables will be created: accounts, account_transactions, transaction_types
3. Package will be created: account_api
4. Examples of queries are here: main/queries/

Deployment instruction
======================
1. Execute sqlplus /nolog @main.sql <db_tns_name> <test_schema_name> (for example "sqlplus /nolog @main.sql ora_db1 dmitryi_test")
   and enter SYSTEM password after the prompt.

2. Check logfile main_<db_tns_name>_<test_schema_name>.log for errors.


Rollback instruction
====================
1. Execute sqlplus /nolog @rback.sql <db_tns_name> <test_schema_name> (for example "sqlplus /nolog @rback.sql ora_db1 dmitryi_test")
   and enter SYSTEM password after the prompt.

2. Check logfile rback_<db_tns_name>_<test_schema_name>.log for errors.