#
# test spanish homophones against spanish corpora.
#

debug(7 | 24);

include("lib/quality.sl");
include("lib/engine.sl");

#
# load AtD models
#
global('$lang');

$lang = systemProperties()["atd.lang"];
if ($lang ne "" && -exists "lang/ $+ $lang $+ /load.sl") {
	include("lang/ $+ $lang $+ /load.sl");
	initAllModels();
}

#
# load homophones
#
sub homophones {
	local('$handle $text %h @candidates');
	$handle = openf("lang/ $+ $lang $+ /homophonedb.txt");
	while $text (readln($handle)) {
		if ('-*' iswm $text) {
			%h[substr($text, 1)] = $null;
		}
		else {
			@candidates = split(',\s+', $text);
			map(lambda({ %h[$1] = @candidates; }, \%h, \@candidates), @candidates);
		}
	}
	return %h;
}

sub isHomophone {
	local('$sentence $pre2 $pre1 $current $next @results');
	($sentence, $pre2, $pre1, $current, $next) = @_;

	@results = checkHomophone($hnetwork, $current, %homophones[$current], $pre1, $next, @(), $pre2, $bias1 => 30.0, $bias2 => 10.0);

	if (size(@results) > 0) {
		println("\t $+ $sentence");
		println("\t $+ $pre2 $pre1 | $current | $next or: " . @results . "\n");
	}
}

#
# check a sentence for homophones
#
sub checkSentenceForHomophones {
	local('$pre2 $pre1 $current $next $word');

	$current = '0BEGIN.0';
	
	foreach $next (splitIntoWords($1)) {
		if ($current ne '0BEGIN.0' && $current in %homophones) {
			isHomophone($1, $pre2, $pre1, $current, $next);
		}
		$pre2 = $pre1;
		$pre1 = $current;
		$current = $next;
	}

	$next = '0END.0';

	if ($current in %homophones) {
		isHomophone($1, $pre2, $pre1, $current, $next);
	}
}

#
# loop through the file, look for homophones... report them!
#
sub checkForHomophones {
	local('$handle $contents');
	$handle = openf($1);
	$contents = splitIntoSentences(join("\n", readAll($handle, -1)));
	map(&checkSentenceForHomophones, $contents);
	closef($handle);
}

sub main {
	global('%homophones');
	%homophones = homophones();
	[{
		if (-isDir $1) {
			map($this, ls($1));
		}
		else {
			if ('*.txt' iswm $1) {
				println($1);
				checkForHomophones($1);
			}
		}
	}: "lang/ $+ $lang $+ /corpus"];
}

invoke(&main, @ARGV);
