#
# convert the large language model to pieces that we can load as needed
#
debug(7 | 34);

import org.dashnine.preditor.* from: lib/spellutils.jar;
use(^SpellingUtils);

# misc junk
include("lib/dictionary.sl");
global('$__SCRIPT__ $model $rules $dictionary $network $dsize %edits $hnetwork $account $usage $endings $lexdb $trigrams $verbs');
$model      = get_language_model();

sub main {
        local('$handle $x $entry $wid $file');
	$handle = openf(">models/stringpool.bin");
	writeObject($handle, [$model getStringPool]);
	writeObject($handle, [$model count]);
	closef($handle);

	# make the necessary directories
	mkdir("tmp");
	for ($x = 0; $x < 512; $x++) {
		mkdir("tmp/ $+ $x");
	}
	
	# create each individual entry
	foreach $entry ([[[$model getStringPool] entrySet] iterator]) {
		$wid = [$entry getValue];
		$file = getFileProper("tmp", $wid % 512, $wid);
		$handle = openf("> $+ $file"); 
		writeAsObject($handle, [[$model getLanguageModel] get: $wid]);
		closef($handle);
	}
}

invoke(&main, @ARGV);
