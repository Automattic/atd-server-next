#
# this class looks at how often the trigram tagger guesses a word's correctness by the confused word
# used to generate the homobias class to
#

sub byword::init
{
   this('%data');

   %data = ohash();
   setMissPolicy(%data,
   {
      return newObject("score", "$2");
   });
}

sub byword::process
{
   local('$correct $wrong $wrongs $pre2 $pre1 $next @temp $nbase $tbase $solution $all %scores');
   ($correct, $wrong, $wrongs, $pre2, $pre1, $next) = @_;

   $all = tagAll($pre2[1], $pre1[1], $pre1[0], $wrongs);

   if (isDifferent($all))
   {
      $solution = getBest($all)[0];
      if ($solution eq $correct)
      {
         [%data[$solution] correct];
      }
      [%data[$solution] record];
   }
}

sub byword::finish
{
   map({ [$1 print]; }, sort(&sortScores, values(%data)));
}

sub byword::save
{
   local('$key $value $handle');
   foreach $key => $value (%data)
   {
      $value = [$value value];
   #   warn("$key -> $value");
   }

   $handle = openf(">models/bywords.bin");
   writeObject($handle, %data);
   closef($handle);
   println("Model saved");
}
