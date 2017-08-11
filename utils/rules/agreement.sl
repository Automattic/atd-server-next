#
# make a super rule file based on the chunker
#

sub fix {
	local('$s $c $t');
	$s = split('\s+', $1);
	foreach $c => $t ($s) {
		$t = "\\ $+ $c";
	}
	return join(" ", $s);
}

sub count {
	local('$s $c $t');
	$s = split('\s+', $1);
	return "\\" . (size($s) + $2);
}

sub noempties {
	return iff(strlen([$1 trim]) > 0, $1);
}

sub makeData {
	local('$a $b');
	($a, $b) = split('::', $1);
	if (strlen($b) > 0) { $b = ", $b " . count($a); }
	return @($a, fix($a), count($a, 0), $b, count($a, 1));
}

sub main {
	local('$handle @prefixes @rules $rule');
	$handle = openf($1);
	@prefixes = map(&makeData, filter(&noempties, readAll($handle)));
	closef($handle);

	$handle = openf($2);
	@rules = readAll($handle);
	closef($handle);

	foreach $rule (@rules) {
		printAll(map(lambda({ return '0BEGIN.0 ' . strrep($rule, '*prefix*', $1[0], '*text*', $1[1], '\\X', $1[2], '\\Y', $1[4], ', *transform*', $1[3]); }, \$rule), @prefixes));
	}

	printAll(map({ return '0BEGIN.0 ' . $1[0] . "::filter=kill"; }, @prefixes));
}

invoke(&main, sublist(@ARGV, 2));
invoke(&main, @ARGV);

