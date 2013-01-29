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
#@JP	         FILE: pgbackup.sh
#@JP	
#@JP	        USAGE: ./pgbackup.sh -c  /dir/where/is/your/configfile [t | l]  
#@JP	                  -t | Test your backup config
#@JP	                  -l | List your backups files
#@JP	  DESCRIPTION: A bash script to backup your Postgresql Cluster. It support dump,
#@JP	               dumpall and hot tar (whith tablespace). You can use it
#@JP	               to make vacuum, analyse and reindex your databases.  
#@JP	
#@JP	      OPTIONS: configfile(-c), list backup(-l), config test (-t)
#@JP	 REQUIREMENTS: PGBS (Postgres Backup Suite) Library (libpgbs.sh)
#@JP	         BUGS: ---
#@JP	        NOTES: This script may only work on OS bash is implemented
#@JP	       AUTHOR: FARCY jean-philippe (), 
#@JP	          WEB: https://github.com/jpfarcy/pgbs
#@JP	      VERSION: 1.1
#@JP	      CREATED: 23/01/2013 10:03:43
#@JP	     REVISION: 0 
#@JP	===============================================================================
#
# -----------------------------
# Variables Obligatoires 
# -----------------------------
PGBS_BASEDIR="/opt/pgbs"
PGBS_BINDIR="${PGBS_BASEDIR}/bin"
PGBS_LIBDIR="${PGBS_BASEDIR}/lib"
PGBS_CFGDIR="${PGBS_BASEDIR}/cfg"
PGBS_LOGDIR="${PGBS_BASEDIR}/log"
source ${PGBS_LIBDIR}/libpgbs.sh
PGBS_SCRIPT="$( basename ${0} | awk -F. '{ print $1 }' )"
PGBS_MAIL=""
CONFIGFILE="${PGBS_CFGDIR}/pgbackup.config"
BACKUPS_DATE_FORMAT=$(date +%Y-%m-%d-%Hh%Mm%Ss)
PGBS_LOGFILE="${PGBS_LOGDIR}/${PGBS_SCRIPT}_${BACKUPS_DATE_FORMAT}.log"
[[ -d ${PGBS_LOGDIR} ]] || mkdir -p ${PGBS_LOGDIR} || fPrintErr "Cannot create backup directory :\t${PGBS_LOGDIR}"
# ---------------
# FUNCTIONS
# ---------------
function fHelp
{
	grep ^#@JP ${0} | sed '1,$s/#@JP//g'
	exit 0;
}
# ------------------------------------------------------------------------------
# Section prise en compte et controle des parametres
# ------------------------------------------------------------------------------
while getopts c:tlh opt
do
    case $opt in
        c )    typeset -x CONFIGFILE="${OPTARG}" ;;
        l )    BACKUPLIST=1 ;;
        t )    CONFIGTEST=1 ;;
        h )    fHelp ;;
        \?)    fHelp ;;
    esac
done


if [[ -r $CONFIGFILE ]]; then
    source $CONFIGFILE
else
    fPrintErrExit "Cannot read config file : $CONFIGFILE"
fi

if [ "$BACKUP_USER" != "" -a "$(id -un)" != "$BACKUP_USER" ]; then
	fPrintErrExit "This script must be run as $BACKUP_USER. Exiting."
fi;

#-------------------------------------------
# INITIALISATION  et Controle DES VARIABLES
#-------------------------------------------
fInitVar

# ----------------------
# Section Principale
# ----------------------
if [[ $BACKUPLIST ]]; then
    fBackupList
    exit 0
fi

if [[ $CONFIGTEST ]]; then
    fConfigTest
    exit 0
fi

# Export de toutes les bases du cluster
if [[ $BACKUPS_TYPE_EXP == "yes" ]]; then
	fBackupRotate "exp"
	fExport
fi

# Pg_dumpall du cluster
if [[ $BACKUPS_TYPE_ALL == "yes" ]]; then
	fBackupRotate "all"
	fExportAll
fi

# Tar du cluster
if [[ $BACKUPS_TYPE_TAR == "yes" ]]; then
	fBackupRotate "tar"
	fTarCluster
fi

# Traitement du cluster
if [ $PG_VACUUM == "yes" -o $PG_REINDEX == "yes" ]; then
	fPgTrt
fi
# Backup Postgres Config
if [[ $BACKUPS_TYPE_CONF == "yes" ]]; then
    fBkpConf
fi
# END
if grep "ERREUR" $PGBS_LOGFILE; then
    [[ $EXT_CMD == "yes" ]] && $EXT_CMD_Err
    fPrintErrExit "===============================================================================
                !! ERROR !!  Backups finished with error
==============================================================================="
else
    [[ $EXT_CMD == "yes" ]] && $EXT_CMD_Ok
    fPrintOkExit "===============================================================================
                 Backups finished without error
==============================================================================="
fi

