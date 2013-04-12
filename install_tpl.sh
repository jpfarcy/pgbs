#!/bin/bash
#
# ------------------------------------------------------------------------------
#  Copyright (c) 2013, Jean-Philippe Farcy
#  This file is part of Postgres Backup Suite (PGBS).
#
#  Postgres Backup Suite (PGBS) is free software: you can redistribute 
#  it and/or modify it under the terms of the GNU General Public License
#  as published by the Free Software Foundation, either version 3 of
#  the License, or (at your option) any later version.
#
#  Postgres Backup Suite (PGBS) is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with Foobar.  If not, see <http://www.gnu.org/licenses/>.
# ------------------------------------------------------------------------------
#
#@JP	===============================================================================
#@JP	
#@JP	         FILE: install.sh
#@JP	
#@JP	        USAGE: source /rootdir/pgbs/install.sh
#@JP	  DESCRIPTION: Postgresql Backup Suite Installer
#@JP	               Install PGBS.  
#@JP	
#@JP	      OPTIONS: ---
#@JP	 REQUIREMENTS: uudecode, uuencode, let, tail, tar
#@JP	         BUGS: ---
#@JP	        NOTES: This script may only work on OS bash is implemented
#@JP	       AUTHOR: FARCY jean-philippe (), 
#@JP	          WEB: https://github.com/jpfarcy/pgbs 
#@JP	      VERSION: 1.5
#@JP	      CREATED: 07/01/2013 15:26:10
#@JP	     REVISION: 0 
#@JP	===============================================================================
# 
echo "===============================================================================
                 Postgres Backup Suite Installer (pgbs)  
==============================================================================="
# You should be root to run this scripts otherwise install manually
rootdir="/opts/pgbs"
if [ "$(id -un)" != "root" ]; then
	echo "ERR : This script must be run as root. Exiting."
	exit 1;
fi;
# This script needs to run uuencode
if [[ ! -x $(which uudecode) ]]; then
	echo -e "The scripts needs uudecode !\n Try to install it.\n Debian:'apt-get install sharutils'"
	exit 1;
fi
# Directory where pgbs will be installed
read -p "Choose PGBS install directory [/opt/pgbs]:" rootdir
rootdir=${rootdir:=/opt/pgbs}

# User that PGBS scripts run under
read -p "User PGBS that scripts run under [root]:" username
username=${username:=root}
if ! $(id -u $username >/dev/null 2>&1); then
	echo "user doesn't exist"
	exit 1
fi
# Lang of config file
read -p "Choose lang of PGBS default config file [fr]:" lang
lang=${lang:=fr}
# Backup existing conf
if [[ -L $rootdir/cfg/pgbackup.config ]]; then
	cfgfile=$(readlink "$rootdir/cfg/pgbackup.config")
	mv $rootdir/cfg/$cfgfile $rootdir/cfg/pgbackup.config.bkp
fi
# Install
[[ -d $rootdir ]] || mkdir -p $rootdir	|| (echo "ERR : Cannot create $rootdir"; exit 1)
if $(id -g $username >/dev/null 2>&1); then
	CHOWNOPT="${username}:${username} $rootdir"
else
	CHOWNOPT="${username}:root $rootdir"
fi
installerDir=$(dirname $0)
if [[ $installerDir == "." ]]; then
        installerDir=`pwd`
fi
installerBase=$(basename $0)

line=$(grep --text --line-number "^::PGBS::$" ${installerDir}/${installerBase} |cut -d: -f1 -)
let line=line+1
cd $rootdir
tail -n +$line ${installerDir}/${installerBase} | uudecode | tar -xf -
[[ $? == 0 ]] || (echo "ERR : Install failed !";exit 2)
chown -R $CHOWNOPT
ln -sf $rootdir/cfg/pgbackup_${lang}.config $rootdir/cfg/pgbackup.config	
echo -e "PGBS is Installed\nEnjoy !"
exit 0;
::PGBS::
