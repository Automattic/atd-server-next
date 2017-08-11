#
# calculate quality score for a dataset
#

sub loadCommonWords
{
   this('$common');
   if ($common is $null)
   {
      $common = %();  
      local('$handle $bad $good $foo');

      #  function to load file data and add it to our hash
      $foo = lambda(
      {
         local('$handle $bad');
         $handle = openf($1);
         while $bad (readln($handle))
         {
            if ($bad !in $dictionary)
            {
               $common[$bad] = 1;
            }
         }
         closef($handle);
      }, \$common);

      [$foo : 'data/tests/tests1.txt'];
      [$foo : 'data/tests/tests2.txt'];
   }

   return $common;
}

sub generateStatistics
{
   local('$error $rule');

   foreach $error ($1)
   {
      $rule = $error[0];
      $2[$rule['rule']] += 1;
   }
}

sub processDocumentQuality
{
   local('@paragraphs $paragraph $sentence @results @words $count $word %common $suggest %stats');

   %common     = loadCommonWords();
   @paragraphs = splitByParagraph($1);

   $suggest    = function('&suggest');
   setf('&suggest', { return @(); });

   foreach $count => $paragraph (@paragraphs)
   {
      foreach $sentence ($paragraph)
      {
         if ($sentence eq "")
         {
            continue;
         }

         @words = splitIntoWords($sentence);
         %stats['words'] += size(@words);
         %stats['sentences'] += 1;

         foreach $word (@words) { if ($word in %common) { %stats['miss'] += 1; } }

         processSentence(\$sentence, \@results);
      }

      generateStatistics(@results, %stats);
      @results = @();
   }

   setf('&suggest', $suggest);
   return %stats;
}

