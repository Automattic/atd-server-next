$handle = openf(@ARGV[0]);
while $text (readln($handle))
{
   ($first, $second, $type) = matches($text, '(\w+), (\w+) : (\w+)\\(.*');
   if ($type eq 'Pbigram1' && $first ne "wont" && $first ne "continue" && '*ed' !iswm $first && $first ne "attempts")
   {
      if ($second eq "to")
      {
          if ($first eq "decided")
          {
             println(".*/DT $first stir::filter=kill");
          }
          else if ($first eq "attempt")
          {
             println(".*/DT $first be::filter=kill");
          }
          else if ($first eq "reference")
          {
             println(".*/DT $first have::filter=kill");
          }
          else if ($first eq "wanted" || $first eq "wants" || $first eq "want")
          {
             println(".*/PRP $first help::filter=kill");
             println(".*/NNP $first help::filter=kill");
          }

         if (-islower charAt($first, 0))
         {
            println(".*/PRP $first .*/VB::word=\\0 \\1 $second \\2::pivots= $+ $first $+ , $+ $first $second");
            println(".*/NNP $first .*/VB::word=\\0 \\1 $second \\2::pivots= $+ $first $+ , $+ $first $second");
            println(".*/DT $first .*/VB::word=\\0 \\1 $second \\2::pivots= $+ $first $+ , $+ $first $second");
         }
         else
         {
            println("0BEGIN.0 $first .*/VB::word=\\0 $second \\1::pivots= $+ $first $+ , $+ $first $second");
            println("0BEGIN.0 $first .*/VB::word=\\0 $second \\1::pivots= $+ $first $+ , $+ $first $second");
            println("0BEGIN.0 $first .*/VB::word=\\0 $second \\1::pivots= $+ $first $+ , $+ $first $second");
         }
      }
      else if ($second eq "of")
      {
         if ($first eq "couple")
         {
            println(".*/DT $first .*/NN|NNS::word=\\0 \\1 $second \\2::pivots= $+ $first $+ , $+ $first $second");
         }
         else if ($first eq "beware")
         {
            println(".*/DT $first .*/DT .*/NN|NNS::word=\\0 \\1 $second \\2 \\3::pivots= $+ $first $+ , $+ $first $second");
            println(".*/DT $first .*/NN|NNS::word=\\0 \\1 $second \\2::pivots= $+ $first $+ , $+ $first $second");
         }
      }
      else if ($second eq "on" || $second eq "with" || $second eq "in")
      {
#         println("$first .*/DT .*/NN|NNS::word=\\0 $second \\1 \\2::pivots= $+ $first $+ , $+ $first $second");
#         println("$first .*/NN|NNS::word=\\0 $second \\1::pivots= $+ $first $+ , $+ $first $second");
      }
      else if ($second ne "of" && $second ne "to")
      {
#         println("$first $second $+ ::filter=none");
      }
   }
   else if ($type eq 'Pbigram2')
   {
#      println(".*/DT .*/NN $first $+ ::word=\\0 \\1 $second \\2::pivots= $+ $first $+ , $+ $second $first");
#      println(".*/VB $first $+ ::word=\\0 $second \\1::pivots=\\1, $+ $second \\1");
#      println(".*/VBD $first $+ ::word=\\0 $second \\1::pivots=\\1, $+ $second \\1");
#      println(".*/VBD .*/PRP $first $+ ::word=\\0 \\1 $second \\2::pivots= $+ $first $+ , $+ $second $first");
   }
}

