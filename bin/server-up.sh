#!/bin/sh
set -e

echo "Running server-up.sh"

echo "Validating DB envs ..."
if [ -z "$DB_NAME" ] || [ -z "$DB_HOST" ] || [ -z "$DB_USER" ] || [ -z "$DB_PASS" ]; then
  echo "Error: One or more DB env are missing"
  exit 1
fi

echo "Ensuring database exists ..."
echo "SELECT 'CREATE DATABASE ${DB_NAME}' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = '${DB_NAME}')\gexec" | \
PGPASSWORD="${DB_PASS}" psql --username="${DB_USER}" --host="${DB_HOST}"
unset PGPASSWORD

echo "Running migration / seeds ..."
/usr/src/app/_release/bin/stone eval "Stone.Release.run()"

echo "Starting release ..."
/usr/src/app/_release/bin/stone start
