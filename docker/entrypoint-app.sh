#!/bin/bash
set -e
mkdir -p /run/php /etc/nginx/ssl

if [ ! -f /etc/nginx/ssl/mywebsite.local.crt ]; then
  echo ">> Generate sertifikat SSL mywebsite.local"
  openssl req -x509 -nodes -newkey rsa:2048 -days 825 \
    -keyout /etc/nginx/ssl/mywebsite.local.key \
    -out    /etc/nginx/ssl/mywebsite.local.crt \
    -subj   "/C=ID/O=Local Dev/CN=mywebsite.local" \
    -addext "subjectAltName=DNS:mywebsite.local"
fi

exec /usr/bin/supervisord -n -c /etc/supervisor/conf.d/supervisord.conf
