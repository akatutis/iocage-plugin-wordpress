#!/bin/sh
cp /usr/local/etc/php.ini-production /usr/local/etc/php.ini
hash -r

# Setup database
service mysql-server enable
service mysql-server start

db_name=wordpress
db_user=wp$(openssl rand -base64 -hex 8)
db_password=$(openssl rand -base64 32)

echo "${db_user}" > /root/wordpress_db_username
echo "${db_password}" > /root/wordpress_db_password
echo "Wordpress Database" > /root/PLUGIN_INFO
echo "Name: ${db_name}" >> /root/PLUGIN_INFO
echo "Username: ${db_user}" >> /root/PLUGIN_INFO
echo "Password: ${db_password}\n" >> /root/PLUGIN_INFO

{
  echo "CREATE DATABASE ${db_name};"
  echo "CREATE USER '${db_user}'@'localhost' IDENTIFIED BY '${db_password}';"
  echo "GRANT ALL PRIVILEGES ON ${db_name}.* TO '${db_user}'@'localhost';"
  echo "FLUSH PRIVILEGES;"
} > wordpress_db_setup.sql
mysql -u root < wordpress_db_setup.sql

# Setup Apache web server
mv /usr/local/etc/apache24/httpd.conf /usr/local/etc/apache24/httpd.conf.bak
sed 's/#ServerName www.example.com/ServerName localhost/g' /usr/local/etc/apache24/httpd.conf.bak > /usr/local/etc/apache24/httpd.conf

# Enable PHP in Apache
{
  echo "<IfModule dir_module>"
  echo "  DirectoryIndex index.php index.html"
  echo "  <FilesMatch \"\.php$\">"
  echo "    SetHandler application/x-httpd-php"
  echo "  </FilesMatch>"
  echo "  <FilesMatch \"\.phps$\">"
  echo "    SetHandler application/x-httpd-php-source"
  echo "  </FilesMatch>"
  echo "</IfModule>"
}  > /usr/local/etc/apache24/modules.d/001_mod-php.conf

# Setup wordpress
wordpress_dir=/usr/local/www/apache24/data/wordpress
{
  echo "<VirtualHost *:80>"
  echo "    ServerAdmin webmaster@example.com"
  echo "    ServerName localhost"
  echo "    DocumentRoot $wordpress_dir"
  echo "    <Directory $wordpress_dir>"
  echo "       AllowOverride All"
  echo "       Require all granted"
  echo "    </Directory>"
  echo "</VirtualHost>"
} > /usr/local/etc/apache24/Includes/wordpress.conf

# Download wordpress
cd /tmp
curl -O https://wordpress.org/latest.tar.gz
tar xzf latest.tar.gz
mkdir -p $wordpress_dir
cp -pr /tmp/wordpress/ $wordpress_dir

# Update wordpress config
cp $wordpress_dir/wp-config-sample.php $wordpress_dir/wp-config.php

wp_seed="$(openssl rand -base64 64)";echo $wp_seed;wp_seed="$(echo $wp_seed|sed -r 's#(/|\(|\))#\\\1#g')";echo $wp_seed;sed -I.bak -r "s/(define\([ ]*'AUTH_KEY',).*/\1'$wp_seed');/" $wordpress_dir/wp-config.php
wp_seed="$(openssl rand -base64 64)";echo $wp_seed;wp_seed="$(echo $wp_seed|sed -r 's#(/|\(|\))#\\\1#g')";echo $wp_seed;sed -I.bak -r "s/(define\([ ]*'SECURE_AUTH_KEY',).*/\1'$wp_seed');/" $wordpress_dir/wp-config.php
wp_seed="$(openssl rand -base64 64)";echo $wp_seed;wp_seed="$(echo $wp_seed|sed -r 's#(/|\(|\))#\\\1#g')";echo $wp_seed;sed -I.bak -r "s/(define\([ ]*'LOGGED_IN_KEY',).*/\1'$wp_seed');/" $wordpress_dir/wp-config.php
wp_seed="$(openssl rand -base64 64)";echo $wp_seed;wp_seed="$(echo $wp_seed|sed -r 's#(/|\(|\))#\\\1#g')";echo $wp_seed;sed -I.bak -r "s/(define\([ ]*'NONCE_KEY',).*/\1'$wp_seed');/" $wordpress_dir/wp-config.php
wp_seed="$(openssl rand -base64 64)";echo $wp_seed;wp_seed="$(echo $wp_seed|sed -r 's#(/|\(|\))#\\\1#g')";echo $wp_seed;sed -I.bak -r "s/(define\([ ]*'AUTH_SALT',).*/\1'$wp_seed');/" $wordpress_dir/wp-config.php
wp_seed="$(openssl rand -base64 64)";echo $wp_seed;wp_seed="$(echo $wp_seed|sed -r 's#(/|\(|\))#\\\1#g')";echo $wp_seed;sed -I.bak -r "s/(define\([ ]*'SECURE_AUTH_SALT',).*/\1'$wp_seed');/" $wordpress_dir/wp-config.php
wp_seed="$(openssl rand -base64 64)";echo $wp_seed;wp_seed="$(echo $wp_seed|sed -r 's#(/|\(|\))#\\\1#g')";echo $wp_seed;sed -I.bak -r "s/(define\([ ]*'LOGGED_IN_SALT',).*/\1'$wp_seed');/" $wordpress_dir/wp-config.php
wp_seed="$(openssl rand -base64 64)";echo $wp_seed;wp_seed="$(echo $wp_seed|sed -r 's#(/|\(|\))#\\\1#g')";echo $wp_seed;sed -I.bak -r "s/(define\([ ]*'NONCE_SALT',).*/\1'$wp_seed');/" $wordpress_dir/wp-config.php
sed -I.bak -r "s/(define\([ ]*'DB_HOST',).*/\1'127.0.0.1');/" $wordpress_dir/wp-config.php
sed -I.bak -r "s/(define\([ ]*'DB_NAME',).*/\1'$db_name');/" $wordpress_dir/wp-config.php
sed -I.bak -r "s/(define\([ ]*'DB_USER',).*/\1'$db_user');/" $wordpress_dir/wp-config.php
db_password="$(echo $db_password|sed -r 's#(/|\(|\))#\\\1#g')";sed -I.bak -r "s/(define\([ ]*'DB_PASSWORD',).*/\1'$db_password');/" $wordpress_dir/wp-config.php

chown -R www:www $wordpress_dir
find $wordpress_dir -type d -exec chmod 750 {} \;
find $wordpress_dir -type f -exec chmod 640 {} \;

service apache24 enable
service apache24 restart
