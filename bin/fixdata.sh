#
# do this once!
#

cd data
tar zxf corpora.tgz
cd ..
java -Xmx1024M -jar lib/sleep.jar utils/bigrams/fixgutenberg.sl data/corpus_gutenberg
