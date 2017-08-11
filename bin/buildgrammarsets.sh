#
# build grammar corpora
#

if [ -f wp.txt ]
then

  java -jar lib/sleep.jar utils/spelldata/torules.sl wrong >rules.out

  # make the grammar rules files

  java -jar lib/sleep.jar utils/spelldata/maker.sl rules.out data/wikipedia_sentences.txt >data/tests/grammar_wikipedia.txt
  java -jar lib/sleep.jar utils/spelldata/maker.sl rules.out data/gutenberg_sentences.txt >data/tests/grammar_gutenberg.txt

  rm -f rules.out

else
  echo "No wp.txt file is present, cut and paste Wikipedia Common Errors List to wp.txt and try again"

fi
