#!/bin/sh
kill -HUP $(head -1 /var/run/postgresql/__POSTGRESQL__-main.pid)
