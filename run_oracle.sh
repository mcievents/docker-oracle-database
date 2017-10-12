#!/bin/bash
set -e

# Check container memory
if [ `cat /sys/fs/cgroup/memory/memory.limit_in_bytes | wc -c` -lt 11 ]; then
    if [ `cat /sys/fs/cgroup/memory/memory.limit_in_bytes` -lt 2147483648 ]; then
        echo "ERROR: Insufficient memory in container."
        exit 1
    fi
fi

# Check ORACLE_SID
if [ "$ORACLE_SID" == "" ]; then
    export ORACLE_SID=ORCLCDB
else
    if [ "${#ORACLE_SID}" -gt 12 ]; then
        echo "ERROR: ORACLE_SID maximum length is 12 characters."
        exit 1
    fi

    if [[ "$ORACLE_SID" =~ [^a-zA-Z0-9] ]]; then
        echo "ERROR: ORACLE_SID must be alphanumeric."
        exit 1
    fi
fi

# These are generated database configuration files that will be moved into the
# Docker data volume and symlinked back into place.
configFiles=(
    $ORACLE_HOME/dbs/spfile$ORACLE_SID.ora
    $ORACLE_HOME/dbs/orapw$ORACLE_SID
    $ORACLE_HOME/network/admin/sqlnet.ora
    $ORACLE_HOME/network/admin/listener.ora
    $ORACLE_HOME/network/admin/tnsnames.ora
)

# Move database configuration files into the Docker data volume.
function moveFiles {
    if [ ! -d $ORACLE_BASE/oradata/dbconfig/$ORACLE_SID ]; then
        mkdir -p $ORACLE_BASE/oradata/dbconfig/$ORACLE_SID
    fi

    for f in ${configFiles[@]}; do
        mv $f $ORACLE_BASE/oradata/dbconfig/$ORACLE_SID/
    done

    cp /etc/oratab $ORACLE_BASE/oradata/dbconfig/$ORACLE_SID/

    symLinkFiles;
}

# Symlink database configuration files.
function symLinkFiles {
    for f in ${configFiles[@]}; do
        if [ ! -L $f ]; then
            ln -s $ORACLE_BASE/oradata/dbconfig/$ORACLE_SID/${f##*/} $f
        fi
    done

    cp $ORACLE_BASE/oradata/dbconfig/$ORACLE_SID/oratab /etc/oratab
}

# Set up signal handlers
function shutdownImmediate {
    echo "Stopping database."
    sqlplus / as sysdba <<EOF
    shutdown immediate;
    exit;
EOF
    echo "Stopping listener."
    lsnrctl stop
}

function shutdownAbort {
    echo "Killing database."
    sqlplus / as sysdba <<EOF
    shutdown abort;
    exit;
EOF
    echo "Stopping listener."
    lsnrctl stop
}

trap shutdownImmediate SIGINT SIGTERM
trap shutdownAbort SIGKILL

# Check if database exists
if [ -d $ORACLE_BASE/oradata/$ORACLE_SID ]; then
    echo "Using existing database $ORACLE_SID."
    # It does.
    symLinkFiles;

    if [ ! -d $ORACLE_BASE/admin/$ORACLE_SID/adump ]; then
        mkdir -p $ORACLE_BASE/admin/$ORACLE_SID/adump
    fi

    # Start the database
    $ORACLE_BASE/start_oracle.sh
else
    # It does not.  Create it.
    # Remove database config files, if they exist
    echo "Creating new database $ORACLE_SID."
    rm -f \
        $ORACLE_HOME/dbs/spfile$ORACLE_SID.ora \
        $ORACLE_HOME/dbs/orapw$ORACLE_SID \
        $ORACLE_HOME/network/admin/sqlnet.ora \
        $ORACLE_HOME/network/admin/listener.ora \
        $ORACLE_HOME/network/admin/tnsnames.ora

    # Create database
    $ORACLE_BASE/create_db.sh
    moveFiles;

    # Execute custom setup scripts
    $ORACLE_BASE/run_user_scripts.sh $ORACLE_BASE/scripts/setup
fi

# Verify database is running.
$ORACLE_BASE/check_db_status.sh
if [ $? -eq 0 ]; then
    echo "Database is ready to use."

    # Run custom startup scripts
    $ORACLE_BASE/run_user_scripts.sh $ORACLE_BASE/scripts/startup
else
    echo "ERROR: Database setup was not successful."
fi

echo "Alert log:"
tail -f $ORACLE_BASE/diag/rdbms/*/*/trace/alert*.log &
childPID=$!
wait $childPID
