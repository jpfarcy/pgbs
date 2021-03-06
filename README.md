# PGBS (Postgresql Backup Suite)

is a colection of scripts for backuping your Postgres databases.  
Nothing very new, this suite is a summary of my Postgres administrator experience.  

## Description
It backup your Postgresql databases. I postulated that the you have a backup software (ex: bacula), so this software does not handle policy as backup per week, per month, per year.  
This Software handles exports of bases, "Dump all" postgres cluster and On-line backups (need tar and wal archiving) 
### What PGBS can do : 
* In the on-line backup PGBS manages the use of tablespsaces.
* Backup your Postgres config (postgresql.conf, pg_hba.conf)
* Do vacuum, analyse, reindex
* list your backups (-l)
* test your config (-t)
* use sockdir ou hostname
* Possibility to appoint the cluster
* Choose script user, postgres super-user, port, postgres engine path, database path (initdb) etc ...
* Choose the backup you want dump or/and dump_all or/and on-line (tar)
* Choose dump backup type (plain, custom, tar)
* Set if you want compress the plain backup
* Choose Compression utility
* Set the "no-owner" option to clone database
* Set a very small retention policy
* Possibility to set a external command when the script ending whith success
* Possibility to set a external command when the script ending whith error

## Installation
Just dowload the zip file, and use the install.sh inside. Follow the instructions.  
```bash
root@postgres1:# ./install.sh  
===============================================================================  
            Postgres Backup Suite Installer (pgbs)  
===============================================================================  
Choose PGBS install directory [/opt/pgbs]: 
User PGBS that scripts run under [root]:postgres  
Choose lang of PGBS default config file [fr]:  
PGBS is Installed 
Enjoy ! 
```
## Usage
By default the config file is /opt/pgbs/cfg/pgbackup.config, otherwise use *-c* option
```bash
./pgbackup.sh -c  /dir/where/is/your/configfile [t | l]  
       -t | Test your backup config  
       -l | List your backups files  
```
## Configuration
Read the configuration file PGBS_PATH/cfg/pgbackup.config


## Legal

PGBS is released under the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
[Postgresql](http://www.postgresql.org) is a registered [trademark](http://wiki.postgresql.org/wiki/Trademark_Policy).
