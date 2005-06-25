#
##########################################################################
#
#  Author: Michael Rash (mbr@cipherdyne.org)
#
#  Credits:  (see the CREDITS file)
#
#  Version: 1.4.1
#
#  Copyright (C) 1999-2002 Michael Rash (mbr@cipherdyne.org)
#
#  License (GNU Public License):
#
#     This program is distributed in the hope that it will be useful,
#     but WITHOUT ANY WARRANTY; without even the implied warranty of
#     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#     GNU General Public License for more details.
#
#     You should have received a copy of the GNU General Public License
#     along with this program; if not, write to the Free Software
#     Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307
#     USA
#
##########################################################################
#
#  $Id$
#

### default
all : kmsgsd.c psadwatchd.c psad_funcs.c strlcpy.c strlcat.c psad.h
	/usr/bin/gcc -Wall kmsgsd.c psad_funcs.c strlcpy.c strlcat.c -o kmsgsd
	/usr/bin/gcc -Wall psadwatchd.c psad_funcs.c strlcpy.c strlcat.c -o psadwatchd

### debug mode
debug : kmsgsd.c psadwatchd.c psad_funcs.c strlcpy.c strlcat.c psad.h
	/usr/bin/gcc -Wall -g -DDEBUG kmsgsd.c psad_funcs.c strlcpy.c strlcat.c -o kmsgsd
	/usr/bin/gcc -Wall -g -DDEBUG psadwatchd.c psad_funcs.c strlcpy.c strlcat.c -o psadwatchd

#install : kmsgsd
#	if [ -x kmsgsd ]; then \
#		/bin/cp kmsgsd /usr/sbin/kmsgsd

clean :
	if [ -f a.out ]; then rm a.out; fi
	if [ -f core ]; then rm core; fi
	if [ -f kmsgsd ]; then rm kmsgsd; fi
	if [ -f psadwatchd ]; then rm psadwatchd; fi
