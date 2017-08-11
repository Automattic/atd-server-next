#
# transform the homophonesdb file into something our other scripts can handle
# using the bad\ngood format.

($inh, $outh) = @ARGV;

$handle = openf("models/dictionary.txt");
putAll(%dictionary, readAll($handle), { return 1; });
closef($handle);

$handle = openf($inh);
@data = readAll($handle);
closef($handle);

$handle = openf("> $+ $outh");
foreach $d (@data)
{
   @words = split(',\s*', $d);
   foreach $w1 (@words)
   {
      foreach $w2 (@words)
      {
         if ($w1 ne $w2 && $w1 in %dictionary && $w2 in %dictionary)
         {
            println($handle, "$w2");
            println($handle, "$w1");
         }
      }
   }
}
closef($handle);
