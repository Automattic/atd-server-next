sub exp::init
{
   this('$score1 $score2 $score $criterf $network $criteria %dpoints $tscores $nscores $oscores $criterf2 $network2 $criteria2');

   $criterf  = criteria($2);
   $network  = get_network($1);
   $criteria = $2;

   $nscores = newObject("score", "network  total");
   $tscores = newObject("score", "trigrams total");
   $oscores = newObject("score", "best score");
}

sub exp::process
{
   local('$correct $wrong $wrongs $pre2 $pre1 $next @temp $nbase $tbase $solution $all %scores');
   ($correct, $wrong, $wrongs, $pre2, $pre1, $next) = @_;

   # do a trigram check?
   if ($wrong eq $correct)
   {
      $all = tagAll($pre2[1], $pre1[1], $pre1[0], $wrongs);

      if (isDifferent($all))
      {
         $solution = getBest($all)[0];
         if ($solution eq $correct)
         {
            [$tscores correct];
         }
         else
         {
            if ($bywords[$solution] == 1.0)
            {
  #             warn("$solution is wrong, correct is $correct : " . $bywords[$correct]);
            }
         }
         [$tscores record];
      }
   }

   if ($wrong eq $correct)
   {
      (@temp, %scores) = checkAnyHomophone2($network, $wrong, copy($wrongs), $pre1[0], $next[0], @($pre2[1], $pre1[1]), 
             $criteriaf => $criterf);

      if (size(@temp) == 0)
      {
          @temp[0] = $wrong;
      }

      if ($bywords[$solution] >= 1.0)  #&& $solution eq $correct)
      {
          @temp[0] = $solution;
      }

      if (@temp[0] eq $correct)
      {
         [$nscores correct];
      }
      [$nscores record];

      if (@temp[0] eq $correct || $solution eq $correct)
      {
         [$oscores correct];
      }
      [$oscores record];

      if ($solution ne $correct && $bywords[$solution] == 1.0)
      {
#          warn("$solution - " . $bywords[$solution] . " vs. $correct " . $bywords[$correct]);
      }
   }
}

sub exp::finish
{
   [$nscores print];
   [$tscores print];
   [$oscores print];
}
