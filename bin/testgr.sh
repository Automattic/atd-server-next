java -Datd.lowmem=true -Xmx4048M -XX:+AggressiveHeap -XX:+UseParallelGC -jar lib/sleep.jar utils/rules/testgr.sl data/tests/grammar_wikipedia.txt
java -Datd.lowmem=true -Xmx4048M -XX:+AggressiveHeap -XX:+UseParallelGC -jar lib/sleep.jar utils/rules/testgr.sl data/tests/grammar_gutenberg.txt
