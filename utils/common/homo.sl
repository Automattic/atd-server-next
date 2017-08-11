#
# test out spelling with associated context information
#

sub suggestTest
{
   local('$suspect $dict $previous $next @suggestions $f');
   ($suspect, $dict, $previous, $next) = @_;

   @suggestions = %edits[$suspect];

   if ($correct in @suggestions)
   {
      foreach $f (@functions)
      {
         [$f : $suspect, $correct, copy(@suggestions), $previous, $next];
      }
    #  warn("Done for $previous $suspect $next -> $correct");
   }

   return @();
}

sub testCorrectionsContext
{
   local('$score $entry $sentence $correct $wrongs @results @words $rule $wrong $previous $next $func');

   while $entry (sentences($1))
   {
      ($sentence, $correct, $wrongs) = $entry;
      ($previous, $next) = split(' \\* ', $sentence);
      $func = lambda(&suggestTest, \$score, \$correct, @functions => sublist(@_, 1));

      #
      # check for a false negative
      #
      foreach $wrong ($wrongs)
      {
         [$func: $wrong, $dictionary, $previous, $next]
      } 
   }
}

sub loopHomophonesPOS
{
   local('$entry $sentence $correct $wrongs $pre2 $pre1 $next $object $wrong $next2'); 

   while $entry (sentences($1))
   {
      ($sentence, $correct, $wrongs) = $entry;
      ($pre2, $pre1, $null, $next, $next2) = toTaggerForm(split(' ', $sentence));

      if ($pre2[1] eq "UNK") { $pre2[1] = ""; }
      if ($pre1[1] eq "UNK") { $pre1[1] = ""; }

      $correct = split('/', $correct)[0];

      push($wrongs, $correct);

      foreach $wrong ($wrongs)
      {
         [$2 process: $correct, $wrong, $wrongs, $pre2, $pre1, $next, $next2];
      }

#      [$2 process: $correct, $correct, $wrongs, $pre2, $pre1, $next];
   }

   [$2 finish];
}
