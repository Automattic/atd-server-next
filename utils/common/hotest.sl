sub hotest::init
{
   this('$score1 $score2 $score $criterf $network $criteria');

   $criterf  = criteria($2);
   $network  = get_network($1);
   $criteria = $2;

   $score1  = newObject("score", "Correct   $4");
   $score2  = newObject("score", "Wrong     $4");
   $score   = newObject("score", "Composite $4");
}

sub hotest::process
{
   local('$correct $wrong $wrongs $pre2 $pre1 $next $next2 @temp');
   ($correct, $wrong, $wrongs, $pre2, $pre1, $next, $next2) = @_;

   if (size($criteria) == 0)
   {
      @temp[0] = rand($wrongs);
   }
   else
   {
      @temp = checkAnyHomophone($network, $wrong, copy($wrongs), $pre1[0], $next[0], @($pre2[1], $pre1[1]), $pre2[0], $next2[0], $criteriaf => $criterf);
   #   println(join(', ', @($network, $wrong, copy($wrongs), $pre1[0], $next[0], @($pre2[1], $pre1[1]))) . ' = ' . @temp);
   }

   if (size(@temp) == 0)
   {
      @temp[0] = $wrong;
   }

   if (@temp[0] eq $correct)
   {
      [iff($wrong eq $correct, $score1, $score2) correct];
      [$score correct];
  #          warn("Correct!");
   }
   else
   {
       if ($wrong eq $correct)
       {
          [$score1 falsePositive];
          [$score falsePositive];
 #              warn("FP!");
        }
        else
        {
           [$score2 falseNegative];
           [$score falseNegative];
#           warn("FN!");
        }
   }

   [$score record];
   [iff($wrong eq $correct, $score1, $score2) record];
}

sub hotest::finish
{
   [$score1 print];
   [$score2 print];
   [$score print];
   println("-" x 30);
}

