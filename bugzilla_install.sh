#!/bin/bash

# Update package list and upgrade packages
sudo apt-get update && sudo apt-get upgrade -y

# Install required packages
sudo apt-get install -y debconf-utils wget perl build-essential libssl-dev libexpat1-dev libmysqlclient-dev libgd-dev libxml2-dev libxslt1-dev libnet-ldap-perl libdbi-perl libdbd-mysql-perl git nano libcgi-pm-perl libdigest-sha-perl libtimedate-perl libdatetime-perl libdatetime-timezone-perl libdbix-connector-perl libtemplate-perl libemail-address-perl libemail-sender-perl libemail-mime-perl liburi-perl liblist-moreutils-perl libmath-random-isaac-perl libjson-xs-perl libgd-perl libchart-perl libtemplate-plugin-gd-perl libgd-text-perl libgd-graph-perl libmime-tools-perl libwww-perl libxml-twig-perl libauthen-sasl-perl libnet-smtp-ssl-perl libauthen-radius-perl libsoap-lite-perl libxmlrpc-lite-perl libjson-rpc-perl libtest-taint-perl libhtml-parser-perl libhtml-scrubber-perl libencode-perl libencode-detect-perl libemail-reply-perl libhtml-formattext-withlinks-perl libtheschwartz-perl libdaemon-generic-perl libapache2-mod-perl2 libapache2-mod-perl2-dev libfile-mimeinfo-perl libio-stringy-perl libcache-memcached-perl libfile-copy-recursive-perl libfile-which-perl perlmagick lynx graphviz python3-sphinx rst2pdf

# Download Bugzilla
BUGZILLA_VERSION="5.0.6"
wget https://ftp.mozilla.org/pub/mozilla.org/webtools/bugzilla-$BUGZILLA_VERSION.tar.gz

# Extract Bugzilla
tar xf bugzilla-$BUGZILLA_VERSION.tar.gz

sudo mkdir -p /var/www/

# Move Bugzilla to the /var/www directory
sudo mv bugzilla-$BUGZILLA_VERSION /var/www/

sudo mv /var/www/bugzilla-$BUGZILLA_VERSION /var/www/bugzilla

# Install Perl modules
cd /var/www/bugzilla
sudo perl checksetup.pl --check-modules

sudo perl install-module.pl DateTime
sudo perl install-module.pl DateTime::TimeZone
sudo perl install-module.pl Template
sudo perl install-module.pl Email::Sender
sudo perl install-module.pl Email::MIME
sudo perl install-module.pl List::MoreUtils
sudo perl install-module.pl Math::Random::ISAAC
sudo perl install-module.pl JSON::XS
sudo perl install-module.pl ExtUtils::PkgConfig module

sudo perl install-module.pl --all

# Download MySQL
wget https://dev.mysql.com/get/mysql-apt-config_0.8.12-1_all.deb

echo "mysql-apt-config mysql-apt-config/repo-distro select ubuntu" | sudo debconf-set-selections
echo "mysql-apt-config mysql-apt-config/repo-url string http://repo.mysql.com/apt" | sudo debconf-set-selections
echo "mysql-apt-config mysql-apt-config/repo-codename select bionic" | sudo debconf-set-selections
echo "mysql-apt-config mysql-apt-config/select-server select mysql-5.7" | sudo debconf-set-selections
echo "mysql-apt-config mysql-apt-config/select-product select Ok" | sudo debconf-set-selections
echo "mysql-apt-config mysql-apt-config/select-tools select Ok" | sudo debconf-set-selections
echo "mysql-apt-config mysql-apt-config/unsupported-platform select abort" | sudo debconf-set-selections

# Install MySQL Package
sudo dpkg -i mysql-apt-config_0.8.12-1_all.deb

# Select options for MySQL installation
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 467B942D3A79BD29

# Update the packages list
sudo apt-get update

sudo debconf-set-selections <<< "mysql-community-server mysql-community-server/root-pass password root"
sudo debconf-set-selections <<< "mysql-community-server mysql-community-server/re-root-pass password root"

# Install MySQL 5.7
sudo apt install -f mysql-client=5.7* mysql-community-server=5.7* mysql-server=5.7* -y

# Change the MySQL root user authentication plugin
MYSQL_ROOT_PASSWORD="root"

# Configure MySQL for Bugzilla
mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "CREATE DATABASE bugzilla;"
mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "CREATE USER 'bugzilla'@'localhost' IDENTIFIED BY 'bugzilla';"
mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "GRANT ALL PRIVILEGES ON bugzilla.* TO 'bugzilla'@'localhost';"
mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "FLUSH PRIVILEGES;"

# Set up the web server
sudo apt-get install -y apache2 libapache2-mod-perl2

# Enable required Apache modules
sudo a2enmod cgi
sudo a2enmod expires
sudo a2enmod headers
sudo a2enmod rewrite

# Create an Apache virtual host configuration for Bugzilla
sudo bash -c 'cat > /etc/apache2/sites-available/bugzilla.conf << EOL
<VirtualHost *:80>
    ServerAdmin webmaster@localhost
    DocumentRoot /var/www/bugzilla
    ServerName bugzilla.bugzilla

    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined

    <Directory /var/www/bugzilla>
        AddHandler cgi-script .cgi
        Options +ExecCGI
        DirectoryIndex index.cgi
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
EOL'

# Enable the Bugzilla site and restart Apache
sudo a2ensite bugzilla
sudo systemctl restart apache2

# Run the Bugzilla setup
sudo perl checksetup.pl

# Set ownership and permissions
sudo chown -R www-data:www-data /var/www/bugzilla
sudo chmod -R 755 /var/www/bugzilla

echo "127.0.0.1 bugzilla.bugzilla bugzilla" | sudo tee -a /etc/hosts

# Create Bugzilla's local configuration file, again
sudo sed -i "s/\$db_name = 'bugs';/\$db_name = 'bugzilla';/" localconfig
sudo sed -i "s/\$db_user = 'bugs';/\$db_user = 'bugzilla';/" localconfig
sudo sed -i "s/\$db_pass = '';/\$db_pass = 'bugzilla';/" localconfig
sudo sed -i "s/\$webservergroup = 'apache';/\$webservergroup = 'www-data';/" localconfig

sudo perl checksetup.pl

# Done
echo "Bugzilla installation completed successfully. Visit http://bugzilla.bugzilla to access your Bugzilla instance."