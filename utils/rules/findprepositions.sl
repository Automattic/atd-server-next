#
# a tool to inspect the language model
#

import org.dashnine.preditor.* from: lib/spellutils.jar;
use(^SpellingUtils);

# misc junk
include("lib/dictionary.sl");
global('$__SCRIPT__ $model $rules $dictionary $network $dsize %edits $hnetwork $account $usage $endings $lexdb $trigrams $verbs');
$model      = get_language_model();
$dictionary = dictionary();
$dsize      = size($dictionary);

global('@prepositions');
@prepositions = filter({ return iff(indexOf($1, ' ') is $null, $1); }, map({ return [$1 trim]; }, `cat data/rules/prepositions.txt`));

foreach $word (sort({ return count($2) <=> count($1); }, keys($dictionary)))
{
   if (count($word) < 100)
   {
      continue;
   }

   foreach $preposition (@prepositions)
   {
      # Pnext(preposition|word) 
      if (Pbigram1($word, $preposition) > 0.50)
      {
         println("$word $+ , $preposition : Pbigram1( $+ $word $+ , $preposition $+ ) = " . Pbigram1($word, $preposition));
      }
      # Pprev(preposition|word)
      else if (Pbigram2($preposition, $word) > 0.50)
      {
         println("$word $+ , $preposition : Pbigram2( $+ $preposition $+ , $word $+ ) = " . Pbigram2($preposition, $word));
      }
   }
}
