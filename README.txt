# bank-accounts-ow

Demo bank accounts structures and PL/SQL api

Instructions

0. Connect to oracle db into schema
1. From root dir (account_home_task) execute sqlplus @main.sql <TNSNAME> on all units;
2. Check logfile SWT-6941_fix_UK_15_day_trials_<TNSNAME>.log for errors;

Roll-back Instructions

1. From svn://svn.dins.ru/Vportal/branches/db-patches/20173101_SWT-6941_fix_UK_15_day_trials execute sqlplus /nolog @rback.sql <TNSNAME> on all units;
2. Check logfile SWT-6941_fix_UK_15_day_trials_rback_<TNSNAME>.log for errors.