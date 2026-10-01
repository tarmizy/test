#!/bin/bash
set -e

: "${MYSQL_ROOT_PASSWORD:=rootpass}"
: "${MYSQL_DATABASE:=mywebsite}"
: "${MYSQL_USER:=appuser}"
: "${MYSQL_PASSWORD:=apppass}"

mkdir -p /run/php /var/run/mysqld /etc/nginx/ssl
chown mysql:mysql /var/run/mysqld
chown -R mysql:mysql /var/lib/mysql

# 1) Sertifikat SSL self-signed untuk mywebsite.local (dibuat sekali saja)
if [ ! -f /etc/nginx/ssl/mywebsite.local.crt ]; then
  echo ">> Generate sertifikat SSL mywebsite.local"
  openssl req -x509 -nodes -newkey rsa:2048 -days 825 \
    -keyout /etc/nginx/ssl/mywebsite.local.key \
    -out    /etc/nginx/ssl/mywebsite.local.crt \
    -subj   "/C=ID/O=Local Dev/CN=mywebsite.local" \
    -addext "subjectAltName=DNS:mywebsite.local"
fi

# 2) Inisialisasi MySQL HANYA jika datadir (volume) masih kosong.
#    Restart berikutnya melewati blok ini -> data tidak hilang.
if [ ! -d /var/lib/mysql/mysql ]; then
  echo ">> Inisialisasi MySQL datadir"
  mysqld --initialize-insecure --user=mysql --datadir=/var/lib/mysql

  mysqld --user=mysql --skip-networking --socket=/var/run/mysqld/mysqld.sock &
  pid=$!
  for i in $(seq 1 30); do
    mysqladmin --socket=/var/run/mysqld/mysqld.sock ping &>/dev/null && break
    sleep 1
  done

  mysql --socket=/var/run/mysqld/mysqld.sock -uroot <<SQL
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
CREATE USER IF NOT EXISTS 'root'@'%' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
FLUSH PRIVILEGES;
SQL

  mysqladmin --socket=/var/run/mysqld/mysqld.sock -uroot -p"${MYSQL_ROOT_PASSWORD}" shutdown
  wait $pid || true
  echo ">> MySQL siap"
fi

# 3) Jalankan MySQL + PHP-FPM 8.2 + NGINX via supervisor
exec /usr/bin/supervisord -n -c /etc/supervisor/conf.d/supervisord.conf
