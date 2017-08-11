#
# convert a WordPress WXR file to raw data suitable for use in the AtD corpus
#

java -Xmx3584M -jar lib/sleep.jar utils/bigrams/corpuswp.sl $1
