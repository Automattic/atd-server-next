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

$total = 0L;
foreach $word ($dictionary) {
	$total += count($word);
}

println($total);
