FROM postgres:latest
COPY create-custom-postgresql.sh /docker-entrypoint-initdb.d/
