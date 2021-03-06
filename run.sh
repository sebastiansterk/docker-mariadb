#!/bin/sh
set -e

if [ ! -d "/run/mysqld" ]; then
	mkdir -p /run/mysqld
	chown -R mysql:mysql /run/mysqld
fi

if [ -d /var/lib/mysql/mysql ]; then
	echo "[i] MySQL directory already present, skipping creation"
else
	echo "[i] MySQL data directory not found, creating initial DBs"

	chown -R mysql:mysql /var/lib/mysql

	mysql_install_db --user=mysql --datadir=/var/lib/mysql > /dev/null

	if [ "$MYSQL_ROOT_PASSWORD" = "" ]; then
		MYSQL_ROOT_PASSWORD=`pwgen 16 1`
		echo "[i] MySQL root Password: $MYSQL_ROOT_PASSWORD"
	fi

	MYSQL_DATABASE=${MYSQL_DATABASE:-""}
	MYSQL_USER=${MYSQL_USER:-""}
	MYSQL_PASSWORD=${MYSQL_PASSWORD:-""}

	tf=$(mktemp)
	if [ ! -f "$tf" ]; then
		return 1
	fi

	cat << EOF > $tf
USE mysql;
FLUSH PRIVILEGES ;
GRANT ALL ON *.* TO 'root'@'%' identified by '$MYSQL_ROOT_PASSWORD' WITH GRANT OPTION ;
GRANT ALL ON *.* TO 'root'@'localhost' identified by '$MYSQL_ROOT_PASSWORD' WITH GRANT OPTION ;
SET PASSWORD FOR 'root'@'localhost'=PASSWORD('${MYSQL_ROOT_PASSWORD}') ;
DROP DATABASE IF EXISTS test ;
FLUSH PRIVILEGES ;
EOF
        if [ "${MYSQL_DATABASE}" != "" ]; then
                echo "[i] Creating database: ${MYSQL_DATABASE}"
                echo "CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\` CHARACTER SET utf8 COLLATE utf8_general_ci;" >> $tf

                if [ "${MYSQL_USER}" != "" ]; then
                        echo "[i] Creating user: ${MYSQL_USER} with password ${MYSQL_PASSWORD}"
                        echo "GRANT ALL ON \`${MYSQL_DATABASE}\`.* to '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';" >> $tf
                fi
        fi

        /usr/bin/mysqld --user=mysql --bootstrap --verbose=0 --skip-name-resolve --skip-networking=0 < $tf
        rm -f $tf
fi

exec /usr/bin/mysqld --user=mysql --console --skip-name-resolve --skip-networking=0 
