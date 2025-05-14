#!/bin/bash

# Обновляем систему
apt-get update && apt-get upgrade -y

# Устанавливаем нужные пакеты
apt-get install -y \
    nginx \
    moodle \
    mediawiki \
    mariadb-server \
    php-fpm \
    php-mysql \
    cups \
    chrony \
    rsyslog \
    openssl \
    curl \
    ansible

# Запускаем сервисы
systemctl enable --now nginx mariadb php-fpm cups chronyd rsyslog

# Генерация самоподписанного SSL-сертификата
mkdir -p /etc/nginx/ssl
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/nginx/ssl/server.key \
  -out /etc/nginx/ssl/server.crt \
  -subj "/C=RU/ST=Moscow/L=Moscow/O=IRPO/CN=hq-srv.au-team.irpo"

# Настройка HTTPS nginx
cat <<EOF > /etc/nginx/sites-available/hq-srv
server {
    listen 443 ssl;
    server_name hq-srv.au-team.irpo;

    ssl_certificate /etc/nginx/ssl/server.crt;
    ssl_certificate_key /etc/nginx/ssl/server.key;

    location /moodle {
        root /usr/share/;
        index index.php;
    }

    location /mediawiki {
        root /var/lib/;
        index index.php;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php-fpm.sock;
    }
}
EOF

ln -sf /etc/nginx/sites-available/hq-srv /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
systemctl reload nginx

# Настройка CUPS — виртуальный принтер в файл
lpadmin -p PDFPrinter -E -v file:/tmp/output.pdf -m drv:///sample.drv/generic.ppd
lpoptions -d PDFPrinter

# Настройка monitoring страницы
mkdir -p /opt/mon
echo "<html><body><h1>Monitoring OK</h1></body></html>" > /opt/mon/index.html

cat <<EOF > /etc/nginx/sites-available/mon
server {
    listen 80;
    server_name mon.au-team.irpo;
    root /opt/mon;
    index index.html;
}
EOF

ln -sf /etc/nginx/sites-available/mon /etc/nginx/sites-enabled/
systemctl reload nginx

# Настройка логирования в /opt
mkdir -p /opt/logs
echo "*.* /opt/logs/hq-srv.log" >> /etc/rsyslog.conf
systemctl restart rsyslog
