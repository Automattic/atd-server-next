#
# run through a corpus and transform matching sentences using the specified rules.
#

java -Xmx3384M -XX:+AggressiveHeap -XX:+UseParallelGC -jar lib/sleep.jar utils/rules/transr.sl $1 $2
