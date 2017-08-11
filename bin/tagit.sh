#
java -Datd.lowmem=true -Xmx3384M -XX:+AggressiveHeap -XX:+UseParallelGC -jar lib/sleep.jar utils/tagger/tagit.sl $1
