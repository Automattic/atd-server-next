#
# train and test the spellchecker models
#

java -Datd.lowmem=true -Xmx3536M -XX:+AggressiveHeap -XX:+UseParallelGC -jar lib/sleep.jar utils/spell/trainspell.sl trainNoContext

echo "=== NON-CONTEXTUAL DATA ======================================================================="

java -Datd.lowmem=true -Xmx3536M -XX:+AggressiveHeap -XX:+UseParallelGC -jar lib/sleep.jar utils/spell/test.sl runSpellingTest sp_test_aspell_nocontext.txt
java -Datd.lowmem=true -Xmx3536M -XX:+AggressiveHeap -XX:+UseParallelGC -jar lib/sleep.jar utils/spell/test.sl runSpellingTest sp_test_wpcm_nocontext.txt

# normal spelling test
#java -Xmx1024M -jar lib/sleep.jar utils/spell/test.sl runSpellingTest tests1.txt
#java -Xmx1024M -jar lib/sleep.jar utils/spell/test.sl runSpellingTest tests2.txt
