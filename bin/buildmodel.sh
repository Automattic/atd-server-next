#
# This script creates the AtD bigram model (corpus.zip)
#

java -version

rm -f models/model.bin

java -Dfile.encoding=UTF-8 -Xmx6840M -XX:+AggressiveHeap -XX:+UseParallelGC -jar lib/sleep.jar utils/bigrams/buildcorpus.sl data/corpus_gutenberg
java -Dfile.encoding=UTF-8 -Xmx6840M -XX:+AggressiveHeap -XX:+UseParallelGC -jar lib/sleep.jar utils/bigrams/buildcorpus.sl data/corpus_wikipedia
java -Dfile.encoding=UTF-8 -Xmx6840M -XX:+AggressiveHeap -XX:+UseParallelGC -jar lib/sleep.jar utils/bigrams/buildcorpus.sl data/corpus_extra

# build dictionary (make sure it's done *after* zipping)

java -Dfile.encoding=UTF-8 -Xmx6840M -XX:NewSize=512M -jar lib/sleep.jar utils/bigrams/builddict.sl 2

# create the not misspelled dictionary...

cp data/wordlists/accented.txt models/not_misspelled.txt

# create LM for low-memory AtD
./bin/smallmodel.sh
