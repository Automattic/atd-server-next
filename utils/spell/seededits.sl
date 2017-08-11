#
# this is a script to run unit tests and calculute the effectiveness of the 
# preditor engine
#

debug(debug() | 7 | 34);

map({ iff('*.sl' iswm $1, include($1)); }, ls("utils/common"));

include("lib/engine.sl");
include("lib/object.sl");

global('$dictionary $model $dsize $trie');
$model      = get_language_model();
$dictionary = dictionary();
$trie       = trie($dictionary);
$dsize      = size($dictionary);

sub seedFile
{
   local('$score $good $bad $word');
   
   $score = newObject("score", "Word pool accuracy: $1");

   while $word (words($1))
   {  
      ($bad, $good) = $word;

      if ($bad !in %edits)
      {
         %edits[$bad] = editst($dictionary, $trie, $bad); # filterByDictionary($bad, $dictionary);
      }

      if ($good in %edits[$bad])
      {
         [$score correct];
      }
      else
      {
#         println("$bad -> $good ".editDistance($bad, $good)."  is not in " . %edits[$bad]);
      }
      [$score record];
   }

   [$score print];
}

global('%edits $handle');
%edits = ohasha();

map(&seedFile, @ARGV);

$handle = openf(">models/edits.bin");
writeObject($handle, %edits);
closef($handle);

println("Edits flushed!");
