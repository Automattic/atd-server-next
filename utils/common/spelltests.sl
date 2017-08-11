#
# this is a script to run unit tests and calculute the effectiveness of the 
# preditor engine
#

sub testSpellingNoContext
{
   local('$handle $score $bad $good');
   $handle = openf("tests/tests2.txt");

   $score = newObject("score", "Spellchecker w/ No Context");

   while $bad (readln($handle))
   {
      $good = readln($handle);
      if ($dictionary[$bad] !is $null)
      {
         local('$source $size');
         [$score falseNegative];
      }
      else
      {
         [$score correct];
      }

      if ($dictionary[$good] is $null)
      {
         [$score falsePositive];
      }

      [$score record];
   }

   [$score print];
}

sub testSoundEx
{
   local('$score $entry $bad $good');
   $score = newObject("score", "Test of SoundEx");
   while $entry (words("tests2.txt"))
   {
      ($bad, $good) = $entry;
      if (soundex($bad) eq soundex($good))
      {
         [$score correct];
      }
      else
      {
         warn("$[25]bad " . soundex($bad) . " $[25]good " . soundex($good));
      }

      [$score record];
   }

   [$score print];
}

sub testSoundExEditDistance
{
   local('%distance %totals $count $entry $bad $good $key $value $p $t');

   while $entry (words("tests2.txt"))
   {
      ($bad, $good) = $entry;
      if (soundex($bad) eq soundex($good))
      {
         %distance[editDistance($good, $bad)] += 1;
      }
 
      if (editDistance($good, $bad) == 0)
      {
         warn("$good -> $bad has an edit distance of 0?!?");
      }
      
      %totals[editDistance($good, $bad)] += 1;
      $count++;
   }

   foreach $key => $value (%distance)
   {
      $p = double($value) / $count;
      $t = double($value) / %totals[$key];

      println("$[5]key $[20]t $p"); 
   }
}

sub testCorrectionsNoContext
{
   local('$good $bad $entry $score @suggestions $f $c');

   $score = newObject("score", "Test of Corrections w/o Context");
   $c = 0;


   while $entry (words(@_[0]))
   {
      ($bad, $good) = $entry;

      if ($dictionary[$bad] is $null && $dictionary[$good] !is $null)
      {
         @suggestions = %edits[$bad]; # filterByDictionary($bad, $dictionary);

         if ($good in @suggestions)
         {
            foreach $f (sublist(@_, 1))
            {
               [$f : $bad, $good, copy(@suggestions), $null, $null];
            }
            [$score correct];
         }
         else
         {
       #     println("$bad -> $good : " . editDistance($bad, $good));
         }

         [$score record];
      }
      else
      {
         if ($dictionary[$bad] !is $null)
         {
            [$score falseNegative];
            $c++;
         }

         if ($dictionary[$good] is $null)
         {
            [$score falsePositive];
         }
      }
   }

   println("Present words: $c");
   [$score print];
}

sub RandomGuess
{
   [$score record];
   if (rand($3) eq $2)
   {
      [$score correct];
   }
}

sub FrequencyCount
{ 
   local('@suggs');

   [$score record];
   @suggs = sort({ return Pword($2) <=> Pword($1); }, $3);  
   if (@suggs[0] eq $2)
   {
      [$score correct];
   }
}

sub scoreIt
{
   return (         ( 0.75 / (  editDistance($word, $1) + 1  ) )         ) + 
          (  0.25 *  Pword($1) ) ;
}
sub scoreIt2
{
   return (         ( 0.75 / (  editDistance($word, $1) + 1  ) )         ) + 
          (  0.25 * Pword($1)  ) ;
}

sub CombineFreqEdit
{
   local('@suggs');

   let(&scoreIt, $word => $1);
   let(&scoreIt2, $word => $1);

   [$score record];
   @suggs = sort({ return scoreIt2($2) <=> scoreIt2($1); }, $3);  

   if (@suggs[0] eq $2)
   {
      [$score correct];
   }
}

sub NeuralNetworkScore
{
   local('@suggs $4 $5 $cs');

   [$score record];
   @suggs = sortHash($3, CompareSuggestions($network, $criteriaf, $1, $pool => $3, $pre => $4, $next => $5));

   if (@suggs[0] eq $2)
   {
      [$score correct];
   }
}
