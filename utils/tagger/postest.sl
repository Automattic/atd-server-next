#
# test the tagger
#

debug(debug() | 7 | 34);

include("lib/tagger.sl");
initTaggerModels();

sub both
{
   local('$a $b');
   ($a, $b) = @_;
   while (size($a) > 0 && size($b) > 0)
   {
      yield @($a[0], $b[0]);
      $a = sublist($a, 1);
      $b = sublist($b, 1);
   }
}

sub tests
{
   local('$lexicon $handle $count $score $line $item $word $tag $f $compare $taggit $opt $count $word $tag');

   $handle = openf(@ARGV[0]);
   while $line (readln($handle))
   {
      $compare = map({ return split('/', $1)[0]; }, split(' ', $line));

      foreach $f (@_)
      {
         $taggit  = taggerToString([$f tag: $compare]);

         while $opt (both(split(' ', $line), split(' ', $taggit)))
         {
            ($word, $tag) = split('/', $opt[0]);

            if ($word in $lexdb)
            {
               if ($opt[0] eq $opt[1])
               {
                  [$f scoreK];
               }
               [$f countK];
            }
            else
            {
               if ($opt[0] eq $opt[1])
               {
                  [$f scoreU];
               }
               [$f countU];
            }
         }
      }        

      $count++;
#      if (($count % 2500) == 0 && $count > 0)
#      {
#          foreach $f (@_)
#          {
#             [$f print];
#          }
#          println("$[-20]count");
#      }
   }

   foreach $f (@_)
   {
      [$f print];
   }
}

sub test
{
   return lambda(
   {
      if ($0 eq "tag")
      {
         return invoke($function, @_);
      }
      else if ($0 eq "scoreK")
      {
         $scoreK += 1;
      }
      else if ($0 eq "countK")
      {
         $countK += 1;
      }
      else if ($0 eq "scoreU")
      {
         $scoreU += 1;
      }
      else if ($0 eq "countU")
      {
         $countU += 1;
      }
      else if ($0 eq "print")
      {
         println("test: $description = known: " . ($scoreK / $countK) . " unknown: " . ($scoreU / $countU) . " composite: " . (($scoreK + $scoreU) / ($countK + $countU)));
      }
   }, $function => $2, $description => $1, $scoreK => 0.0, $countK => 0.0, $scoreU => 0.0, $countU => 0.0);
}

tests(
#  test("pytagger", &taggerPython),
#  test("brill-light", &taggerLikeBrill),
  test("trigrams", &taggerWithTrigrams),
  test("lexprob", &taggerWithLexProb),
#   test("trigrams w/ neural", &taggerWithNeuralTrigrams),
#  test("trigrams w/ fix", &taggerWithTrigramsFix),
#  test("trigrams - no fixes", &taggerWithTrigrams2),
#  test("random", &taggerRandom)
#   test("HMM", &taggerHMM)
);
