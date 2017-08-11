#
# compare a corpus text file to the current wordlists and see what needs to be added 
#

# to generate a wordlist suitable for the AtD wordlists directory:
#
# ./bin/corpus-lex-diff.sh filename.txt 50 wordlist 

java -Xmx3072M -jar lib/sleep.jar utils/bigrams/corpus-lex-diff.sl $1 $2 $3
