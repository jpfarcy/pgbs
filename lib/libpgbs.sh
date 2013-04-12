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
#@JP	         FILE: libpgbs.sh
#@JP	
#@JP	        USAGE: source /rootdir/pgbs/lib/libpgbs.sh
#@JP	  DESCRIPTION: Postgresql Backup Suite Library
#@JP	               contain functions for pgbs suite scripts.  
#@JP	      OPTIONS: ---
#@JP	 REQUIREMENTS: ---
#@JP	         BUGS: ---
#@JP	        NOTES: This script may only work on OS bash is implemented
#@JP	       AUTHOR: FARCY jean-philippe (), 
#@JP	          WEB: https://github.com/jpfarcy/pgbs 
#@JP	      VERSION: 1.5
#@JP	      CREATED: 22/12/2012 10:03:43
#@JP	     REVISION: 0 
#@JP	===============================================================================
#
function fInitVar
{
	# --------------------------
	#  Connection Parameters
	# --------------------------
	
	# --- Choose between Hostname and Socket
	fSockOrHost
 	
 	: ${PG_USER:=postgres}
		
	: ${PG_PORT:=5432}
	
	: ${PG_PATH:=/usr/bin}	
	
	: ${PG_DATA:=$PGDATA}

	if [[ $BACKUPLIST -ne 1 ]];then
		# --- On test les binaires de dump PG et psql si pas present on sort
		fTestPgBin
		# --- On test une connection à la base postgres
		fTestPgConn
	fi
	
	# --------------------------
	#  Backups Parameters
	# --------------------------
	# --- General
	: ${BACKUP_DIR:=/var/backups}
	[[ -d $BACKUP_DIR ]] || fCreateDir $BACKUP_DIR
	
	if [[ ! $PG_DB_LISTE ]]; then
		fGetDbList
	fi
	
	: ${PG_CLUSTER:=cluster_${PG_PORT}}
	#if [[ ! $PG_CLUSTER ]]; then
	#	PG_CLUSTER="cluster_${PG_PORT}"
	#fi
	
	# --- Exports
	
	: ${BACKUPS_TYPE_ALL:=yes}
	: ${BACKUPS_TYPE_EXP:=yes}	
		
	if [ $BACKUPS_TYPE_ALL == "yes" -o $BACKUPS_TYPE_EXP == "yes" ]; then
		: ${BACKUPS_FORMAT:=custom}
		
		: ${PG_EXPORT:=${BACKUP_DIR}/${PG_CLUSTER}/exports}		
		[[ -d $PG_EXPORT ]] || fCreateDir $PG_EXPORT
	
		: ${COMPRESS:=yes}
		: ${COMPRESS_BIN:=$(which gzip)}
		[[ -x $COMPRESS_BIN ]] || fPrintErrExit "$COMPRESS_BIN DOES NOT EXIST"
	
		if [[ $BACKUPS_NOOWNER == "yes" ]]; then
			BACKUPS_NOOWNER="--no-owner"
		fi
				
		: ${BACKUPS_RETENTION_EXP:=7}
		: ${BACKUPS_RETENTION_ALL:=7}

	fi
	
	# --- Tar
	: ${BACKUPS_TYPE_TAR:=no}
	if [[ $BACKUPS_TYPE_TAR == "yes" ]]; then
		: ${PG_TAR_IN:=$PG_DATA}
		[[ ! $PG_TAR_IN ]] && fPrintErrExit "$PG_CLUSTER: Le chemin ou se trouve le cluster doit etre definit : PG_TAR_IN"
		
		TAR_BIN=$(which tar)
		[[ -x $TAR_BIN ]] || fPrintErrExit "$TAR_BIN DOES NOT EXIST"
		
		: ${PG_TAR_OUT:=$BACKUP_DIR/$PG_CLUSTER/tar}
		[[ -d $PG_TAR_OUT ]] || fCreateDir $PG_TAR_OUT
				
		: ${BACKUPS_RETENTION_TAR:=7}
		
	fi
	
	# --- conf
	: ${BACKUPS_TYPE_CONF:=yes}
	if [[ $BACKUPS_TYPE_CONF == "yes" ]]; then
		[[ ! $PG_DATA ]] && fPrintErrExit "$PG_CLUSTER: Le chemin ou se trouve le cluster doit etre definit : PG_DATA"
		: ${BACKUPS_DIR_CONF:=$BACKUP_DIR/$PG_CLUSTER/conf}
		[[ -d $BACKUPS_DIR_CONF ]] || fCreateDir $BACKUPS_DIR_CONF
		: ${BACKUPS_RETENTION_CONF:=7}
	fi
	
	# ----------------------------
	#  Batch Parameters
	# ----------------------------
	: ${PG_VACUUM:=yes}
	: ${VACUUM_TYPE:=full}
	: ${PG_ANALYSE:=yes}
	: ${PG_REINDEX:=yes}
	
	# ----------------------------
	#  Others Parameters
	# ----------------------------
	: ${PGBS_MAIL:=no}
	: ${EXT_CMD:=no}

} # END fInitVar

# --- Display configuration parameters
function fConfigTest
{
	echo "***************************"
	echo "  Connection Informations  "
	echo "***************************"
	echo "Host: $PG_SOCKDIR"
	echo "User: $PG_USER"
	echo "Port: $PG_PORT"
	echo "PGDATA: $PG_DATA"
	echo "Postgresql binaries path: $PG_PATH"
	echo "Test Connection: $PG_CONN"
	echo "*********************************"
	echo " Cluster / Database Informations "
	echo "*********************************"
	echo "Cluster name: $PG_CLUSTER"
	echo "Databases list: ${PG_DB_LISTE}"
	echo "*****************************"
	echo " Backups Informations"
	echo "*****************************"
	echo "Backups directory: $BACKUP_DIR"
	if [[ $BACKUPS_TYPE_EXP == "yes" ]]; then
		echo "- Export"
		echo " dump each base: $BACKUPS_TYPE_EXP"
		echo " Format: $BACKUPS_FORMAT"
		echo " Destination: $PG_EXPORT"
		echo " Retention policy: $BACKUPS_RETENTION_EXP days"
	fi
	if [[ $BACKUPS_TYPE_ALL == "yes" ]]; then
		echo "- Export All"
		echo " DumpAll: $BACKUPS_TYPE_ALL"
		echo " Destination: $PG_EXPORT"
		echo " Retention policy: $BACKUPS_RETENTION_ALL days"
	fi
	if [[ $BACKUPS_TYPE_TAR == "yes" ]]; then
		echo "- Tar"
		echo " Tar: $BACKUPS_TYPE_TAR"
		echo " Origin: $PG_TAR_IN"
		echo " Destination: $PG_TAR_OUT"
		echo " Retention policy: $BACKUPS_RETENTION_TAR days"
		fGetTbList
		echo " Tablespaces list: $PG_TB_LIST"
	fi
	echo "*************************"
	echo " Batch Informations      "
	echo "*************************"
	echo "Vacuum: $VACUUM_TYPE"
	echo "Analyse: $PG_ANALYSE"
	echo "Reindex: $PG_REINDEX"
}

# --- Test Postgresql Connection
function fTestPgConn
{
	echo "\q" | $PG_PATH/psql -h $PG_SOCKDIR -p $PG_PORT -U $PG_USER > /dev/null 2>&1
	if [[ $? -ne 0 ]]; then
		if [[ $CONFIGTEST -eq 1 ]]; then
			 PG_CONN="KO"
		 else
			fPrintErrExit "could not connect to $PG_SOCKDIR port $PG_PORT user $PG_USER !"
		fi
	else
		if [[ $CONFIGTEST -eq 1 ]]; then
			 PG_CONN="OK"
		 else
			CMD_PSQL="$PG_PATH/psql -h $PG_SOCKDIR -p $PG_PORT -U $PG_USER"
			CMD_PG_DUMP="$PG_PATH/pg_dump -h $PG_SOCKDIR -p $PG_PORT -U $PG_USER"
			CMD_PG_DUMPALL="$PG_PATH/pg_dumpall -h $PG_SOCKDIR -p $PG_PORT -U $PG_USER"
		fi
	fi
}
# --- Test postgresql binaries
function fTestPgBin
{
	for S_BIN in pg_dumpall pg_dump psql; do
		[ ! -x "${PG_PATH}/${S_BIN}" ] && fPrintErrExit "$PG_PATH/pg_dump DOES NOT EXIST"
	done
} 
# --- Connection method : Hostname or Socket 
function fSockOrHost
{
	if [ "$PG_HOSTNAME" != "" -a "$PG_SOCKDIR" != "" ]; then
		fPrintErrExit "YOU MUST CHOOSE PG_HOSTNAME OR PG_SOCKDIR"
	fi
	if [[ ! $PG_SOCKDIR ]]; then
		if [[ ! $PG_HOSTNAME ]]; then
			PG_SOCKDIR="localhost"
		else
			PG_SOCKDIR="$PG_HOSTNAME"
		fi
	fi	
}
# --- Create Directory
function fCreateDir
{
	if [[ $CONFIGTEST -ne 1 ]]; then
		DIR=$@
		MKDIR=$(which mkdir)
		fExecute "$MKDIR -p $DIR"
		[[ $? == 0 ]] ||  fPrintErrExit "CANNOT CREATE DIRECTORY : $DIR"
	fi
}
# --- Create database list, if not specified in config file
function fGetDbList
{
	if [[ "${PG_DB_LISTE}" == "" ]] ; then
		# recherche la liste des bases a sauvegarder = toutes sauf postgres et template
		PG_DB_LISTE=`echo "SELECT datname FROM pg_stat_database WHERE datname != 'postgres' AND datname NOT LIKE 'template%';" \
		  | psql -h ${PG_SOCKDIR} -p ${PG_PORT} --pset tuples_only 2>/dev/null \
		  | perl -p -e 's/\n//'`
	fi
}

#---- Create tablespace list
function fGetTbList
{
    PG_TB_LISTE=`echo "SELECT spcname from pg_tablespace WHERE spcname != 'pg_default' AND spcname != 'pg_global';" \
            | psql -h ${PG_SOCKDIR} -p ${PG_PORT} --pset tuples_only 2>/dev/null \
            | perl -p -e 's/\n//'`
}

# --- dump cluster database ---
function fExport
{
	
	for S_DB in ${PG_DB_LISTE}; do
		unset OPTS
		OPTS="${BACKUPS_NOOWNER}"
		# --- Dump schema
		fExecute "${CMD_PG_DUMP} -b --create --oids --schema-only --format=p ${S_DB} > ${PG_EXPORT}/pg_dump-${S_DB}_schema_${BACKUPS_DATE_FORMAT}.sql"
		[[ $? == 0 ]] ||  fPrintErrExit "${PG_CLUSTER},$S_DB: EXPORT SCHEMA FAILED"
		if [[ $BACKUPS_FORMAT == "plain" ]]; then
			if [[ $COMPRESS == "no" ]]; then 
				OPTS="$OPTS --format=p ${S_DB}"
				FILEXT="sql"
			else
				OPTS="$OPTS --format=p ${S_DB}| $COMPRESS_BIN"
				FILEXT="sql.gz"
			fi
			FINAL_BACKUP_FILE="${PG_EXPORT}/pg_dump-${S_DB}_${BACKUPS_FORMAT}_${BACKUPS_DATE_FORMAT}.${FILEXT}"
			
		elif [[ $BACKUPS_FORMAT == "tar" ]]; then
			FINAL_BACKUP_FILE="pg_dump-${PG_EXPORT}/pg_dump-${S_DB}_${BACKUPS_FORMAT}_${BACKUPS_DATE_FORMAT}.dump"
			OPTS="$OPTS --format=t ${S_DB}"
		elif [[ $BACKUPS_FORMAT == "custom" ]]; then
			FINAL_BACKUP_FILE="${PG_EXPORT}/pg_dump-${S_DB}_${BACKUPS_FORMAT}_${BACKUPS_DATE_FORMAT}.dump"
			OPTS="$OPTS --format=c ${S_DB}"
		else
			fPrintErrExit "${PG_CLUSTER},$S_DB: $BACKUPS_FORMAT BACKUP FORMAT DOES NOT EXIST !"
		fi
		fExecute "${CMD_PG_DUMP} -b --create --oids $OPTS > ${FINAL_BACKUP_FILE}.in_progress"
		[[ $? == 0 ]] ||  fPrintErrExit "${PG_CLUSTER},$S_DB: EXPORT FAILED $FINAL_BACKUP_FILE"
		mv ${FINAL_BACKUP_FILE}.in_progress $FINAL_BACKUP_FILE
		fPrintOk "INFO : ${PG_CLUSTER},$S_DB: EXPORT DONE"
	done
}

# --- dumpall postgresql cluster
function fExportAll
{
	fPrintOk "${PG_CLUSTER}: DumpAll"
	OPTS_EA="${BACKUPS_NOOWNER}"
	if [[ $COMPRESS == "no" ]]; then 
		OPTS_EA="$OPTS_EA"
		FILEEXT="sql"
	else
		OPTS_EA="$OPTS_EA | $COMPRESS_BIN"
		FILEEXT="sql.gz"
	fi
	
	# --- Dumpall cluster
	fExecute "${CMD_PG_DUMPALL} --clean --oids $OPTS_EA > ${PG_EXPORT}/pg_dumpall-${PG_CLUSTER}_${BACKUPS_DATE_FORMAT}.${FILEEXT}.in_progress"
	[[ $? == 0 ]] ||  fPrintErrExit "${PG_CLUSTER}: EXPORT ALL FAILED ${PG_EXPORT}/pg_dumpall-${PG_CLUSTER}_${BACKUPS_DATE_FORMAT}.${FILEEXT}.in_progress"
	mv ${PG_EXPORT}/pg_dumpall-${PG_CLUSTER}_${BACKUPS_DATE_FORMAT}.${FILEEXT}.in_progress ${PG_EXPORT}/pg_dumpall-${PG_CLUSTER}_${BACKUPS_DATE_FORMAT}.${FILEEXT}
	fPrintOk "INFO : ${PG_CLUSTER}: EXPORT ALL DONE"
	
}
function fBkpConf
{
	if [[ $COMPRESS == "no" ]]; then 
		OPTS_CONF="$OPTS_CONF"
		FILEEXT="sql"
	else
		OPTS_CONF="$OPTS_CONF | $COMPRESS_BIN"
		FILEEXT="sql.gz"
	fi
	# --- Dumpall globals only
	fExecute "${CMD_PG_DUMPALL} --globals-only --clean --oids $OPTS_CONF > ${BACKUPS_DIR_CONF}/pg_dumpall-${PG_CLUSTER}_globals-only_${BACKUPS_DATE_FORMAT}.${FILEEXT}.in_progress"
	[[ $? == 0 ]] ||  fPrintErr "${PG_CLUSTER}: EXPORT ALL FAILED ${BACKUPS_DIR_CONF}/pg_dumpall-${PG_CLUSTER}_globals-only_${BACKUPS_DATE_FORMAT}.${FILEEXT}.in_progress"
	mv ${BACKUPS_DIR_CONF}/pg_dumpall-${PG_CLUSTER}_globals-only_${BACKUPS_DATE_FORMAT}.${FILEEXT}.in_progress ${BACKUPS_DIR_CONF}/pg_dumpall-${PG_CLUSTER}_globals-only_${BACKUPS_DATE_FORMAT}.${FILEEXT}
	fPrintOk "INFO : ${PG_CLUSTER}: EXPORT ALL 'globals-only' DONE"
	# --- Sav config file
	for i in pg_hba postgresql; do
		cp $PG_DATA/${i}.conf $BACKUPS_DIR_CONF/${i}-${PG_CLUSTER}_${BACKUPS_DATE_FORMAT}.conf
		[[ $? == 0 ]] ||  fPrintErr "Backup $i.conf FAILED !"
	done
}
function fTarCluster 
{
	fPrintOk "INFO : $PG_CLUSTER :Hot Cluster Backup (TAR)"
	# trap to remove the backup label in case of interruption of the script
	trap "fPgStopBackup" 0
	# Tag the WAL with a backup label
	fPgStartBackup	
	# make postgresql tar	
	OUT="${PG_TAR_OUT}/pg_tar-${PG_CLUSTER}_${BACKUPS_DATE_FORMAT}.tar.gz"
	# TODO exclude dir ex: archiveslogs
	#OUTARCH="${PG_TAR_OUT}/pg_tar-${PG_CLUSTER}_${BACKUPS_DATE_FORMAT}_arch.tar.gz"
	#fExecute "tar cfz $OUT.in_progress ${PG_TAR_IN} --exclude ${PG_TAR_IN}/archiveslogs/*.gz"
	fExecute "tar cfz $OUT.in_progress ${PG_TAR_IN}"
	RET=$?
	[[ $RET -eq 2 ]] && fPrintErr "${PG_CLUSTER}: FAILED TO MAKE"
	mv $OUT.in_progress $OUT
	# make tar of every tablespace
	fGetTbList
	if [[ PG_TB_LISTE ]]; then
		for S_TB in ${PG_TB_LISTE}; do
			OUTB="${PG_TAR_OUT}/pg_tar-${PG_CLUSTER}_${BACKUPS_DATE_FORMAT}_${S_TB}.tar.gz"
			INTB=`echo "SELECT spclocation from pg_tablespace WHERE spcname = '${S_TB}';" \
				| $CMD_PSQL --pset tuples_only \
					| perl -p -e 's/\n//'`
			fExecute "tar cfz $OUTB.in_progress $INTB"
			RET=$?
			[[ $RET -eq 2 ]] && fPrintErr "$PG_CLUSTER: FAILED TO MAKE TAR OF TABLESPACE ${INTB}"
			mv ${OUTB}.in_progress $OUTB
		done
	fi
	# Delete the backup label 
	trap - 0
	fPgStopBackup
	sleep 10
	# TODO exclude dir ex: archiveslogs
	#fExecute "tar cfz ${OUTARCH}.in_progress ${PG_TAR_IN}/archiveslogs"
	#RET=$?
	#[[ $RET -eq 2 ]] && fPrintErrExit "$PG_CLUSTER: FAILED TO MAKE ARCHIVESLOGS TAR"
	#mv ${OUTARCH}.in_progress $OUTARCH
	fPrintOk "INFO : ${PG_CLUSTER}: TAR IS DONE !"
}

function fPgStopBackup 
{
	# Delete the backup label
	fExecute "echo \"SELECT pg_stop_backup();\" | $CMD_PSQL"
}

function fPgStartBackup
{
	# Tag the WAL with a backup label
	fExecute "echo \"SELECT pg_start_backup('${PG_CLUSTER}_backup')\" | $CMD_PSQL"
}

# --- Do Batch on Postgresql Cluster
# Vacuum, Analyse, Reindex
function fPgTrt
{
	
	if [[ $PG_VACUUM == "yes" ]]; then
		OPTS_TRT="-a"
		if [[ $PG_VACUUM == "full" ]]; then
			OPTS_TRT="$OPTS_TRT -f"
		fi 
		if [[ $PG_ANALYSE == "yes" ]]; then
			OPTS_TRT="$OPTS_TRT -z"
		fi
		fExecute "$PG_PATH/vacuumdb $OPTS_TRT -h ${PG_SOCKDIR} -p ${PG_PORT} -U $PG_USER"
		[[ $? -ne 0 ]] && fPrintErr "$PG_CLUSTER: LE VACCUM A ECHOUE."
	fi
	if [[ $PG_REINDEX == "yes" ]]; then
		fExecute "$PG_PATH/reindexdb -a -h ${PG_SOCKDIR} -p ${PG_PORT} -U $PG_USER"
		[[ $? -ne 0 ]] && fPrintErr "$PG_CLUSTER: LE REINDEXDB A ECHOUE."
	fi
}

# --- Rotate backups
function fBackupRotate
{
	case $@ in
		exp)
			(find $PG_EXPORT -name "pg_dump-*" -mtime +${BACKUPS_RETENTION_EXP} -exec rm {} \;)
			;;
		all)
			(find $PG_EXPORT -name "pg_dumpall-*" -mtime +${BACKUPS_RETENTION_ALL} -exec rm {} \;)
			;;
		tar)
			(find $PG_TAR_OUT -name "pg_tar-*" -mtime +${BACKUPS_RETENTION_TAR} -exec rm {} \;)
			;;
	esac
}

# --- Backups List 
function fBackupList
{
	FILE_EXP=( $(ls -1rt $PG_EXPORT 2>/dev/null) )
	FILE_TAR=( $(ls -1rt $PG_TAR_OUT 2>/dev/null) )
	echo "+- ${BACKUP_DIR}"
	echo "|- $PG_CLUSTER" 
	if [[ -d $PG_EXPORT ]]; then
		echo "  |- exports"
		COUNTER=0
		while [  $COUNTER -lt $((${#FILE_EXP[*]} - 1)) ]; do
			echo "  | |- ${FILE_EXP[$COUNTER]}" 
			let COUNTER=COUNTER+1 
		done
		echo "  | \`- ${FILE_EXP[$COUNTER]}"
	fi
	if [[ -d $PG_TAR_OUT ]]; then
		echo "  \`- tar"
		TARCOUNT=0
		while [  $TARCOUNT -lt $((${#FILE_TAR[*]} - 1)) ]; do
			echo "    |- ${FILE_TAR[$TARCOUNT]}" 
			let TARCOUNT=TARCOUNT+1 
		done
		echo "    \`- ${FILE_TAR[$TARCOUNT]}"
	fi
}

# --- Send Mail
function fMailLog
{
	cat $1 | mail -s "$PGBS_MAIL_SUB" $PGBS_MAIL_ADR
}

# -----------------------------------------
# Print and Log Functions
# -----------------------------------------
# -----------------------------------------
# Description of Print and Log Functions
# -----------------------------------------
#
#        |   print   |     Exit      |
# -------|-----------|---------------|
# info   | fPrintOk  | fPrintOkExit  |
# erreur | fPrintErr | fPrintErrExit |
#
function fPrint
{
	unset s_OUTPUT
	unset i_RC
	unset i_EXIT
	unset i_MAIL
	unset i_EXTCMD
	
	FONCTION="$1"
	MESSAGE="$2"
	if [[ "$FONCTION" =~ "Ok" ]] ; then
		s_OUTPUT="$MESSAGE"
		i_RC=0
		i_EXTCMD="Ok"
	fi
	if [[ "$FONCTION" =~ "Err" ]] ; then
		s_OUTPUT="--- ERROR ---\n$MESSAGE"
		i_RC=2
		i_EXTCMD="Err"
	fi
	if [[ "$FONCTION" =~ "Exit" ]] ; then
		i_EXIT=1
	fi
		
	echo -e "+---------------------+\n| $( date '+%Y/%m/%d %H:%M:%S' ) |\n+---------------------+\n$s_OUTPUT" | tee -a  ${PGBS_LOGFILE}

	if [[ ${i_EXIT} -eq 1 ]] ; then
		exit ${i_RC}
	fi
	return ${i_RC}
	
}
# --- fPrintOk ---
function fPrintOk
{
	fPrint "$FUNCNAME" "$@"
}
function fPrintOkExit
{
	fPrint "$FUNCNAME" "$@"
}

# --- fPrintErr ---
function fPrintErr
{
	fPrint "$FUNCNAME" "$@"
}
function fPrintErrExit
{
	fPrint "$FUNCNAME" "$@"
}

# -----------------------------------------


# -----------------------------------------
# Execute Functions
# -----------------------------------------
# -----------------------------------------
# Description of Execute Functions
# -----------------------------------------
#
#        | fExecute   | fExecuteExit  |
# -------|----------------------------|
# info   | fPrintOk   | fPrintOkExit  |
# erreur | fPrintErr  | fPrintErrExit |
#
function fExecuteCommand
{ 
	FONCTION="$1"
	COMMAND="$2"
	CONCAT="fPrint"
	CmdResult=$( eval "${COMMAND}" 2>&1 )
	CmdRc=${?}
	
	if [ ${CmdRc} -ne 0 ] ; then
		CONCAT="${CONCAT}Err" 
	else
		CONCAT="${CONCAT}Ok"
	fi
	if [[ "$FONCTION" =~ "Mail" ]] ; then
		CONCAT="${CONCAT}Mail"
	fi
	if [[ "$FONCTION" =~ "Exit" ]] ; then
		CONCAT="${CONCAT}Exit"
	fi
	$CONCAT " COMMAND : ${COMMAND}\n RETURN CODE : ${CmdRc}\n RESULT : ${CmdResult}\n"
	return ${CmdRc} 
}
function fExecute
{
	fExecuteCommand "$FUNCNAME" "$@"
}
function fExecuteExit 
{
	fExecuteCommand "$FUNCNAME" "$@"
}

# -----------------------------------------
