#!/bin/bash
set -e

# Set ORACLE_SID default.
export ORACLE_SID=${ORACLE_SID:-ORCLCDB}

# Set ORACLE_PDB default.
export ORACLE_PDB=${ORACLE_PDB:-ORCLPDB1}

# Set ORACLE_PWD default.
if [ -z "$ORACLE_PWD" ]; then
    if [ -f /run/secrets/oracle_admin_password ]; then
        export ORACLE_PWD=`cat /run/secrets/oracle_admin_password`
        echo 'Oracle admin password read from Docker secret.'
    else
        export ORACLE_PWD=${ORACLE_PWD:-"`openssl rand -base64 12`"}
        echo 'Generated random Oracle admin password.'
        echo "ORACLE PASSWORD FOR SYS, SYSTEM AND PDBADMIN: $ORACLE_PWD"
    fi
else
    echo 'Oracle admin password read from environment.'
fi

mkdir -p $ORACLE_BASE/oradata/$ORACLE_SID

# Set ORACLE_CHARACTERSET default.
export ORACLE_CHARACTERSET=${ORACLE_CHARACTERSET:-AL32UTF8}

# Replace place holders in response file
cp $ORACLE_BASE/dbca.rsp.tmpl $ORACLE_BASE/dbca.rsp
sed -i \
    -e "s|###ORACLE_SID###|$ORACLE_SID|g" \
    -e "s|###ORACLE_PDB###|$ORACLE_PDB|g" \
    -e "s|###ORACLE_PWD###|$ORACLE_PWD|g" \
    -e "s|###ORACLE_CHARACTERSET###|$ORACLE_CHARACTERSET|g" \
    $ORACLE_BASE/dbca.rsp

# Create network config files (sqlnet.ora, tnsnames.ora, listener.ora)
mkdir -p $ORACLE_HOME/network/admin
echo "NAME.DIRECTORY_PATH= (TNSNAMES, EZCONNECT, HOSTNAME)" > $ORACLE_HOME/network/admin/sqlnet.ora

# Listener.ora
echo "LISTENER = 
(DESCRIPTION_LIST = 
  (DESCRIPTION = 
    (ADDRESS = (PROTOCOL = IPC)(KEY = EXTPROC1)) 
    (ADDRESS = (PROTOCOL = TCP)(HOST = 0.0.0.0)(PORT = 1521)) 
  ) 
) 

DEDICATED_THROUGH_BROKER_LISTENER=ON
DIAG_ADR_ENABLED = off
" > $ORACLE_HOME/network/admin/listener.ora

# Start LISTENER and run DBCA
lsnrctl start

dbca -silent -createDatabase -responseFile $ORACLE_BASE/dbca.rsp ||
    cat /opt/oracle/cfgtoollogs/dbca/$ORACLE_SID/$ORACLE_SID.log ||
    cat /opt/oracle/cfgtoollogs/dbca/$ORACLE_SID.log

echo "$ORACLE_SID=localhost:1521/$ORACLE_SID" > $ORACLE_HOME/network/admin/tnsnames.ora
echo "$ORACLE_PDB= 
(DESCRIPTION = 
  (ADDRESS = (PROTOCOL = TCP)(HOST = 0.0.0.0)(PORT = 1521))
  (CONNECT_DATA =
    (SERVER = DEDICATED)
    (SERVICE_NAME = $ORACLE_PDB)
  )
)" >> $ORACLE_HOME/network/admin/tnsnames.ora

# Remove second control file, make PDB auto open
sqlplus / as sysdba << EOF
   ALTER SYSTEM SET control_files='$ORACLE_BASE/oradata/$ORACLE_SID/control01.ctl' scope=spfile;
   ALTER PLUGGABLE DATABASE $ORACLE_PDB SAVE STATE;
   exit;
EOF

# Remove temporary response file
rm $ORACLE_BASE/dbca.rsp
