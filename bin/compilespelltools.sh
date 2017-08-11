#
# Compiles the Sleep methods ported to Java contained in service/code
# 

cd service/code
ln -s ../../lib/ lib
ant clean
ant
mv spellutils.jar lib/spellutils.jar
rm -f lib
ant clean
