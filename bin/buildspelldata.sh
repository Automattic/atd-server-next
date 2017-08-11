java -Xmx2536M -XX:NewSize=512M -jar lib/sleep.jar utils/spelldata/gen2.sl data/corpus_gutenberg data/tests/sp_test_wpcm_nocontext.txt data/tests/sp_test_gutenberg_context1.txt
java -Xmx2536M -XX:NewSize=512M -jar lib/sleep.jar utils/spelldata/gen2.sl data/corpus_gutenberg data/tests/sp_test_aspell_nocontext.txt data/tests/sp_test_gutenberg_context2.txt

java -Xmx2536M -XX:NewSize=512M -jar lib/sleep.jar utils/spelldata/gen2.sl data/corpus_wikipedia data/tests/sp_test_wpcm_nocontext.txt data/tests/sp_test_wp_context1.txt
java -Xmx2536M -XX:NewSize=512M -jar lib/sleep.jar utils/spelldata/gen2.sl data/corpus_wikipedia data/tests/sp_test_aspell_nocontext.txt data/tests/sp_test_wp_context2.txt

#java -Xmx2536M -XX:NewSize=512M -jar lib/sleep.jar utils/spelldata/gen2.sl data/corpus_gutenberg data/tests/train.txt data/tests/sp_train_gutenberg_context.txt
#echo "are * blind|you, oyu" >>data/tests/sp_train_gutenberg_context.txt

