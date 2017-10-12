#!/bin/bash
set -e

# Verify ORACLE_HOME
if [ "$ORACLE_HOME" == "" ]; then
    echo "ERROR: ORACLE_HOME is not set."
    exit 1
fi

# Verify ORACLE_SID
if [ "$ORACLE_SID" == "" ]; then
    echo "ERROR: ORACLE_SID is not set."
    exit 1
fi

# check oracle db status and store it in status
status=`sqlplus -s / as sysdba << EOF
   set heading off;
   set pagesize 0;
   select status from v\\$instance;
   exit;
EOF`

# store return code from sql*plus
ret=$?

if [ $ret -eq 0 ] && [ "$status" = "OPEN" ]; then
    # sqlplus execution was successful and database is open
    exit 0;
elif [ "$status" != "OPEN" ]; then
    # database is not open
    exit 1
else
    # sqlplus execution failed
    exit 2
fi
