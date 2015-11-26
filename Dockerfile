FROM phusion/baseimage:0.9.17

# Ensure UTF-8
RUN locale-gen en_US.UTF-8
ENV LANG       en_US.UTF-8
ENV LC_ALL     en_US.UTF-8

# Set Local Env
ENV HOME /root

# Set the intial ssh key
RUN /etc/my_init.d/00_regen_ssh_host_keys.sh

# Initials the base build
CMD ["/sbin/my_init"]

# Install everything we need

# Update apt
RUN apt-get update
# Install basic libraries
RUN apt-get install -y vim curl wget build-essential python-software-properties imagemagick unoconv\
				nodejs npm elasticsearch
				
# Add some repositories for php and nginx
RUN add-apt-repository -y ppa:ondrej/php5
RUN add-apt-repository -y ppa:nginx/stable
RUN apt-get update
RUN apt-get install -y --force-yes php5-cli php5-fpm php5-mysql php5-pgsql php5-sqlite php5-curl\
		       php5-gd php5-mcrypt php5-intl php5-imap php5-tidy php5-imagick php5-xml


# Enable Datestamp for php
RUN sed -i "s/;date.timezone =.*/date.timezone = UTC/" /etc/php5/fpm/php.ini
RUN sed -i "s/;date.timezone =.*/date.timezone = UTC/" /etc/php5/cli/php.ini

RUN DEBIAN_FRONTEND="noninteractive" apt-get install -y nginx

# Disable daemon so that nginx and php-fpm don't crash the container
RUN echo "daemon off;" >> /etc/nginx/nginx.conf
RUN sed -i -e "s/;daemonize\s*=\s*yes/daemonize = no/g" /etc/php5/fpm/php-fpm.conf
RUN sed -i "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/" /etc/php5/fpm/php.ini
 
RUN mkdir -p        /var/www
ADD build/default   /etc/nginx/sites-available/default


# add an executable for nginx
RUN mkdir           /etc/service/nginx
ADD build/nginx.sh  /etc/service/nginx/run
RUN chmod +x        /etc/service/nginx/run

# Add an executable to start php fpm
RUN mkdir           /etc/service/phpfpm
ADD build/phpfpm.sh /etc/service/phpfpm/run
RUN chmod +x        /etc/service/phpfpm/run

# Open port 80
EXPOSE 80
# End Nginx-PHP


# Install Mongodb
RUN echo "deb http://repo.mongodb.org/apt/ubuntu trusty/mongodb-org/3.0 multiverse" > sudo tee /etc/apt/sources.list.d/mongodb-org-3.0.list
RUN apt-get -y install mongodb-org


# Install Mysql
# I don't know what this does
RUN dpkg-divert --local --rename --add /sbin/initctl
RUN ln -s /bin/true /sbin/initctl

# Install mysql
RUN apt-get -y install mysql-client mysql-server

# Set up bind
RUN sed -i -e"s/^bind-address\s*=\s*127.0.0.1/bind-address = 0.0.0.0/" /etc/mysql/my.cnf

RUN mkdir           /etc/service/mysql
ADD build/mysql.sh  /etc/service/mysql/run
RUN chmod +x        /etc/service/mysql/run

EXPOSE 3306

CMD ["/bin/bash", "/opt/startup.sh"]


# Clean everything
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
