#!/bin/bash

set -e
set -u

function user_exists() {
	if [[ -n $1 ]]; then
		[[ -n $(psql -qtA --username "$POSTGRES_USER" -d "$POSTGRES_DB" -c "\du ${1}" | cut -d "|" -f 1) ]] && echo 1 || echo 0
	else
	  echo 0
	fi
}

function alter_role(){
	psql -v ON_ERROR_STOP=1 -q --username "$POSTGRES_USER" <<-EOSQL
GRANT ALL PRIVILEGES ON DATABASE $1 TO $2;
EOSQL
}

function create_db() {
	psql -v ON_ERROR_STOP=1 -q --username "$POSTGRES_USER" <<-EOSQL
DO \$$
BEGIN
    IF NOT EXISTS(
        SELECT datname
          FROM pg_catalog.pg_database
          WHERE datname = '$1'
      )
    THEN
      EXECUTE "CREATE DATABASE '$1'";
    ELSE
      RAISE NOTICE 'DB $1 exists. Skipping ....';
    END IF;
END
\$$;
EOSQL
	alter_role "$1" "$2"
}

function create_schema() {
	psql -v ON_ERROR_STOP=1 -q --username "$POSTGRES_USER" <<-EOSQL
\connect $1;

DO \$$
BEGIN
    IF NOT EXISTS(
        SELECT schema_name
          FROM information_schema.schemata
          WHERE schema_name = '$2'
      )
    THEN
      EXECUTE 'CREATE SCHEMA $2 AUTHORIZATION $3';
      RAISE NOTICE 'Schema $2 Created';
    ELSE
      RAISE NOTICE 'Schema $2 exists. Skipping ....';
    END IF;
END
\$$;
EOSQL
}

function create_user() {
	psql -v ON_ERROR_STOP=1 -q --username "$POSTGRES_USER" <<-EOSQL
DO
\$$
BEGIN
	CREATE ROLE $1 LOGIN PASSWORD '$2';
	EXCEPTION WHEN DUPLICATE_OBJECT THEN
		RAISE NOTICE '$1 exists, skipping...';
END
\$$;
EOSQL
}

function create_user_and_database() {
	local database
	local owner
	local password
  local user_exists_result

	database=$( (echo "$1" | tr ',' ' ' | awk '{print $1}') | tr '[:upper:]' '[:lower:]')
	owner=$( (echo "$1" | tr ',' ' ' | awk '{print $2}') | tr '[:upper:]' '[:lower:]')
  password=$(echo "$1" | tr ',' ' ' | awk '{print $4}')

	if [[ $password == '' ]]; then
	  password="$POSTGRES_PASSWORD"
  fi
  if [[ $owner == '' ]]; then
	  owner="$POSTGRES_USER"
  fi
	printf "\n\tCreating database '%s' for user '%s'\n" "$database" "$owner"

	user_exists_result=$(user_exists "$owner")
	if [[ $user_exists_result == 0 ]]; then
	  printf "\tUser '%s' Not found! Creating ...\n" "$owner"
  	create_user "$owner" "$password"
  else
    printf "\tUser '%s' already exists! Skipping creation ...\n" "$owner"
  fi
	create_db "$database" "$owner"
}


function create_schema_for_db_user() {
	local database
	local schema
	local owner
	local password
	local user_exists_result

	database=$( (echo "$1" | tr ',' ' ' | awk '{print $1}') | tr '[:upper:]' '[:lower:]')
	schema=$( (echo "$1" | tr ',' ' ' | awk '{print $2}') | tr '[:upper:]' '[:lower:]')
	owner=$( (echo "$1" | tr ',' ' ' | awk '{print $3}') | tr '[:upper:]' '[:lower:]')
	password=$(echo "$1" | tr ',' ' ' | awk '{print $4}')

	if [[ $password == '' ]]; then
	  password="$POSTGRES_PASSWORD"
  fi
  if [[ $owner == '' ]]; then
	  owner="$POSTGRES_USER"
  fi
	printf "\n\tCreating schema '%s' for database '%s' with user '%s'\n" "$schema" "$database" "$owner"

	user_exists_result=$(user_exists "$owner")

	if [[ $user_exists_result == 0 ]]; then
	  printf "\tUser '%s' Not found! Creating ...\n" "$owner"
  	create_user "$owner" "$password"
  else
    printf "\tUser '%s' already exists! Skipping creation ...\n" "$owner"
  fi
	create_db "$database" "$owner"
	create_schema "$database" "$schema" "$owner"
}
if [ ! -z ${POSTGRES_MULTIPLE_DATABASES+x} ] && [ -n "$POSTGRES_MULTIPLE_DATABASES" ]; then
  printf "\n\e[1m\e[3m*** Multiple database creation requested: '%s'\e[0m\e[0m\n" "$POSTGRES_MULTIPLE_DATABASES"
  for db in $(echo "$POSTGRES_MULTIPLE_DATABASES" | tr ':' ' '); do
  create_user_and_database "$db"
  done
  printf "\n\n\t-- \t Multiple databases created \t --\n\n"
fi
if [ ! -z ${POSTGRES_SCHEMAS+x} ] && [ -n "$POSTGRES_SCHEMAS" ]; then
  printf "\n\e[1m\e[3m*** Schema creation requested: '%s'\e[0m\e[0m\n" "$POSTGRES_SCHEMAS"
  for schema_input in $(echo "$POSTGRES_SCHEMAS" | tr ':' ' '); do
  create_schema_for_db_user "$schema_input"
  done
  printf "\n\n\t-- \t Schemas created \t --\n\n"
fi
