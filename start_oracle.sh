#!/bin/bash
set -e

# Check that ORACLE_HOME is set
if [ "$ORACLE_HOME" == "" ]; then
    echo "ERROR: ORACLE_HOME is not set."
    exit 1
fi

# Start listener
lsnrctl start

# Start database
sqlplus / as sysdba << EOF
   startup;
   exit;
EOF
