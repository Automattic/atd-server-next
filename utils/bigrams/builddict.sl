# 
# This is a script to generate a spellchecker dictionary using the specified threshold.  It's fun stuff.
#
# java -jar sleep.jar builddict.sl threshold models/model.bin models/dictionary.txt
#

debug(7 | 34);

import org.dashnine.preditor.* from: lib/spellutils.jar;
use(^SpellingUtils);

include("lib/dictionary.sl");

sub main
{
   global('$model $threshold $handle $index $1 $2');
   $model   = get_language_model($2);

   $handle = openf(iff($2 is $null, ">models/dictionary.txt", "> $+ $3"));

   printAll($handle, [SleepUtils getArrayWrapper: [$model harvest: int($1)]]);

   closef($handle);
}

invoke(&main, @ARGV);
