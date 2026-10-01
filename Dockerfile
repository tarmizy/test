FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Asia/Jakarta \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

# NGINX + MySQL 8.0 + PHP 8.2 (PPA ondrej) + supervisor
RUN apt-get update \
 && apt-get install -y --no-install-recommends software-properties-common ca-certificates gnupg tzdata \
 && add-apt-repository -y ppa:ondrej/php \
 && apt-get update \
 && apt-get install -y --no-install-recommends \
      nginx mysql-server supervisor openssl \
      php8.2-fpm php8.2-cli php8.2-mysql php8.2-mbstring php8.2-xml \
      php8.2-curl php8.2-zip php8.2-gd php8.2-intl php8.2-bcmath \
 && rm -rf /var/lib/apt/lists/* \
 && rm -rf /var/lib/mysql/* \
 && rm -f /etc/nginx/sites-enabled/default \
 && mkdir -p /run/php /var/run/mysqld /etc/nginx/ssl /var/www/mywebsite \
 && chown mysql:mysql /var/run/mysqld

COPY docker/nginx-mywebsite.conf  /etc/nginx/sites-enabled/mywebsite.conf
COPY docker/mysql-custom.cnf      /etc/mysql/mysql.conf.d/zz-custom.cnf
COPY docker/supervisord.conf      /etc/supervisor/conf.d/supervisord.conf
COPY docker/entrypoint.sh         /usr/local/bin/entrypoint.sh
COPY src/                         /var/www/mywebsite/

RUN chmod +x /usr/local/bin/entrypoint.sh \
 && chown -R www-data:www-data /var/www/mywebsite

VOLUME ["/var/lib/mysql"]
EXPOSE 80 443 3306

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
