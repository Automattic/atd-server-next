# generate the source data
rm -rf tmp
mkdir tmp
java -jar lib/sleep.jar utils/spelldata/makesrc.sl data/rules/homophonedb.txt tmp/homophones.txt

#
# build with parts-of-speech
#
java -jar lib/sleep.jar utils/spelldata/gen4.sl tmp/homophones.txt data/wikipedia_sentences.txt data/tests/ho_test_wp_pos_context.txt 15
java -jar lib/sleep.jar utils/spelldata/gen4.sl tmp/homophones.txt data/gutenberg_sentences.txt data/tests/ho_test_gutenberg_pos_context.txt 15

# was 8
java -jar lib/sleep.jar utils/spelldata/gen4.sl tmp/homophones.txt data/gutenberg_sentences.txt data/tests/ho_train_gutenberg_pos_context.txt 6

#
# build without parts-of-speech
#
java -Xmx2536M -XX:NewSize=512M -jar lib/sleep.jar utils/spelldata/gen3.sl data/corpus_gutenberg tmp/homophones.txt data/tests/ho_test_gutenberg_context.txt
java -Xmx2536M -XX:NewSize=512M -jar lib/sleep.jar utils/spelldata/gen2.sl data/corpus_gutenberg tmp/homophones.txt data/tests/ho_train_gutenberg_context.txt
java -Xmx2536M -XX:NewSize=512M -jar lib/sleep.jar utils/spelldata/gen3.sl data/corpus_wikipedia tmp/homophones.txt data/tests/ho_test_wp_context.txt
rm -rf tmp
