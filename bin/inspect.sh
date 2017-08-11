#
# startup script for AtD web service
#

#!/bin/sh

export PRODUCTION=/home/atd
export ATD_HOME=/home/atd/atd
export LOG_DIR=$ATD_HOME/logs

export LC_CTYPE=en_US.UTF-8
export LANG=en_US.UTF-8

java -Datd.lowmem=true -Dfile.encoding=UTF-8 -Xmx3512M -XX:+AggressiveHeap -XX:+UseParallelGC -jar lib/sleep.jar utils/bigrams/inspect.sl

