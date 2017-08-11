#
# seed the edits model
# This model is nothing more than a cache of potential edits for common word mispellings.  The purpose is to speed up processing.  AtD uses an LRU cache
# when running to track and grow this information.  The seeding is done because the edits operation is so expensive that have this information available
# makes training, testing, and warm up time significantly faster.
#
java  -Xmx3840M -XX:+AggressiveHeap -XX:+UseParallelGC -jar lib/sleep.jar utils/spell/seededits.sl sp_test_aspell_nocontext.txt sp_test_wpcm_nocontext.txt
