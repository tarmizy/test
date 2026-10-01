# mywebsite — NGINX + MySQL 8 + PHP 8.2 (1 container)

## 1. Tambah host
Linux/macOS: `/etc/hosts` | Windows (Notepad as Admin): `C:\Windows\System32\drivers\etc\hosts`

    127.0.0.1   mywebsite.local

## 2. Build & jalankan
    docker compose up -d --build
    docker compose logs -f

## 3. Akses web
https://mywebsite.local  -> menampilkan phpinfo()
Sertifikat self-signed ada di `./certs/mywebsite.local.crt`. Import ke
"Trusted Root Certification Authorities" (Windows) / Keychain (macOS) agar tidak ada warning.

## 4. Akses database dari laptop (DBeaver / HeidiSQL / Workbench / CLI)
    Host: 127.0.0.1   Port: 3306
    User: root / rootpass   atau   appuser / apppass (DB: mywebsite)

    mysql -h 127.0.0.1 -P 3306 -u appuser -papppass mywebsite
DBeaver: set driver property `allowPublicKeyRetrieval=true`.

## 5. Uji persistensi data
    mysql -h 127.0.0.1 -uroot -prootpass -e "CREATE TABLE mywebsite.t(id INT); INSERT INTO mywebsite.t VALUES (1);"
    docker compose restart
    mysql -h 127.0.0.1 -uroot -prootpass -e "SELECT * FROM mywebsite.t;"   # data masih ada

Data hanya hilang jika volume dihapus (`docker compose down -v`).

## Tanpa docker compose
    docker build -t mywebsite .
    docker volume create mysql_data
    docker run -d --name mywebsite --restart unless-stopped \
      -p 80:80 -p 443:443 -p 3306:3306 \
      -e MYSQL_ROOT_PASSWORD=rootpass -e MYSQL_DATABASE=mywebsite \
      -e MYSQL_USER=appuser -e MYSQL_PASSWORD=apppass \
      -v mysql_data:/var/lib/mysql -v "$PWD/src:/var/www/mywebsite" -v "$PWD/certs:/etc/nginx/ssl" \
      mywebsite
