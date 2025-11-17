#!/usr/bin/env bash
set -euo pipefail

echo "=========================================="
echo " 🚀 Nginx + PHP 8.2 + 扩展 + Composer 一键安装"
echo " 🚀 不依赖项目路径，不自动执行 composer"
echo "=========================================="

#------------------------------------------
# 0. 基础检查
#------------------------------------------
if [[ $EUID -ne 0 ]]; then
    echo "❌ 请使用 root 用户运行本脚本（sudo -i）"
    exit 1
fi

if ! command -v apt >/dev/null 2>&1; then
    echo "❌ 当前系统不支持本脚本（仅支持 Debian / Ubuntu ）"
    exit 1
fi

#------------------------------------------
# 1. 安装 Nginx
#------------------------------------------
echo "==> 安装 Nginx ..."
apt update -y
apt install -y nginx

systemctl enable nginx
systemctl restart nginx

echo "✅ Nginx 安装完成"
echo

#------------------------------------------
# 2. 安装 PHP 8.2 + 扩展
#------------------------------------------
echo "==> 安装 PHP 8.2 及扩展 ..."

apt install -y software-properties-common curl unzip

# 添加 PHP PPA（第一次运行时需要）
if ! grep -Rqs "ondrej/php" /etc/apt/sources.list /etc/apt/sources.list.d 2>/dev/null; then
    add-apt-repository -y ppa:ondrej/php
fi

apt update -y

apt install -y \
    php8.2 php8.2-cli php8.2-fpm php8.2-common \
    php8.2-mysql php8.2-gd php8.2-curl php8.2-mbstring \
    php8.2-xml php8.2-zip php8.2-gmp

# 确保 GMP 启用
for INI in /etc/php/8.2/fpm/php.ini /etc/php/8.2/cli/php.ini; do
    if [[ -f "$INI" ]] && ! grep -q "^extension=gmp" "$INI"; then
        echo "extension=gmp" >> "$INI"
    fi
done

systemctl restart php8.2-fpm

echo "✅ PHP 8.2 安装完成"
php -v || true
echo

#------------------------------------------
# 3. 安装 Composer
#------------------------------------------
if ! command -v composer >/dev/null 2>&1; then
    echo "==> 安装 Composer ..."
    curl -sS https://getcomposer.org/installer -o /tmp/composer-setup.php
    php /tmp/composer-setup.php --install-dir=/usr/local/bin --filename=composer
    rm -f /tmp/composer-setup.php
else
    echo "✅ Composer 已存在"
fi

composer -V
echo

#------------------------------------------
# 4. 完成提示
#------------------------------------------
echo "=========================================="
echo "🎉 环境安装全部完成！"
echo
echo "🚀 已安装服务："
echo "   - Nginx"
echo "   - PHP 8.2 + 扩展"
echo "   - Composer"
echo
echo "📌 你现在可以自由放置项目，例如："
echo "   /root/wow/"
echo "   /www/wwwroot/wow/"
echo
echo "📌 如需安装项目依赖，请手动执行："
echo "   cd /root/wow/application"
echo "   composer install"
echo
echo "🧩 服务状态："
echo "   systemctl status nginx"
echo "   systemctl status php8.2-fpm"
echo "=========================================="
