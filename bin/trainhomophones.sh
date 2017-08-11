#
# train and test the homophone misuse detection models

java -Datd.lowmem=true -Xmx3840M -XX:+AggressiveHeap -XX:+UseParallelGC -jar lib/sleep.jar utils/spell/trainspell.sl trainHomophoneModels
java -Datd.lowmem=true -Xmx3840M -XX:+AggressiveHeap -XX:+UseParallelGC -jar lib/sleep.jar utils/spell/test.sl runHomophoneTests
