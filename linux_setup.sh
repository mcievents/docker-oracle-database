#!/bin/bash
set -e

mkdir -p $ORACLE_BASE/scripts/setup
mkdir $ORACLE_BASE/scripts/startup
mkdir $ORACLE_BASE/oradata

yum -y install \
    oracle-database-server-12cR2-preinstall \
    unzip \
    tar \
    openssl \
    wget
yum clean all

chown -R oracle:dba $ORACLE_BASE

ln -s $ORACLE_BASE/scripts /docker-entrypoint-initdb.d
