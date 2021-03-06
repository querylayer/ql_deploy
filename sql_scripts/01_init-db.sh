#!/bin/bash
set -e

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    CREATE DATABASE bank;
    CREATE DATABASE datasource;
    CREATE USER ql_user WITH PASSWORD CHANGEME;
    GRANT CONNECT ON DATABASE bank to ql_user;
EOSQL

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "bank" <<-EOSQL
    CREATE EXTENSION anon_func;
    CREATE TABLE credit_cards( CUST_ID VARCHAR(50) NOT NULL, BALANCE REAL, BALANCE_FREQUENCY REAL, PURCHASES REAL, ONEOFF_PURCHASES REAL, INSTALLMENTS_PURCHASES REAL, CASH_ADVANCE REAL, PURCHASES_FREQUENCY REAL, ONEOFF_PURCHASES_FREQUENCY REAL, PURCHASES_INSTALLMENTS_FREQUENCY REAL, CASH_ADVANCE_FREQUENCY REAL, CASH_ADVANCE_TRX REAL, PURCHASES_TRX REAL, CREDIT_LIMIT REAL, PAYMENTS REAL, MINIMUM_PAYMENTS REAL, PRC_FULL_PAYMENT REAL, TENURE REAL );
    GRANT USAGE ON SCHEMA public TO ql_user;
    GRANT SELECT ON public.credit_cards TO ql_user;
    COPY credit_cards FROM '/docker-entrypoint-initdb.d/dummy.csv' WITH (FORMAT csv);
EOSQL


psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "datasource" <<-EOSQL
    CREATE EXTENSION anon_func;
EOSQL
