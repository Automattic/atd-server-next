#
# This script creates the AtD rules
#

java -Datd.lowmem=true -Xmx3536M -XX:+AggressiveHeap -XX:+UseParallelGC -jar lib/sleep.jar utils/rules/rules.sl
