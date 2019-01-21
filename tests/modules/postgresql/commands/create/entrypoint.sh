#!/bin/sh
PG_TEMP="/var/run/postgresql/__POSTGRESQL__-main.pg_stat_tmp/"
mkdir -p $PG_TEMP
chown postgres:postgres $PG_TEMP
exec runuser postgres -c  "/usr/lib/postgresql/__POSTGRESQL__/bin/postgres -c data_directory=/data -D /etc/postgresql/__POSTGRESQL__/main -d 5"
