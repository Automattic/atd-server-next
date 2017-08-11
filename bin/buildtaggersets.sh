#
# code to generate the data used to bootstrap the tagger
#

mkdir tmp

java -Xmx1024M -jar lib/sleep.jar utils/tagger/makesentences.sl data/corpus_wikipedia tmp/wikipedia_sentences.txt
java -Xmx1024M -jar lib/sleep.jar utils/tagger/makesentences.sl data/corpus_gutenberg tmp/gutenberg_sentences.txt

#
# You *must* download the Stanford POS Tagger (GPL) from: http://nlp.stanford.edu/software/tagger.shtml
# and extract it into your AtD directory.
#
# This tagger will take 3 days to run / file
#                       ------

cd stanford-postagger-2008-09-28
java -Xmx1024M -XX:+AggressiveHeap -XX:+UseParallelGC -jar ../lib/sleep.jar ../utils/tagger/makebootstrap.sl models/bidirectional-wsj-0-18.tagger ../data/gutenberg_sentences.txt >../tmp/gutenberg_sentences_tagged.txt &
java -Xmx1024M -XX:+AggressiveHeap -XX:+UseParallelGC -jar ../lib/sleep.jar ../utils/tagger/makebootstrap.sl models/bidirectional-wsj-0-18.tagger ../data/wikipedia_sentences.txt >../tmp/wikipedia_sentences_tagged.txt &

#
# Or, optionally, you can use this Tagger which includes source but use is allowed for non-commercial research purposes only
#  
# http://www-tsujii.is.s.u-tokyo.ac.jp/~tsuruoka/postagger/
#
# This tagger will execute in 5 minutes / file
#                             ---------

# Oh, irony of ironies-- this tagger and the Stanford tagger produce nearly identical data (AtD bootstraps from the Stanford data though)

#
#cd postagger-1.0
#./tagger <../tmp/wikipedia_sentences.txt >../tmp/wikipedia_sentences_tagged.txt 
#./tagger <../tmp/gutenberg_sentences.txt >../tmp/gutenberg_sentences_tagged.txt 
#
cd ..

java -jar lib/sleep.jar utils/tagger/fixtags.sl tmp/wikipedia_sentences_tagged.txt >data/wikipedia_sentences_tagged_f.txt
java -jar lib/sleep.jar utils/tagger/fixtags.sl tmp/gutenberg_sentences_tagged.txt >data/gutenberg_sentences_tagged_f.txt

mv tmp/wikipedia_sentences.txt data/wikipedia_sentences.txt
mv tmp/gutenberg_sentences.txt data/gutenberg_sentences.txt

rm -rf tmp
