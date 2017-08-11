# find homophones in corpus for a language
# ./bin/amigo.sh [language]

java -Xmx3840M -XX:+AggressiveHeap -XX:+UseParallelGC -Datd.lang=$1 -classpath lib/\* sleep.console.TextConsole utils/bigrams/amigo.sl
