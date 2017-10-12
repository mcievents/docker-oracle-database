FROM oraclelinux:7-slim

ARG ORACLE_EDITION=EE
ARG DOWNLOAD_URL_BASE
ARG INSTALL_FILE=linuxx64_12201_database.zip
ARG INSTALL_FILE_SHASUM=96ed97d21f15c1ac0cce3749da6c3dac7059bb60672d76b008103fc754d22dde

ENV ORACLE_BASE=/opt/oracle
ENV ORACLE_HOME=$ORACLE_BASE/product/12.2.0.1/dbhome_1
ENV ORACLE_SID=ORCLCDB \
    ORACLE_PDB=ORCLPDB1 \
    ORACLE_PWD= \
    INSTALL_DIR=$ORACLE_BASE/install \
    PATH=$ORACLE_HOME/bin:$ORACLE_HOME/OPatch:/usr/sbin:$PATH \
    LD_LIBRARY_PATH=$ORACLE_HOME/lib \
    CLASSPATH=$ORACLE_HOME/jlib:$ORACLE_HOME/rdbms/jlib

COPY db_inst.rsp linux_setup.sh check_space.sh install_oracle_binaries.sh $INSTALL_DIR/

RUN chmod ug+x $INSTALL_DIR/*.sh \
    && $INSTALL_DIR/check_space.sh \
    && $INSTALL_DIR/linux_setup.sh

USER oracle
RUN $INSTALL_DIR/install_oracle_binaries.sh

USER root
RUN $ORACLE_BASE/oraInventory/orainstRoot.sh \
    && $ORACLE_HOME/root.sh \
    && rm -rf $INSTALL_DIR

COPY --chown=oracle:dba run_oracle.sh start_oracle.sh create_db.sh dbca.rsp.tmpl check_db_status.sh run_user_scripts.sh $ORACLE_BASE/
RUN chmod ug+x $ORACLE_BASE/*.sh

USER oracle
WORKDIR /home/oracle

VOLUME ["$ORACLE_BASE/oradata"]
EXPOSE 1521 5500

CMD $ORACLE_BASE/run_oracle.sh
