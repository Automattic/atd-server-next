$handle = openf("spelling.txt");

global('%dataset');

while $bad (readln($handle))
{
   $good = readln($handle);
   %dataset[$bad] = $good;
}

closef($handle);


$handle = openf("batch0.tab");
while $text (readln($handle))
{
   ($bad, $good) = split('\s+', $text);
   %dataset[$bad] = $good;
}

closef($handle);

$handle = openf("batch0.tab.1");
while $text (readln($handle))
{
   ($bad, $good) = split('\s+', $text);
   %dataset[$bad] = $good;
}

closef($handle);

$handle = openf(">output.txt");
$handle2 = openf(">output2.txt");

@bads = sorta(keys(%dataset));
foreach $bword (@bads)
{
   println($handle, $bword);
   println($handle2, $bword);
   println($handle, %dataset[$bword]);
}

closef($handle);
closef($handle2);
