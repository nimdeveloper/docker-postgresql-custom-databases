# Using multiple databases with the official PostgreSQL Docker image

The [official recommendation](https://hub.docker.com/_/postgres/) for creating
multiple databases is as follows:

*If you would like to do additional initialization in an image derived from
this one, add one or more `*.sql`, `*.sql.gz`, or `*.sh` scripts under
`/docker-entrypoint-initdb.d` (creating the directory if necessary). After the
entrypoint calls `initdb` to create the default `postgres` user and database,
it will run any `*.sql` files and source any `*.sh` scripts found in that
directory to do further initialization before starting the service.*

This directory contains a script to create multiple databases using that
mechanism.

## Usage

### By mounting a volume

Clone the repository, mount its directory as a volume into
`/docker-entrypoint-initdb.d` and declare database names separated by commas in
`POSTGRES_MULTIPLE_DATABASES` and `POSTGRES_SCHEMAS` environment variable as follows
(`docker-compose` syntax):

```yml
myapp-postgresql:
    image: postgres:latest
    volumes:
        - ../docker-postgresql-custom-databases:/docker-entrypoint-initdb.d
    environment:
        - POSTGRES_MULTIPLE_DATABASES=<data>
        - POSTGRES_SCHEMAS=<data>
        - POSTGRES_USER=<data>
        - POSTGRES_PASSWORD=<data>
```

### Using image

`docker-compose` syntax:

```yml
myapp-postgresql:
    image: nimdev/postgresql-custom-databases:latest
    environment:
        - POSTGRES_MULTIPLE_DATABASES=<data>
        - POSTGRES_SCHEMAS=<data>
        - POSTGRES_USER=<data>
        - POSTGRES_PASSWORD=<data>
```

## Environment variables



##### POSTGRES_MULTIPLE_DATABASES

- Required: `False`
- Order: 1
- Syntax with password:

    ```bash
    export POSTGRES_MULTIPLE_DATABASES=DB1,User1,Pass1:DB2,User2,Pass2:DB3,User1,Pass1:DB4,User1
    ```

- Syntax without password (`POSTGRES_PASSWORD` will be used instead):

    ```bash
    export POSTGRES_MULTIPLE_DATABASES=DB1,User1:DB2,User2:DB2,User1
    ```

- Syntax without username and password (`POSTGRES_PASSWORD` and `POSTGRES_USER` will be used instead):

    ```bash
    export POSTGRES_MULTIPLE_DATABASES=DB1:DB1:DB2
    ```

- Password, in any part is optional and if user dosen't exist, user will be created with `POSTGRES_PASSWORD` as password

- User specified for databased, will be created in first occurrence with password specified in there. If password is not specified, `POSTGRES_PASSWORD` will be used

- For example in this example, `User1` will be created with password `Pass1` and other passwords (`Pass2`) will be skipped.

    ```bash
    export POSTGRES_MULTIPLE_DATABASES=DB1,User1,Pass1:DB2,User1,Pass2:DB3,User1
    ```

##### POSTGRES_SCHEMAS

- Required: `False`
- Order: 2
- Syntax with password:

    ```bash
    export POSTGRES_SCHEMAS=DB1,Schema1,User1,Pass1:DB1,Schema2,User2,Pass2:DB2,Schema2,User1,Pass1
    ```

- Syntax without password (`POSTGRES_PASSWORD` will be used instead):

    ```bash
    export POSTGRES_SCHEMAS=DB1,Schema1,User1:DB1,Schema2,User2:DB2,Schema2,User1
    ```

- Syntax without username and password (`POSTGRES_PASSWORD` and `POSTGRES_USER` will be used instead):

    ```bash
    export POSTGRES_SCHEMAS=DB1,Schema1:DB1,Schema2:DB2,Schema2
    ```

- Password, in any part is optional and if user dosen't exist, user will be created with `POSTGRES_PASSWORD` as password

- User specified for databased, will be created in first occurrence with password specified in there. If password is not specified, `POSTGRES_PASSWORD` will be used

- For example in this example, `User1` will be created with password `Pass1` and other passwords (`Pass2`) will be skipped.

    ```bash
    export POSTGRES_SCHEMAS=DB1,Schema1,User1,Pass1:DB1,Schema2,User1,Pass2:DB2,Schema2,User2
    ```
