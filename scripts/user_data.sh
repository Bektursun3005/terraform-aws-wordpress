#!/bin/bash
set -euo pipefail

# Apache and PHP (WordPress needs PHP and the MySQL extension)
yum update -y
amazon-linux-extras enable php8.2
yum clean metadata
yum install -y httpd php php-mysqlnd php-gd php-xml php-mbstring

systemctl enable --now httpd

# Download WordPress into /var/www/html/blog
wget -q https://wordpress.org/latest.tar.gz -P /tmp
tar -xzf /tmp/latest.tar.gz -C /tmp
mkdir -p /var/www/html/blog
cp -r /tmp/wordpress/* /var/www/html/blog/

chown -R apache:apache /var/www/html/blog
chmod -R 755 /var/www/html/blog

systemctl restart httpd
