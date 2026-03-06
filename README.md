# Telegram OCR to DOCX Bot

Bot Telegram nhan file `pdf/jpg/png/...`, uu tien trich xuat text native tu PDF de convert thang sang `docx`; chi OCR khi la trang scan anh.

## 1) Yeu cau he thong

- Python 3.10+
- Tesseract OCR (bat buoc)
  - Windows: cai tu UB Mannheim hoac goc Tesseract
  - Linux: `sudo apt install tesseract-ocr tesseract-ocr-vie`
- Telegram Bot Token tu `@BotFather`

## 2) Cai dat

```bash
pip install -r requirements.txt
```

Tao file `.env` tu `.env.example`:

```env
BOT_TOKEN=your_telegram_bot_token_here
OCR_LANG=vie+eng
# OCR_LANG=auto
# RUN_MODE=polling
# WEBHOOK_URL=https://your-domain.example.com
# WEBHOOK_PATH=/telegram/webhook
# WEBHOOK_PORT=8080
# WEBHOOK_LISTEN=0.0.0.0
# WEBHOOK_SECRET_TOKEN=change_this_random_secret
# NGINX_LIMIT_ZONE_SIZE=10m
# NGINX_CONN_ZONE_SIZE=10m
# NGINX_CLIENT_MAX_BODY_SIZE=20m
# NGINX_RATE_LIMIT_BURST=20
# NGINX_CONN_LIMIT_PER_IP=30
# NGINX_PROXY_CONNECT_TIMEOUT=5s
# NGINX_PROXY_SEND_TIMEOUT=60s
# NGINX_PROXY_READ_TIMEOUT=60s
# TESSERACT_CMD=C:/Program Files/Tesseract-OCR/tesseract.exe
# MAX_CONCURRENT_JOBS=2
# OCR_TIMEOUT_SECONDS=120
# AUTO_OCR_LANG_CANDIDATES=vie+eng,eng
# AUTO_OCR_DETECT_SAMPLE_PAGES=2
# TELEGRAM_WRITE_TIMEOUT_SECONDS=180
# MAX_OUTPUT_DOCX_MB=25
# ENABLE_DOCX_MEDIA_COMPRESSION=1
# DOCX_MEDIA_COMPRESSION_MIN_MB=8
# DOCX_IMAGE_MAX_DIMENSION=1800
# DOCX_IMAGE_JPEG_QUALITY=70
# TEXT_NATIVE_MIN_CHARS=40
# PDF_LAYOUT_MIN_NATIVE_RATIO=0.8
# CACHE_DIR=cache
# TELEGRAM_PROVIDER_TOKEN=your_payment_provider_token
# PREMIUM_DAYS=30
# PREMIUM_PRICE_USD_CENTS=500
# BILLING_DB_PATH=data/billing.sqlite3
# ADMIN_USER_IDS=123456789,987654321
# FREE_REQUESTS_PER_MINUTE=3
# PREMIUM_REQUESTS_PER_MINUTE=20
# RATE_LIMIT_WINDOW_SECONDS=60
# CACHE_TTL_DAYS=7
# CACHE_MAX_SIZE_MB=1024
# JOB_HISTORY_PER_USER=10
# BACKUP_DB_PATH=data/billing.sqlite3
# BACKUP_DIR=backups
# BACKUP_KEEP_COUNT=14
```

## 3) Chay bot

```bash
python bot.py
```

Mac dinh bot chay polling (`RUN_MODE=polling`). Neu muon webhook, dat `RUN_MODE=webhook` va cau hinh `WEBHOOK_URL`.

## 3.1) Deploy bang Docker + Nginx (Webhook)

```bash
docker compose up -d --build
```

Truoc khi chay, can dat trong `.env`:

- `RUN_MODE=webhook`
- `WEBHOOK_URL=https://your-public-domain`
- (khuyen nghi) `WEBHOOK_SECRET_TOKEN=<random-secret>`

File lien quan deploy:

- `Dockerfile`
- `docker-compose.yml`
- `deploy/nginx/default.conf.template`

Hardening da bat trong deploy nay:

- Healthcheck cho `bot` va `nginx` trong `docker-compose.yml`
- Nginx rate limit cho webhook (`5 req/s` moi IP, co burst)
- Nginx config duoc template hoa theo env vars (`NGINX_*`)

## 3.2) Deploy Linux systemd (Polling/Webhook)

- Mau service: `deploy/systemd/scan2docx.service`
- Chinh `WorkingDirectory`, `EnvironmentFile`, `ExecStart`, `User` theo server cua ban.

Enable service:

```bash
sudo cp deploy/systemd/scan2docx.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now scan2docx.service
```

Installer nhanh (service + backup timer + fail2ban neu co):

```bash
sudo bash deploy/scripts/install_hardening.sh /opt/scan2docx
```

## 3.3) Run tren Windows

- Script chay nhanh: `deploy/windows/run-bot.ps1`

## 3.4) Backup/Rotate billing DB

Linux/macOS:

```bash
bash deploy/scripts/backup_billing_db.sh
```

Windows PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File .\deploy\scripts\backup_billing_db.ps1
```

Script Python goc (cross-platform):

```bash
python deploy/scripts/backup_billing_db.py --db-path data/billing.sqlite3 --backup-dir backups --keep-count 14
```

Goi y lich chay:

- Linux cron: backup moi ngay 1 lan
- Windows Task Scheduler: chay script `.ps1` theo ngay

Systemd timer (Linux) san co:

- `deploy/systemd/scan2docx-backup.service`
- `deploy/systemd/scan2docx-backup.timer`

Enable timer:

```bash
sudo cp deploy/systemd/scan2docx-backup.service /etc/systemd/system/
sudo cp deploy/systemd/scan2docx-backup.timer /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now scan2docx-backup.timer
sudo systemctl list-timers | grep scan2docx-backup
```

Cron mau san co trong `deploy/cron/backup.cron`.

## 3.5) Fail2ban (optional, Linux + host nginx)

Neu ban chay nginx tren host (khong phai trong container), co the bat fail2ban:

```bash
sudo cp deploy/fail2ban/filter.d/scan2docx-nginx.conf /etc/fail2ban/filter.d/
sudo cp deploy/fail2ban/jail.d/scan2docx-nginx.local /etc/fail2ban/jail.d/
sudo systemctl restart fail2ban
sudo fail2ban-client status scan2docx-nginx
```

Luu y: can dam bao `logpath` trong jail trung voi access log thuc te cua nginx.

## 3.6) Render nginx config cho host mode

Neu ban chay nginx tren host (khong qua Docker template), co the render file static:

```bash
python deploy/nginx/render_local_conf.py
```

File output: `deploy/nginx/default.conf` (doc cac bien `NGINX_*` tu environment hien tai).

## 3.7) Arch Linux: install nhanh + update nhanh + systemd service

Bo file moi:

- `deploy/arch/install_arch_service.sh`
- `deploy/arch/quick_update.sh`
- `deploy/systemd/scan2docx-arch.service`

Install nhanh tren server Arch (clone + tao venv + cai deps + enable service):

```bash
sudo bash deploy/arch/install_arch_service.sh https://github.com/<user>/<repo>.git
```

Hoac neu source da nam san trong `/opt/scan2docx`:

```bash
sudo INSTALL_DIR=/opt/scan2docx bash deploy/arch/install_arch_service.sh
```

Update nhanh sau moi lan push code:

```bash
sudo INSTALL_DIR=/opt/scan2docx SERVICE_NAME=scan2docx BRANCH=master bash /opt/scan2docx/deploy/arch/quick_update.sh
```

Script update se:

- Backup nhanh SQLite billing DB truoc khi update
- `git fetch/pull --ff-only`
- Update `pip` + install lai `requirements.txt`
- Compile check `bot.py`
- Restart service va in trang thai

Neu gap loi build `Pillow` (vd: `error: command 'gcc' failed`), cai them build deps roi chay lai installer/update:

```bash
sudo pacman -Sy --needed base-devel gcc pkgconf libjpeg-turbo zlib libtiff lcms2 libwebp openjpeg2 freetype2
```

Neu server dang dung Python qua moi (vd 3.14) va van phai build source, hay xoa venv cu roi chay lai installer de script tu uu tien `python3.13` (neu co):

```bash
sudo rm -rf /opt/scan2docx/.venv
sudo BRANCH=master bash /opt/scan2docx/deploy/arch/install_arch_service.sh
```

## 4) Su dung

- Mo chat voi bot va go `/start`
- Gui anh scan hoac file PDF scan
- Bot tra lai file `.docx`
- Dung `/plan` de xem goi hien tai
- Dung `/buy` de mua goi Premium subscription ($5/thang)
- Dung `/lang <code>` de doi ngon ngu OCR (VD: `auto`, `eng`, `vie+eng`)
- Dung `/status` de xem trang thai job gan nhat
- Admin: `/grant <user_id> [days]`, `/revoke <user_id>`, `/stats`

## Ghi chu

- OCR tieng Viet can du lieu ngon ngu `vie.traineddata` trong Tesseract.
- Free plan: gioi han 5 trang/PDF va 10MB/file.
- Premium plan: subscription $5/thang, bo gioi han trang va dung luong file.
- PDF vuot gioi han cua goi se bi tu choi ngay.
- Bot se convert truc tiep voi PDF text-native de giam tai server.
- Bot uu tien giu layout PDF bang `pdf2docx` khi tai lieu co ti le text-native cao.
- Neu DOCX giu layout qua lon, bot tu fallback sang ban nhe hon de tang kha nang gui file thanh cong.
- Neu trang PDF khong co text (dang scan), bot moi OCR cho trang do.
- File tam dau vao/ra duoc xoa ngay sau khi xu ly xong.
- Co gioi han so job dong thoi va timeout OCR de tranh qua tai/treo tien trinh.
- Co timeout upload Telegram (`TELEGRAM_WRITE_TIMEOUT_SECONDS`) de giam loi gui file lon.
- Bot co the nen anh trong DOCX truoc khi gui (`ENABLE_DOCX_MEDIA_COMPRESSION`) de giam loi upload.
- Co nguong kich thuoc output (`MAX_OUTPUT_DOCX_MB`) de tranh file layout qua nang gay loi upload.
- Rate-limit theo goi: Free/Premium co nguong request/phut khac nhau.
- Co heuristic text-native (`TEXT_NATIVE_MIN_CHARS`) de giam OCR khong can thiet.
- Nguong uu tien layout PDF co the dieu chinh bang `PDF_LAYOUT_MIN_NATIVE_RATIO`.
- Bot ghi metrics thoi gian xu ly trong log de toi uu van hanh.
- Bot ghi su kien xu ly dang JSON (kem `request_id`) de de monitor.
- Co cache theo hash file (`CACHE_DIR`) de file gui lai trung nhau se tra ket qua ngay.
- Cache duoc don dep tu dong theo tuoi file (`CACHE_TTL_DAYS`) va dung luong toi da (`CACHE_MAX_SIZE_MB`).
- Caption file tra ve hien thong ke tong trang/native/OCR.
- Bot luu lich su thanh toan vao bang `payments` trong SQLite de doi soat.
- Bot luu job history theo user (`JOB_HISTORY_PER_USER`) de phuc vu `/status`.

## Premium billing

- Bot dung Telegram Payments (invoice) qua lenh `/buy`.
- Sau thanh toan thanh cong, user duoc Premium 1 thang (`PREMIUM_DAYS=30`).
- Thong tin Premium duoc luu trong SQLite (`BILLING_DB_PATH`).
- Gia mac dinh la `PREMIUM_PRICE_USD_CENTS=500` (5 USD/thang).
- Neu chua cau hinh `TELEGRAM_PROVIDER_TOKEN`, lenh `/buy` se thong bao chua san sang.

## Admin operations

- Dat danh sach admin qua `ADMIN_USER_IDS` (phan cach boi dau phay).
- Admin moi duoc phep dung lenh `/grant`, `/revoke`, `/stats`.
- User trong `ADMIN_USER_IDS` duoc bo qua toan bo gioi han page/file-size/rate-limit khi xu ly file.
