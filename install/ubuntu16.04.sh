#!/bin/bash

###########################
###########################
# YOURS web
# See : http://wiki.openstreetmap.org/wiki/YOURS#Installing_YOURS_website
###########################
###########################
apt update
apt-get -y install php7.0-curl
apt-get -y install php7.0
apt-get -y install apache2
apt-get -y install php libapache2-mod-php

cp -a src/www /var/www/yours

## Configure apache2
cp src/debianfs/etc/apache2/sites-available/001-yours.conf /etc/apache2/sites-available/
ln -s /etc/apache2/sites-available/001-yours.conf /etc/apache2/sites-enabled/001-yours.conf
rm /etc/apache2/sites-enabled/000-default.conf 
apache2ctl restart

###########################
###########################
# Gosmore
# See : http://wiki.openstreetmap.org/wiki/YOURS#Installing_YOURS_website
# See : http://wiki.openstreetmap.org/wiki/Gosmore
###########################
###########################
apt-get -y install libxml2-dev libgtk2.0-dev g++ make subversion libcurl4-gnutls-dev libgps-dev
#svn co http://svn.openstreetmap.org/applications/rendering/gosmore/
svn co https://svn.openstreetmap.org/applications/rendering/gosmore/
cd gosmore
#Modify Makefile: uncomment #CFLAGS += -DHEADLESS
#Modify Makefile: add ONLY_ROUTING option
sed -i '/^#.*CFLAGS += -DHEADLESS/s/^#//' Makefile.in
sed -i 's/^CFLAGS += -DHEADLESS/CFLAGS += -DHEADLESS -DONLY_ROUTING/g' Makefile.in

./configure
# ? Modify jni/gosmore.cpp according to http://wiki.openstreetmap.org/wiki/Talk:Gosmore
make
sudo make install
cd ../

cp -a gosmore /var/www
chown -R www-data:www-data /var/www/gosmore

###########################
###########################
# RoutingInstructions
# See : http://wiki.openstreetmap.org/wiki/YOURS#Installing_YOURS_website
# See : http://wiki.openstreetmap.org/wiki/Gosmore
###########################
###########################
apt-get -y install cmake
apt-get -y install qttool5-dev
apt-get -y install qttool5-dev-tools
apt-get -y install qtscript5-dev
apt-get install git build-essential cmake 
libqt5svg5-dev libqt5webkit5-dev 
qt5-default qtscript5-dev qttools5-dev qttools5-dev-tools qtmultimedia5-dev 
libssl-dev libsdl2-dev libasound2 libxmu-dev libxi-dev freeglut3-dev libasound2-dev libjack-jackd2-dev libxrandr-dev 
libqt5xmlpatterns5-dev libqt5xmlpatterns5 libqt5xmlpatterns5-private-dev

cd 
mkdir routing-instructions
cd routing-instructions
git clone git://anongit.kde.org/marble src
mkdir build
cd build
cmake -DWITH_KF5=FALSE -DBUILD_MARBLE_TOOLS=ON ../src
make routing-instructions
cp tools/routing-instructions/routing-instructions /usr/local/bin/
cd


###########################
###########################
# Fixes to make it work
# See : https://forum.openstreetmap.org/viewtopic.php?id=735&p=9
###########################
###########################
#Fix hardcode paths in php files
sed -i 's:^$www_dir.*:$www_dir = '/var/www/yours/';:g' /var/www/yours/api/dev/settings.php
sed -i 's:^$yours_dir.*:$yours_dir = '/var/www/gosmore/';:g' /var/www/yours/api/dev/gosmore.php
sed -i 's:^$www_dir.*:$www_dir = '/var/www/yours/';:g' /var/www/yours/api/1.0/settings.php
sed -i 's:^$yours_dir.*:$yours_dir = '/var/www/gosmore/';:g' /var/www/yours/api/1.0/gosmore.php

#Web app is calling api/<version>/route.php which does not exist
ln -s /var/www/yours/api/dev/gosmore.php /var/www/yours/api/dev/route.php
ln -s /var/www/yours/api/1.0/gosmore.php /var/www/yours/api/1.0/route.php

cd /var/www/gosmore
ln -s default.pak gosmore.pak
ln -s default.pak eurasia.pak
ln -s default.pak america.pak

# Get a proper elemstyles.xml
cd /root/gosmore
wget http://www.yournavigation.org/elemstyles.xml.routing
ln -s elemstyles.xml.routing elemstyles.xml
ln -s elemstyles.xml.routing genericstyles.xml
ln -s elemstyles.xml.routing cyclestyles.xml

# Fix replace deprecated split with explode  
sed -i 's:split:explode:g' /var/www/yours/api/1.0/gosmore.php
sed -i 's:split:explode:g' /var/www/yours/api/dev/gosmore.php


###########################
###########################
# Get map data
###########################
###########################
###
#wget -O - http://m.m.i24.cc/osmconvert.c | cc -x c - -lz -O3 -o osmconvert
#wget http://mirror.openstreetmap.nl/planet/benelux/planet-benelux-160503.osm.pbf
#./osmconvert planet-benelux-160503.osm.pbf > planet-benelux-160503.osm
#cat planet-benelux-160503.osm | ./gosmore/gosmore rebuild
###

#apt-get -y install osmosis

# Remove old pak files from gosmore
cd /root
mkdir paks
mv gosmore/*.pak pak/

# Download a osm map
cd /root
mkdir osm
cd /root/osm
#wget http://ftp.snt.utwente.nl/pub/misc/openstreetmap/planet-latest.osm.bz2
#wget https://ftp5.gwdg.de/pub/misc/openstreetmap/planet.openstreetmap.org/planet/planet-latest.osm.bz2
#wget https://download.geofabrik.de/europe-latest.osm.bz2
wget http://download.geofabrik.de/europe/netherlands-latest.osm.bz2
#wget http://download.geofabrik.de/europe/netherlands-latest.osm.pbf
wget http://download.geofabrik.de/europe/netherlands.poly

cd /root/gosmore
OSM_BZ2=/root/osm/netherlands-latest.osm.bz2
bzcat $OSM_BZ2 | ./gosmore rebuild 

cp gosmore.pak /var/www/gosmore/default.pak
