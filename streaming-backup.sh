#!/bin/bash
#
# ----- Config start -----
timestamp=`date +%Y%m%d%H%M%S`
s3_bucket=${S3_BUCKET}
password_file=${PASSWORD_FILE:-~/.pass}
pgpass_file=${PGPASS_FILE:-~/.pgpass}

if [ -z "$s3_bucket" ]; then
    echo "Specify S3 destination bucket in S3_BUCKET variable..."
    exit 1
fi

if [ ! -f "${password_file}" ]; then
    echo "Password file ${password_file} does not exist..."
    exit 1
fi

if [ ! -f "${pgpass_file}" ]; then
    echo "PGPass file ${pgpass_file} does not exist..."
    exit 1
fi

echo Using configuration
echo -------------------
echo     S3 Bucket: ${s3_bucket}
echo Password file: ${password_file}
echo   PGPass file: ${pgpass_file}
# ----- Config end -----

# NO USER SERVICABLE PARTS AFTER THIS POINT

echo Processing...
for i in `cat ${pgpass_file}`;do
	OFS=$IFS
	IFS=:
	read -ra FIELDS <<< "$i"
	db_host=${FIELDS[0]}
	db_port=${FIELDS[1]}
	db_name=${FIELDS[2]}
	db_user=${FIELDS[3]}
	db_password=${FIELDS[4]}
	db_service=${FIELDS[5]}
        ignore=${FIELDS[6]}
	if [ -n "$1" ]; then
		if [ "$1" != "${db_service}" ]; then
			echo "Skipping ${db_service}"
			continue
		fi
		if [ "ignore" == "${ignore}" ]; then
                        echo "Ignoring ${db_service}"
			continue
		fi
	fi

	outfile=${db_service}-${timestamp}.gz.aes
	echo Backing up stream to s3://${s3_bucket}/${outfile} ...
	pg_dump -h ${db_host} -p ${db_port} -U ${db_user} ${db_name} | gzip | openssl enc -aes-256-cbc -e -pass file:${password_file} | s3cmd put - s3://${s3_bucket}/${outfile} --no-encrypt
	IFS=$OFS
done
