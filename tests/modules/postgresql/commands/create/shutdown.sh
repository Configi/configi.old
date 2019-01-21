#!/bin/sh
kill -INT $(head -1 /var/run/postgresql/__POSTGRESQL__-main.pid)
