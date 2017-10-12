# Running the image

This image contains the binaries for Oracle 12c R2 Enterprise or Standard Edition Two.  On first run, it will create a database.  It will store configuration, control, log, and data files in the volume mounted at `$ORACLE_BASE/oradata`.  On subsequent runs, it will notice that this database already exists and use the existing database.  

These environment variables can be used to manage the database:

*   `ORACLE_SID`: The SID of the database instance.  Default: `ORCLCDB`.
*   `ORACLE_PDB`: The service name of the (only) pluggable database.  Default: `ORCLPDB1`.
*   `ORACLE_PWD`: The password to set for the SYS, SYSTEM, and PDBADMIN accounts.  If not set then a random password will be generated and printed to standard output.

You may want to increase the size of `/dev/shm`.

Run example:

```shell
docker run -d --shm-size=1g --name oracle oracle-database:12.2.0.1-ee
```

# Building the image

Building the image downloads the Oracle Database installer and installs the Oracle Database binaries.

There is one required build argument: the location from which to download the Oracle installer.

*   `DOWNLOAD_URL_BASE`: The base URL from which the installer can be downloaded.

The following build arguments can also be used:

*   `INSTALL_FILE`: The name of the Oracle installer archive.
*   `INSTALL_FILE_SHASUM`: The SHA256 binary checksum of the Oracle installer archive.
*   `ORACLE_EDITION`: The Edition of Oracle to install.  Must be one of `EE` (Enterprise Edition) or `SE2` (Standard Edition Two).  Default: `EE`

Build example:

```shell
docker build -t oracle-database:12.2.0.1-ee \
    --build-arg DOWNLOAD_URL_BASE=https://s3.amazonaws.com/path/to/installer/dir \
    --build-arg ORACLE_EDITION=SE2 \
    .
```
