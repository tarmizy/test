# CI/CD GitHub Actions -> VPS

Alur: push ke `main` -> checkout repo -> build image -> push ke GHCR -> SSH ke VPS -> pull & `docker compose up -d` -> health check.

## 1. Persiapan VPS (sekali saja)
    curl -fsSL https://get.docker.com | sh
    sudo adduser deploy && sudo usermod -aG docker deploy
    sudo mkdir -p /opt/mywebsite && sudo chown deploy:deploy /opt/mywebsite

SSH key khusus deploy (di laptop):
    ssh-keygen -t ed25519 -f gh_deploy -N "" -C github-actions
    ssh-copy-id -i gh_deploy.pub deploy@IP_VPS
Isi file `gh_deploy` (private key) dimasukkan ke secret `VPS_SSH_KEY`.

## 2. GitHub Secrets
Repo -> Settings -> Environments -> buat `production` -> tambahkan secrets:

| Secret | Contoh |
|---|---|
| VPS_HOST | 203.0.113.10 |
| VPS_USER | deploy |
| VPS_SSH_KEY | isi private key gh_deploy |
| VPS_PORT | 22 (opsional) |
| MYSQL_ROOT_PASSWORD | (password kuat) |
| MYSQL_DATABASE | mywebsite |
| MYSQL_USER | appuser |
| MYSQL_PASSWORD | (password kuat) |

Catatan: password MySQL hanya dipakai saat volume masih kosong (deploy pertama).
Mengganti secret setelahnya TIDAK mengubah password di database.

## 3. Jalankan
Push ke `main`, atau Actions -> "CI/CD - Build & Deploy ke VPS" -> Run workflow.

## 4. Akses MySQL dari laptop (SSH tunnel)
    ssh -L 3307:127.0.0.1:3306 deploy@IP_VPS
Lalu SQL client ke `127.0.0.1:3307`. (DBeaver/HeidiSQL punya opsi SSH tunnel bawaan.)

## 5. Rollback
Di VPS: ubah `TAG=` di `/opt/mywebsite/.env` ke short SHA versi lama, lalu
    docker compose -f docker-compose.prod.yml up -d
Atau re-run workflow dari commit lama.
