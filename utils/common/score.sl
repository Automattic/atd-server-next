#
# code for the score object
#

sub sortScores
{
   return [$1 value] <=> [$2 value];
}

sub score::init
{
   this('$desc $count $fneg $fpos $correct $sugg');
   ($desc) = @_;
}

sub score::record
{
   $count++;
}

sub score::falseNegative
{
   $fneg++;
}

sub score::falsePositive
{
   $fpos++;
}

sub score::correct
{
   $correct++;
}

sub score::correctSugg
{
   $sugg++;
}

sub score::value
{
   return (double($correct) / $count);
}

sub score::print
{
   println("Report for $desc");
   println("Correct:        " . ((double($correct) / $count) * 100.0));

   if ($sugg != 0)
   {
   println("Suggestion Acc: " . ((double($sugg) / $count) * 100.0));
   println("-" x 20);
   }
   if ($fneg != 0)
   {
   println("False Negative: " . ((double($fneg) / $count) * 100.0));
   }
   if ($fpos != 0)
   {
   println("False Positive: " . ((double($fpos) / $count) * 100.0));
   }
}


