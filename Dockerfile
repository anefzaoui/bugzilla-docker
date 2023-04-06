FROM ubuntu:22.04

# Update package list and upgrade packages
RUN apt-get update && apt-get upgrade -y

# Install required packages
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y debconf-utils perl build-essential libssl-dev libexpat1-dev libmysqlclient-dev libgd-dev libxml2-dev libxslt1-dev libnet-ldap-perl libdbi-perl libdbd-mysql-perl git nano libcgi-pm-perl libdigest-sha-perl libtimedate-perl libdatetime-perl libdatetime-timezone-perl libdbix-connector-perl libtemplate-perl libemail-address-perl libemail-sender-perl libemail-mime-perl liburi-perl liblist-moreutils-perl libmath-random-isaac-perl libjson-xs-perl libgd-perl libchart-perl libtemplate-plugin-gd-perl libgd-text-perl libgd-graph-perl libmime-tools-perl libwww-perl libxml-twig-perl libauthen-sasl-perl libnet-smtp-ssl-perl libauthen-radius-perl libsoap-lite-perl libxmlrpc-lite-perl libjson-rpc-perl libtest-taint-perl libhtml-parser-perl libhtml-scrubber-perl libencode-perl libencode-detect-perl libemail-reply-perl libhtml-formattext-withlinks-perl libtheschwartz-perl libdaemon-generic-perl libapache2-mod-perl2 libapache2-mod-perl2-dev libfile-mimeinfo-perl libio-stringy-perl libcache-memcached-perl libfile-copy-recursive-perl libfile-which-perl perlmagick lynx graphviz python3-sphinx rst2pdf

# Download Bugzilla
ENV BUGZILLA_VERSION 5.0.6
RUN wget https://ftp.mozilla.org/pub/mozilla.org/webtools/bugzilla-$BUGZILLA_VERSION.tar.gz

# Extract Bugzilla
RUN tar xf bugzilla-$BUGZILLA_VERSION.tar.gz

RUN mkdir -p /var/www/

# Move Bugzilla to the /var/www directory
RUN mv bugzilla-$BUGZILLA_VERSION /var/www/

RUN mv /var/www/bugzilla-$BUGZILLA_VERSION /var/www/bugzilla

# Install Perl modules
WORKDIR /var/www/bugzilla
RUN perl checksetup.pl --check-modules

RUN perl install-module.pl DateTime
RUN perl install-module.pl DateTime::TimeZone
RUN perl install-module.pl Template
RUN perl install-module.pl Email::Sender
RUN perl install-module.pl Email::MIME
RUN perl install-module.pl List::MoreUtils
RUN perl install-module.pl Math::Random::ISAAC
RUN perl install-module.pl JSON::XS
RUN perl install-module.pl ExtUtils::PkgConfig module

RUN perl install-module.pl --all

# Set up the web server
RUN apt-get install -y apache2 libapache2-mod-perl2

# Enable required Apache modules
RUN a2enmod cgi
RUN a2enmod expires
RUN a2enmod headers
RUN a2enmod rewrite

# Create an Apache virtual host configuration for Bugzilla
RUN echo '<VirtualHost *:80>' >> /etc/apache2/sites-available/bugzilla.conf \
    && echo '    ServerAdmin webmaster@localhost' >> /etc/apache2/sites-available/bugzilla.conf \
    && echo '    DocumentRoot /var/www/bugzilla' >> /etc/apache2/sites-available/bugzilla.conf \
    && echo '    ServerName bugzilla.bugzilla' >> /etc/apache2/sites-available/bugzilla.conf \
    && echo '' >> /etc/apache2/sites-available/bugzilla.conf \
    && echo '    ErrorLog \${APACHE_LOG_DIR}/error.log' >> /etc/apache2/sites-available/bugzilla.conf \
    && echo '    CustomLog \${APACHE_LOG_DIR}/access.log combined' >> /etc/apache2/sites-available/bugzilla.conf \
    && echo '' >> /etc/apache2/sites-available/bugzilla.conf \
    && echo '    <Directory /var/www/bugzilla>' >> /etc/apache2/sites-available/bugzilla.conf \
    && echo '        AddHandler cgi-script .cgi' >> /etc/apache2/sites-available/bugzilla.conf \
    && echo '        Options +ExecCGI' >> /etc/apache2/sites-available/bugzilla.conf \
    && echo '        DirectoryIndex index.cgi' >> /etc/apache2/sites-available/bugzilla.conf \
    && echo '        AllowOverride All' >> /etc/apache2/sites-available/bugzilla.conf \
    && echo '        Require all granted' >> /etc/apache2/sites-available/bugzilla.conf \
    && echo '    </Directory>' >> /etc/apache2/sites-available/bugzilla.conf \
    && echo '</VirtualHost>' >> /etc/apache2/sites-available/bugzilla.conf


# Enable the Bugzilla site and restart Apache
RUN a2ensite bugzilla
RUN service apache2 start


# Run the Bugzilla setup
RUN perl checksetup.pl

# Configure Bugzilla localconfig file
RUN sed -i "s/\$db_name = 'bugs';/\$db_name = 'bugzilla';/" localconfig
RUN sed -i "s/\$db_user = 'bugs';/\$db_user = 'bugzilla';/" localconfig
RUN sed -i "s/\$db_pass = '';/\$db_pass = 'bugzilla';/" localconfig
RUN sed -i "s/\$webservergroup = 'apache';/\$webservergroup = 'www-data';/" localconfig

# Set ownership and permissions
RUN chown -R www-data:www-data /var/www/bugzilla
RUN chmod -R 755 /var/www/bugzilla

# Run the final checksetup with input parameters
COPY checksetup_answers.txt /var/www/bugzilla/checksetup_answers.txt
RUN perl checksetup.pl /var/www/bugzilla/checksetup_answers.txt

CMD ["apache2ctl", "-DFOREGROUND"]