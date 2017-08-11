#!/bin/sh
#
# startup script for AtD web service
#

export LC_CTYPE=en_US.UTF-8
export LANG=en_US.UTF-8

java -Dfile.encoding=UTF-8 -XX:+AggressiveHeap -XX:+UseParallelGC -Datd.lowmem=true -Dbind.interface=127.0.0.1 -Dserver.port=1049 -Dsleep.classpath=$ATD_HOME/lib:$ATD_HOME/service/code -Dsleep.debug=24 -classpath ./lib/sleep.jar:./lib/moconti.jar:./lib/spellutils.jar:./lib/* httpd.Moconti atdconfig.sl
