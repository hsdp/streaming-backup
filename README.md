# streaming-backup.sh

## Description
This script dumps all the PostgreSQL databases as defined in your ~/.pgpass
file to the specified Amazon S3 bucket. The standard pgpass line
mut be augmented with an addition field that specifies your (micro)-service name
This is needed because quite a few database within HSDP get the name `hsdp_pg`
The dumps are gzipped and AES encrypted using OpenSSL.

## Dependencies
* `pg_dump` -- minumum 9.6
* `gzip`
* `openssl` -- minimum 1.0.1
* `s3cmd` -- minimum 1.6.0

## Configuration variables

`S3_BUCKET`: The S3 bucket to push the archives to

`PASSWORD_FILE`: First line of this file should contain a strong 20+ character password -- default ~/.pass

`PGPASS_FILE`: The pgpass file -- default ~/.pgpass

## pgpass file

See https://www.postgresql.org/docs/10/static/libpq-pgpass.html for details

This scripts expects an additional field which specifies the backup filename prefix:

`hostname:port:database:username:password:someprefix`

## How does it work?
For each entry in ~/.pgpass the script creates a PostgreSQL dump that is
compressed using gzip and encrypted using OpenSSL. The resulting archive is then pushed
to the S3 bucket for safe keeping. Decrypting and restoring the content is out of scope.
Nonetheless below is an example for getting back the plain `pg_dump` file:

```
$ openssl enc -in ${some_file.gz.aes} -aes-256-cbc -d -pass file:${password_file} |gzip -d > ${pg_dump_file}
```

Author
======
Andy Lo-A-Foe <andy.lo-a-foe@philips.com>

License
=======
License is MIT

References
==========
* [libpq-pgpass](https://www.postgresql.org/docs/current/libpq-pgpass.html)
* [app-pgdump](https://www.postgresql.org/docs/current/static/app-pgdump.html)
