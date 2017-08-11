#
# code to generate and evaluate the tagger models.
#

java -Xmx3072M -XX:+AggressiveHeap -XX:+UseParallelGC -jar lib/sleep.jar utils/tagger/postrain.sl wikipedia_sentences_tagged_f.txt
java -Xmx3072M -XX:+AggressiveHeap -XX:+UseParallelGC -jar lib/sleep.jar utils/tagger/postest.sl  data/gutenberg_sentences_tagged_f.txt
