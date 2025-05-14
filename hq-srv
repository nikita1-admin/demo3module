#!/bin/bash

# Обновляем систему и устанавливаем нужные пакеты
apt-get update && apt-get install -y \
    nginx \
    moodle \
    mediawiki \
    mariadb-server \
    cups \
    chrony \
    rsyslog \
    openssl \
    php-fpm \
    php-mysql \
    ansible

# Включаем и запускаем нужные сервисы
systemctl enable --now nginx mariadb cups php-fpm chronyd rsyslog

# Настройка Moodle и MediaWiki
# Moodle будет доступен по адресу: http://<сервер>/moodle
# MediaWiki по адресу: http://<сервер>/mediawiki

# Настройка самоподписанного SSL-сертификата
mkdir -p /etc/nginx/ssl
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/nginx/ssl/server.key \
  -out /etc/nginx/ssl/server.crt \
  -subj "/C=RU/ST=Moscow/L=Moscow/O=IRPO/CN=hq-srv.au-team.irpo"

# Настройка HTTPS для Moodle и MediaWiki
cat <<EOF > /etc/nginx/sites-available/secure
server {
    listen 443 ssl;
    server_name hq-srv.au-team.irpo;

    ssl_certificate /etc/nginx/ssl/server.crt;
    ssl_certificate_key /etc/nginx/ssl/server.key;

    root /var/www;
    index index.php index.html;

    location /moodle {
        alias /usr/share/moodle;
        index index.php;
    }

    location /mediawiki {
        alias /var/lib/mediawiki;
        index index.php;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php7.4-fpm.sock;
    }
}
EOF

ln -s /etc/nginx/sites-available/secure /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
systemctl reload nginx

# Настройка CUPS (виртуальный принтер для PDF)
lpadmin -p PDFPrinter -E -v file:/tmp/output.pdf -m drv:///sample.drv/generic.ppd
lpoptions -d PDFPrinter

# Настройка мониторинга через nginx
mkdir -p /opt/mon
echo "<html><body><h1>Monitoring</h1></body></html>" > /opt/mon/index.html

cat <<EOF > /etc/nginx/sites-available/mon
server {
    listen 80;
    server_name mon.au-team.irpo;
    root /opt/mon;
    index index.html;
}
EOF

ln -s /etc/nginx/sites-available/mon /etc/nginx/sites-enabled/
systemctl reload nginx

# Настройка логирования в /opt/logs
mkdir -p /opt/logs
echo "*.* /opt/logs/hq-srv.log" >> /etc/rsyslog.conf
systemctl restart rsyslog
