import org.dashnine.preditor.SpellingUtils from: lib/spellutils.jar;
import org.dashnine.preditor.SortFromHash from: lib/spellutils.jar;
use(^SpellingUtils);
use(^SortFromHash);

include("lib/dictionary.sl");
include("lib/neural.sl");

sub getSuggestionPool
{
   local('@s $compare');
   @s = %edits[ $1 ]; 
   $compare = CompareSuggestions($network, &spellcheckerFeatures, $1, $pool => @s, $pre => $3, $next => $4);
   @s = sortHash(@s, $compare);
   return @(@s, $compare);
}

# suggest("bad", "dictionary to use")
sub suggest
{
   local('@s %scores');

   (@s, %scores) = getSuggestionPool($1, $2, $3, $4);

   if (size(@s) > 5)
   {
      local('$top $key $value');
      $top = %scores[@s[0]] * 0.75;
      foreach $key => $value (@s)
      {
         if (%scores[$value] < $top)
         {
            remove();
         }
      }

      return iff(size(@s) < 5, @s, sublist(@s, 0, 5));
   }

   # special case--make sure all uppercase words go on top.  Why not?
   if (uc($1) in $dictionary && uc($1) !in @s)
   {
      add(@s, uc($1));
   }

   return @s;
}   

sub initEdits
{
  local('%edits $1');
   %edits = [{
      if ($1)
      { 
           return $1;
      }
      else if (-exists "models/edits.bin")
      {
          local('$handle $r');
          $handle = openf("models/edits.bin");
          $r = readObject($handle);
          closef($handle);
          return $r;
      }
      else
      {
          return ohasha();
      }
   }: $1];

   if (islowmem() eq "true") 
   {
      setMissPolicy(%edits,
      {
         return filterByDictionary($2, $dictionary);
      });
   }
   else
   {
      setMissPolicy(%edits,
      {
         return editst($dictionary, $trie, $2);
      });
   }

   setRemovalPolicy(%edits,
   {
      return iff([[$1 getData] size] > 512);
   });

   return %edits;
}

sub get_network
{
   local('$network $handle $1');

   if (!-exists "models/ $+ $1")
   {
      warn("'models/ $+ $1 $+ ' doesn't exist");
   }

   $handle = openf(iff(-exists "models/ $+ $1" && $1 ne "", "models/ $+ $1", "network.bin"));
   $network = readObject($handle);
   closef($handle);
   [$network reinit];

   return $network;
}

# CompareSuggestions($network, &criteriaFunction, "mispelled word")
#    return a function suitable for use with sort() to rack and stack results 
sub CompareSuggestions
{
   local('%cache %result');

   %cache = ohash();
   setMissPolicy(%cache, lambda(
   {
      if ($2 ne "" && $original ne "")
      {
         local('$result $nn');

         $nn = $network['$network'];
         $result = feedforward([$criteria : $original, $2, $pool, $pre, $next], $nn[0], $nn[1])[0]["result"];

         #$result = [$network getresult: [$criteria : $original, $2, $pool, $pre, $next]]["result"];
         #warn("$original -> $2 : " . [$criteria : $original, $2, $pool, $pre, $next] . " = $result");
         return $result;
      }

      return 0.0;
   }, $original => $3, $network => $1, $criteria => $2, \$pool, \$pre, \$next));

   return %cache; 
}

sub spellcheckerFeatures
{
   local('$checka $checkb $a $b');
   $a = charAt($1, 0);
   $b = charAt($2, 0);
   $checka = iff(strlen($1) > 2, charAt($1, 1) . $a . substr($1, 2));
   $checkb = $a . $b;

   return %(
      distance    => iff( editDistance($2, $1) == 1, 1.0, 0.0 ),
      postf       => Pbigram2($2, $5),
      pref        => Pbigram1($4, $2),
      firstLetter => iff(uc($a) eq uc($b) || $checka eq $2 || $checkb eq "gx" || $checkb eq "fp" || $checkb eq "ck" || scoreDistance($a, $b) == 0, 1.0, 0.0)
   );
}

sub misuseFeatures
{
   return %(
      postf       => Pbigram2($2, $5),
      pref        => Pbigram1($4, $2),
      probability => Pword($2),
      trigram     => Ptrigram($7, $4, $2),
      trigram2    => Ptrigram2($2, $5, $8)
   );
}

# features("mispelled word", "suggestion", @suggestions, "previous", "next", @(trigram2, trigram1)), "prepre", "nextnext"
sub features
{
   local('%r');

   if (%features["soundex"] == 1)
   {
      %r["soundex"] = 1.0 / (editDistance(soundex($2), soundex($1)) + 1);
   }

   if (%features["distance"] == 1)
   {
      %r["distance"] = iff( editDistance($2, $1) == 1, 1.0, 0.0 );
#      assert %r["distance"] <= 1.0 && %r["distance"] >= 0.0 : "distance fail: " . @_;
   }

   if (%features["frequency"] == 1)
   {
      %r["frequency"] = Pword($2);
   }

   if (%features["firstLetter"] == 1)
   {
      local('$checka $checkb');
      $checka = iff(strlen($1) > 2, charAt($1, 1) . charAt($1, 0) . substr($1, 2));
      $checkb = charAt($1, 0) . charAt($2, 0);

#      %r["firstLetter"] = iff(uc(charAt($1, 0)) eq uc(charAt($2, 0)), 1.0, iff($checka eq $2 || $checkb eq "gx" || $checkb eq "fp" || $checkb eq "ck", 0.50, 0.0));
#      %r["firstLetter"] = iff(uc(charAt($1, 0)) eq uc(charAt($2, 0)) || $checka eq $2); # || $checkb eq "gx" || $checkb eq "fp" || $checkb eq "ck", 1.0, 0.0);
#      %r["firstLetter"] = iff(uc(charAt($1, 0)) eq uc(charAt($2, 0))); # || $checka eq $2); # || $checkb eq "gx" || $checkb eq "fp" || $checkb eq "ck", 1.0, 0.0);
       %r["firstLetter"] = iff(uc(charAt($1, 0)) eq uc(charAt($2, 0)) || $checka eq $2 || $checkb eq "gx" || $checkb eq "fp" || $checkb eq "ck" || scoreDistance(charAt($1, 0), charAt($2, 0)) == 0, 1.0, 0.0);
#       %r["firstLetter"] = iff(uc(charAt($1, 0)) eq uc(charAt($2, 0)) || $checka eq $2 || $checkb eq "gx" || $checkb eq "fp" || $checkb eq "ck", 1.0, 0.0);
   }

   if (%features["transpose"] == 1)
   {
      local('$check');
      $check = iff(strlen($1) > 2, charAt($1, 1) . charAt($1, 0) . substr($1, 2));

      %r["transpose"] = iff($check eq $2, 1.0, 0.0);
   }

   if (%features["phonetic"] == 1)
   {
      local('$check');
      $check = charAt($1, 0) . charAt($2, 0);

      %r["phonetic"] = iff($check eq "gx" || $check eq "fp" || $check eq "ck", 1.0, 0.0);
   }

   if (%features["trigram"] == 1)
   {
      %r["trigram"] = Ptrigram($7, $4, $2);
   }

   if (%features["trigram2"] == 1)
   {
      %r["trigram2"] = Ptrigram2($2, $5, $8);
   }

   if (%features["pos"] == 1)
   {
      local('$pre2 $pre1 $single $assoc $all');
      ($pre2, $pre1) = $6;
      $single = tagSingle($pre2, $pre1, $4, $2);
      %r["pos"] = scoreTags($pre2, $pre1, $single);
#      warn("$pre2 $pre1 $2 $+ / $+ $single = " . %r["pos"]);
   }
  
   if (%features["psize"] == 1)
   {
      %r["psize"] = 1.0 / (size($3) + 1);
   }

   if (%features["pref"] == 1)
   {
      %r["pref"] = Pbigram1($4, $2) + 0.0;
   }   

   if (%features["postf"] == 1)
   {
      %r["postf"] = Pbigram2($2, $5) + 0.0;
   }

   if (%features["probability"] == 1)
   {
      %r["probability"] = Pword($2);
   }

   if (%features["network"] == 1)
   {
      this('$net $criter');
      if ($net is $null || $criter is $null)
      {
          $net = get_network("network3f.bin");
          $criter = criteria(@("distance", "frequency", "firstLetter"));
      }
      %r["network"] = [$net getresult: invoke($criter, @_)]["result"]; 
   }

#   warn("$2 : " . %r);
   return %r;
}

# criteria($word, $suggestion)
sub criteria
{
   return lambda(&features, %features => putAll(%(), $1, { return 1; }));
}

global('%shortcodes');
%shortcodes = %(archives => 1, audio => 1, contact-form => 1, dailymotion => 1, digg => 1, flickr => 1, gallery => 1, googlemaps => 1, googlevideo => 1, 
                livevideo => 1, odeo => 1, podtech => 1, polldaddy => 1, redlasso => 1, rockyou => 1, scribd => 1, slideshare => 1, soundcloud => 1, sourcecode => 1, 
                splashcast => 1, vimeo => 1, youtube => 1, bliptv => 1, kytetv => 1, wpvideo => 1);

sub removeShortCodes
{
   local('@results @maybe @words $head $next');
   @words = $1;

   while (size(@words) >= 1)
   {
      ($head, $next) = @words;
      if ($head eq '[' && $next in %shortcodes)
      {
         while ($head ne ']' && size(@words) >= 1)
         {
            @words = sublist(@words, 1);
            ($head) = @words;
         }

         push(@results, '['); # this is meant to act as a placeholder for the shortcode, AtD eliminates it from precontext

         if (size(@words) >= 1)
         {
            @words = sublist(@words, 1);
         }
      }
      else
      {
         push(@results, $head);
         @words = sublist(@words, 1);
      }
   }

   return @results;
}

# check a sentence for a mispelled word
sub checkSentenceSpelling
{
   local('$index $word $previous $next $rule $suggestf');

   $suggestf = iff($suggestf !is $null, $suggestf, &suggest);
   $previous = '0BEGIN.0';

   foreach $index => $word (removeShortCodes($1))
   {
      $next = iff(($index + 1) < size($1), $1[$index + 1], '0END.0');
      
      if ($word ne "" && $word !in $dictionary && lc($word) !in $dictionary)
      {
         if (charAt($word, 0) eq "'")
         {
            $previous = "";
         }
         $word = fixWord($word);

         if ($word in $dictionary || lc($word) in $dictionary || [$word startsWith: 'http//'] || [$word startsWith: 'https//'])
         {
            # make sure $previous doesn't get set to the modified $word in these cases
            # 1. if the word was changed then the previous tag won't match up
            # 2. if the word is a URL then it won't match because my NLP stack mangled the : and .'s in the string

            $word = ""; 
         } 
         else if ($word ismatch '\d+(\'{0,1}s{0,1}|[aApP][mM])' || $word ismatch '(\d+[-/|x]\d+)+' || $word ismatch '\\${0,1}-{0,1}[0-9,]*(\\.\d+){0,1}(x|[MGT]{0,1}Hz|k|K|GB|TB|MB|KB|M|MM|[mkc]m|m){0,1}')
         {
            # skip time and year values, ranges like 9-5, dimensions like 2x4, monetary values $1.99, and disk sizes like 3GB
         }
         else if ($word ismatch '\d+(st|nd|rd|th)')
         {
            # handle numbers

            if ($word !ismatch '\d*?((1st)|(2nd)|(3rd)|(4th)|(5th)|(6th)|(7th)|(8th)|(9th)|(0th))' && $word !ismatch '1\dth')
            {
               local('$number $suggestions $check');
               $number = long(matches($word, '(\d+)')[0]);
               $check  = $number % 10;

               if ($number >= 11 && $number < 20)
               {
                  $suggestions = "$number $+ th";
               }
               else if ($check == 1)
               {
                  $suggestions = "$number $+ st";
               }
               else if ($check == 2)
               {
                  $suggestions = "$number $+ nd";
               }
               else if ($check == 3)
               {
                  $suggestions = "$number $+ rd";
               }
               else
               {
                  $suggestions = "$number $+ th";
               }

               $rule = %(word => $suggestions,
                          rule => "Spelling",
                          style => "red",
                          category => "Spelling",
                          filter => "none");

               push(@results, filterSuggestion( @($rule, $word, $word, $previous) ));
            }
         }
         else if ([$word endsWith: "'s"])
         {
            local('$word2');
            $word2 = substr($word, 0, -2);
            if ($word2 in $dictionary || lc($word2) in $dictionary)
            {   
               if (right($word2, 1) eq 's' && -islower charAt($word, 0))
               {
                  $rule = %(word => "$word2 $+ '", 
                         rule => "Possessive Ending",
                         style => "red",
                         category => "Spelling",
                         filter => "none",
                         view   => "view/rules/empty.slp",
                         info   => "none"
#                         this needs to be moved into engine.sl as info.slp doesn't use the spellchecker to resolve suggestions
#                         recommendation => { return "Use <em>" . $1["word"] . "</em>"; },
#                         description => 'A possessive noun form says that the noun owns something.  If the noun is singular and ends with s, z, or x you indicate possession with a single apostrophe at the end.  If the noun is plural and ends with an s you use a single apostrophe at the end as well.  Otherwise you indicate possession with an apostrophe s at the end of the word.'
                  );

                  push(@results, filterSuggestion( @($rule, $word, $word, $previous) ));
               }
            }
            else
            {
               $rule = %(word => join(", ", map({ return iff([$1 endsWith: 's'], "$1 $+ '", "$1 $+ 's");  }, suggest($word2, $dictionary, $previous, $next))), 
                         rule => "Spelling",
                         style => "red",
                         category => "Spelling",
                         filter => "none", info => "none");

                push(@results, filterSuggestion( @($rule, $word, $word, $previous) ));
            }
         }
         else if ($word ismatch '\w+(-\w+)+')
         {
            local('@tempw @tempx');
            @tempx = split('-', $word);
            @tempw = filter({ return iff($1 !in $dictionary && lc($1) !in $dictionary && !-isnumber $1, $1); }, @tempx); # keep any mispelled words

            if (size(@tempw) == 0)  # if none of the words are mispelled then suggest all the words as-is
            {
               if ('*ly-*' iswm $word)
               {
                  $rule = %(word => join(" ", @tempx),
                      rule => "No Hyphen",
                      style => "red",
                      category => "Spelling",
                      info => "none",
                      filter => "none");

                  push(@results, filterSuggestion( @($rule, $word, $word, $previous) ));

                  # description => "If an adverb ends in -ly, you shouldn't use a hyphen between it and the adjective it modifies.",
               }
               else if ('*-based' !iswm $word && 'over-*' !iswm $word && 'pre-*' !iswm $word && 'anti-*' !iswm $word && 'non-' !iswm $word && '*-sharing' !iswm $word) 
               {
                  $rule = %(word => join(" ", @tempx),
                      rule => "Spelling",
                      style => "red",
                      category => "Spelling",
                      info => "none",
                      filter => "none");

                  # for now, don't flag hyphenated words as misspelled... wait until we have a better scheme
                  #push(@results, filterSuggestion( @($rule, $word, $word, $previous)));
               }
            }
            else # do a normal round of suggestions
            {
               $rule = %(word => join(", ", suggest($word, $dictionary, $previous, $next)), # suggest($word, %context[$previous])),
                      rule => "Spelling",
                      style => "red",
                      category => "Spelling",
                      info => "none",
                      filter => "none");

                push(@results, filterSuggestion(@($rule, $word, $word, $previous)));
            }
         }
         else
         {
            $rule = %(word => join(", ", suggest($word, $dictionary, $previous, $next)), # suggest($word, %context[$previous])),
                      rule => "Spelling",
                      style => "red",
                      category => "Spelling",
                      filter => "none");

             push(@results, filterSuggestion(@($rule, $word, $word, $previous)));
         }
      }
      else if ($word isin ',-()[]:;/--')
      {
         # TinyMCE plugin isn't aware of commas so make the previous word ""
         $word = "";
      }
      else if ($word eq $next && "$word $+ - $+ $next" !in $dictionary && $word ne 'Boing' && $word ne "Johnson" && $word ne "Mahi")
      {
         $rule = %(word => $word, 
                   rule => "Repeated Word",
                   style => "green",
                   category => "Grammar",
                   filter => "none",
                   info => "none");

         push(@results, filterSuggestion(@($rule, "$word $next", "$word $next", $previous)));
      }

      $previous = $word;
   }
}

# check a sentence for a mispelled word
sub checkRepeatedWords
{
   local('$index $word $previous $next $rule $suggestf');

   $previous = '0BEGIN.0';

   foreach $index => $word (removeShortCodes($1))
   {
      $next = iff(($index + 1) < size($1), $1[$index + 1], '0END.0');

      if ($word isin ',-()[]:;/--')
      {
         $word = "";
      }
      else if ($word eq $next && "$word $+ - $+ $next" !in $dictionary && $word ne 'Boing' && $word ne "Johnson" && $word ne "Mahi")
      {
         $rule = %(word => $word, 
                   rule => "Repeated Word",
                   style => "green",
                   category => "Grammar",
                   filter => "none",
                   info => "none");

         push(@results, filterSuggestion(@($rule, "$word $next", "$word $next", $previous)));
      }

      $previous = $word;
   }
}

sub checkHomophone
{
   local('$current $options $pre $next %scores $criteriaf @results $option $hnetwork $tags $pre2 $next2');
   ($hnetwork, $current, $options, $pre, $next, $tags, $pre2, $next2) = @_;

   # score the options
   foreach $option ($options)
   {
      %scores[$option] = [$hnetwork getresult: misuseFeatures($current, $option, $options, $pre, $next, $tags, $pre2, $next2)]["result"];
      if ($option eq $current)
      {
         %scores[$option] *= iff($pre2 eq "" || !hasTrigram($pre2, $pre), $bias1, $bias2); # bias factor
      }
   }
#   warn("$pre2 $+ . $+ $pre $+ _ $+ $current $+ _ $+ $next $+ . $+ $next2 - " . iff($pre2 eq "" || !hasTrigram($pre2, $pre), $bias1, $bias2) . " = " . %scores);

#   warn("Looking at $pre $current $+ / $+ $options $next " . %scores);

   # filter out any unacceptable words
   @results = filter(lambda({ return iff(%scores[$1] >= %scores[$current] && $1 ne $current && %scores[$1] > 0.0, $1, $null); }, \%scores, \$current), $options);

   # sort the remaining results (probably only one left at this point)
   @results = sort(lambda({ return %scores[$2] <=> %scores[$1]; }, \%scores), @results);

   if (size(@results) > 0)
   {
     #warn("checkHomophone: " . @_ . " -> " . @results);
     #warn("                " . %scores);
   }

   # return the results
   return @results;
}
