#!/bin/bash
# 
# Create a language model for low-memory AtD
#
rm -f models/model.zip
rm -rf tmp
mkdir tmp
java -Dfile.encoding=UTF-8 -Xmx3840M -XX:+AggressiveHeap -XX:+UseParallelGC -jar lib/sleep.jar utils/bigrams/buildsmallmodel.sl
cd tmp

# we're using this instead of zip because zip on some systems creates corrupt
# zip files when dealing with as many files as we have... get the JDK out.
jar -cf ../models/model.zip . 1>/dev/null
cd ..
