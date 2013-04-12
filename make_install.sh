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
: ${RET:=OK}
rm -f install.sh
cp install_tpl.sh install.sh
[[ $? == 0 ]] || RET="ERR" 
tar cvf pgbs.tar bin cfg lib
[[ $? == 0 ]] || RET="ERR"
[[ $(grep "::PGBS::" install.sh) ]] || echo "::PGBS::" >> install.sh
cat pgbs.tar | uuencode - >> install.sh
[[ $? == 0 ]] || RET="ERR"
rm -f pgbs.tar
echo "[ $RET ] install.sh"
