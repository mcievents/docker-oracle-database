#!/bin/bash
set -e

if [ "$DOWNLOAD_URL_BASE" == "" ]; then
    echo "ERROR: Must specify a download location for Oracle binaries."
    exit 1
fi

if [ "$ORACLE_EDITION" == "" ]; then
    echo "ERROR: Must specify an Oracle edition to install."
    exit 1
fi

if [ "$ORACLE_EDITION" != "EE" -a "$ORACLE_EDITION" != "SE2" ]; then
    echo "ERROR: $ORACLE_EDITION is not a valid Oracle edition specifier."
    exit 1
fi

if [ "$ORACLE_BASE" == "" ]; then
    echo "ERROR: ORACLE_BASE has not been set."
    exit 1
fi

if [ "$ORACLE_HOME" == "" ]; then
    echo "ERROR: ORACLE_HOME has not been set."
    exit 1
fi

# Update placeholders in installer response file
sed -i \
    -e "s|###ORACLE_EDITION###|$ORACLE_EDITION|g" \
    -e "s|###ORACLE_BASE###|$ORACLE_BASE|g" \
    -e "s|###ORACLE_HOME###|$ORACLE_HOME|g" \
    $INSTALL_DIR/db_inst.rsp

cd $INSTALL_DIR
wget $DOWNLOAD_URL_BASE/$INSTALL_FILE
echo "$INSTALL_FILE_SHASUM *$INSTALL_FILE" | sha256sum -c
unzip $INSTALL_FILE
rm $INSTALL_FILE

./database/runInstaller -silent -force -waitforcompletion \
    -responsefile $INSTALL_DIR/db_inst.rsp \
    -ignoresysprereqs -ignoreprereq

# Remove unneeded components
rm -rf \
    $ORACLE_HOME/apex \
    $ORACLE_HOME/jdbc \
    $ORACLE_HOME/lib/ra*.zip \
    $ORACLE_HOME/ords \
    $ORACLE_HOME/sqldeveloper \
    $ORACLE_HOME/ucp \
    $ORACLE_HOME/inventory/backup/* \
    $ORACLE_HOME/network/tools/help/mgr/help_* \
    /tmp/* \
    $INSTALL_DIR/database
