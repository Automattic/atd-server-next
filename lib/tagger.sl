#
# lexical database and tagger.  *pHEAR*
#

sub loadModelObject
{
   local('$handle $d @r');
   $handle = openf("models/ $+ $1");
   while $d (readObject($handle))
   {
      push(@r, $d);
   }
   closef($handle);

   return iff(size(@r) == 1, @r[0], @r);
}

# @(@(word, tag, score), ...)
sub isDifferent
{
   local('$word $tag $score $option $_score $_tag %counts');

   foreach $option ($1)
   {
      ($word, $tag, $score) = $option;
      %counts[$tag] += 1; # iff($score > 0.0, 1, 0);

      if (%counts[$tag] > 1)
      {
          return $null;
      }
   }
   return 1;
}

# tagAll(pre1, pre2, prevword, @(word1, word2, ...))
sub tagAll
{
   local('$option $result $score @r');
#   warn(@_);

   foreach $option ($4)
   {
      $result = tagSingle($1, $2, $3, $option);
      $score  = scoreTagSequence($1, $2, $result);
  #    $score  += scoreTagAssociation($option, $result);
  #    $score /= 2;
      push(@r, @($option, $result, $score));
   }

   return @r;
}

sub getBest
{
   local('$x');
   $x = iff(size($1) > 1, 
               reduce({ 
                   return iff($1[2] > $2[2], $1, $2); 
               }, 
               $1), $1[-1]);

#   warn("Best for $1 is: $x");
   return $x;
}

sub initTaggerModels
{
   global('$endings $lexdb $trigrams $trigramsr $bywords');
   $endings   = loadModelObject("endings.bin");
   $lexdb     = loadModelObject("lexicon.bin");
   ($trigrams, $trigramsr) = loadModelObject("trigrams.bin");
#   $bywords   = loadModelObject("bywords.bin");
}

sub scoreTags
{
   local('$pre2 $pre1 $tag $base');
   ($pre2, $pre1, $tag) = @_;

   if ($pre2 in $trigrams && $pre1 in $trigrams[$pre2])
   {
      $base = $trigrams[$pre2][$pre1];
      return iff ($tag in $base, $base[$tag], 0.0);
   }
   else
   {
      return 0.0;
   }
}

sub endsWith
{
   return iff(strlen($1) >= strlen($2) && right($1, strlen($2)) eq $2);
}

sub beginsWith
{
   return iff(strlen($1) >= strlen($2) && left($1, strlen($2)) eq $2);
}

sub past
{
   # a regex to check if a word is a past participle or not.
   return '\w+ed|awoken|borne|beaten|become|begun|bent|bet|bitten|bled|blown|broken|bred|brought|built|burnt|burst|bought|caught|chosen|come|cost|cut|dealt|done|drawn|dreamt|drunk|driven|eaten|made|meant|met|paid|put|quit|read|ridden|rung|risen|run|said|seen|sought|sold|sent|set|shaken|shone|shot|shown|shut|sung|sunk|sat|slept|smelt|spoken|spent|spilt|spoilt|spread|stood|stolen|stuck|stung|stunk|struck|sworn|swum|taken|taught|torn|told|thought|thrown|understood|woken|worn|wept|won|written';
}

sub fixSingleTag
{
   local('$word $tag $pre1 $tag1');
   ($word, $tag, $pre1, $tag1) = @_;   

   # rule 1 : DT, {VBD | VBP} --> DT, NN
   if ($tag1 eq "DT" && ($tag eq "VBD" || $tag eq "VBP" || $tag eq "VB"))
   {
      return "NN";
   }

   # rule 2: convert a noun to a number (CD) if "." appears in the word
   else if ([$tag startsWith: "N"] && -isnumber $word)
   {
      return "CD";
   }

   # rule 3: convert a noun to a past participle if 
   else if ([$tag startsWith: "N"] && [$word endsWith: "ed"])
   {
      return "VBN";
   }

   # rule 4: convert any type to adverb if it ends in "ly"
   else if ([$word endsWith: "ly"])
   {
      return "RB";
   }

   # rule 5: convert a common noun (NN or NNS) to a adjective if it ends with "al"
   else if ([$tag startsWith: "NN"] && [$word endsWith: "al"])
   {
      return "JJ";
   }

   # rule 6: convert a noun to a verb if the preceeding work is "would"
   else if ([$tag startsWith: "NN"] && (lc($pre1) eq "would")) # || $tag1 eq "TO"))
   {
      return "VB";
   }

   # rule 7: if a word has been categorized as a common noun and it ends with "s",
   # then set its type to plural common noun (NNS)
   else if ($tag eq "NN" && [$word endsWith: "s"])
   {
      return "NNS";
   }

   # rule 8: convert a common noun to a present prticiple verb (i.e., a gerand)
   else if ([$tag startsWith: "NN"] && [$word endsWith: "ing"])
   {
      return "VBG";
   }

   # rule 9: give punctuation its own tag.
   else if ($word isin "-,()[];:/--")
   {
      return ",";
   }

   return $tag;
}

sub findWordTag
{
   local('$base $wordtags $rtag $key $value $temp $result');
   ($base, $wordtags) = @_;

   $rtag = -1.0;
   $result = $null;

   foreach $key => $value ($wordtags)
   {
      $temp = iff($key in $base, $base[$key], 0.00000000000000001) * $value;
      if ($temp > $rtag && $key ne "")
      {
         $rtag  = $temp;
         $result = "$key";
      }
   }

   if ($result is $null)
   {
      warn("Null: " . @_);
      return 'NN';
   }

   return $result;
}

sub taggerWithLexProb
{
   local('@results $word $pre2 $pre1 $count $wordl');

   foreach $count => $word ($1)
   {
      $wordl = lc($word);

      local('%base');
      %base = ohash();
      setMissPolicy(%base, { return 1.0; });
 
      if ($wordl !in $lexdb)
      {
         if (-isupper charAt($word, 0) && $pre1 eq "")
         {
            push(@results, @($word, "NN"));
         }
         else if (strlen($word) >= 3 && right($wordl, 3) in $endings)
         {
            push(@results, @($word, findWordTag(%base, $endings[right($wordl, 3)]) ));
         }
         else
         {
            push(@results, @($word, "NN"));
         }

#         @results[-1][1] = fixSingleTag($word, @results[-1][1], iff($pre1 eq "", "", @results[-2][0]), $pre1); 
      }
      else if (size($lexdb[$wordl]) >= 1)
      {
         push(@results, @($word, findWordTag(%base, $lexdb[$wordl])));
      }
      else
      {
         push(@results, @($word, "NN"));
 #        @results[-1][1] = fixSingleTag($word, @results[-1][1], iff($pre1 eq "", "", @results[-2][0]), $pre1); 
      }
   }
 
   return @results;
}

sub scoreWordTagFit
{
   warn("scoreWordTagFit: " . @_);
   warn("scoreTagSequence( $+ $1 $+ , $2 $+ , $3 $+ ) = [".scoreTagSequence($1, $2, $3)."] * scoreTagAssociation( $+ $3 $+ , $4 $+ ) = [".scoreTagAssociation($3, $4)."]");
   return scoreTagSequence($1, $2, $3) * scoreTagAssociation($3, $4);
}

sub scoreTagSequence
{
   local('$pre2 $pre1 $tag $base');
   ($pre2, $pre1, $tag) = @_;

   if ($pre2 in $trigrams && $pre1 in $trigrams[$pre2])
   {
      $base = $trigrams[$pre2][$pre1];
      if ($tag in $base)
      {
         return $base[$tag];
      }
   }
   return 0.0;
}

sub scoreTagAssociation
{
   local('$word $tag $wordl $end');
   ($word, $tag) = @_;
   $wordl = lc($word);

   if ($wordl !in $lexdb)
   {
      $end = iff(strlen($wordl) > 3, right($wordl, 3), $wordl);
      if ($end in $endings && $tag in $endings[$end])
      {
         return $endings[$end][$tag];
      }
   }
   else if ($tag in $lexdb[$wordl])
   {
      return $lexdb[$wordl][$tag];
   }

   #warn("Assoc: $word -> $tag has nothing!");
   return 0.0;
}

# pre2, pre1, last, word
sub tagSingle
{
   local('$pre2 $pre1 $word %base $last $wordl $result');
   ($pre2, $pre1, $last, $word) = @_;

   $wordl = lc($word);

   if ($pre2 !in $trigrams || $pre1 !in $trigrams[$pre2])
   {
      %base = ohash();
      setMissPolicy(%base, { return 1.0; });
   }
   else
   {
      %base = $trigrams[$pre2][$pre1];
   }

   if ($wordl !in $lexdb)
   {
      if (-isupper charAt($word, 0) && $pre1 eq "")
      {
         $result = 'NN';
      }
      else if (strlen($word) >= 3 && right($wordl, 3) in $endings)
      {
         $result = findWordTag(%base, $endings[right($wordl, 3)]);
      }
      else
      {
         $result = 'NN';
      }

      $result = fixSingleTag($word, $result, $last, $pre1);
   }
   else if (size($lexdb[$wordl]) >= 1)
   {
      $result = findWordTag(%base, $lexdb[$wordl]);
   }
   else
   {
      $result = fixSingleTag($word, 'NN', $last, $pre1);
   }

   return $result;
}

# use trigrams to predict appropriate current word and brill strategy for unknown words
sub taggerWithTrigrams
{
   local('@results $word $pre2 $pre1 $count $wordl');

   ($pre2, $pre1) = "";

   foreach $count => $word ($1)
   {
      if (strlen($word) == 0)
      {
          warn("Broken: ' $+ $word $+ ' @ $count of $1");
      }

      push(@results, @($word, tagSingle($pre2, $pre1, iff($pre1 eq "", "", @results[-1][0]), $word)));

      assert @results[-1][1] ne "" : "Eh?!? " . sublist(@_, 1) . " $word and " . @results;

      $pre2 = $pre1;
      $pre1 = @results[-1][1];
   }
 
   return @results;
}

sub taggerToString
{
   return join(" ", map({ return join("/", $1); }, $1));
}

