include("lib/nlp.sl");
include("lib/fsm.sl");
include("lib/spellcheck.sl");
include("lib/tagger.sl");
include("lib/wordforms.sl");

sub initAllModels
{
   global('$model $rules $dictionary $trie $network $hnetwork %edits $dsize $verbs $endings $homophones $agreement');

   $model      = get_language_model();
   $dictionary = dictionary();
   $trie       = trie($dictionary);
   extendDictionary($dictionary, 'models/not_misspelled.txt'); # do this after the Trie is built, add words that are not 
                                                                        # to be suggested but not considered misspelled to the dictionary
   $rules      = get_rules();
   $network    = get_network("cnetwork.bin");
   $hnetwork   = get_network("hnetwork4.bin");
   %edits      = initEdits();
   $dsize      = size($dictionary);
   $verbs      = loadVerbData();
   initTaggerModels();
}

sub get_rules
{
  this('$r');

  if ($r is $null)
  {
     $r = [{
        local('$handle $rules $rcount $rule');
        $rules = @();
        $handle = openf("models/rules.bin");
        $rcount = readObject($handle);
        while $rule (readObject($handle)) 
        {
           push($rules, $rule);
        }
        closef($handle);
        warn("Rules loaded: $rcount rules");
        return $rules;
     }];
  }

  return $r;
}

sub checkAll
{
   local('$engine @r');

   foreach $engine ($rules) 
   {
      @r = check($engine, $1);
      if (@r !is $null)
      {
         return @r;    
      }
   }
}

inline setResultsWithCorrectEngine
{
   if ($index !is $null && $index >= 0 && $index < size($rules))
   {
      @result = check($rules[$index], @tags)
   }
   else
   {
      @result = checkAll(@tags);
   }
}

sub processSingle
{
   local('@list @result $rule $index $path @tags');
   @list = splitIntoWords($1);

   if ($2 !is $null && size(split('\/', $2)) >= size(@list))
   {
      @tags = map(lambda({ return @($1, shift(@t)); }, @t => split('\/', $2)), @list);
   }
   else
   {
      @tags = taggerWithTrigrams(@list);
   }

   setResultsWithCorrectEngine($index => $3);
   if (@result is $null)
   {
      add(@tags, @('0BEGIN.0', 'UNK'));
      setResultsWithCorrectEngine($index => $3);

      if (@result is $null)
      {
         @tags = sublist(@tags, 1);
         push(@tags, @('0END.0', 'UNK'));
         @result = checkAll(@tags);

         if (@result is $null)
         {
            add(@tags, @('0BEGIN.0', 'UNK'));
            @result = checkAll(@tags);
         }
      }
   }

   return iff(@result !is $null && size(@result) > 0, @result[0], $null);
}

sub suggestions2
{
   return suggestions($1, map({ return @($1, '.*'); }, split(' ', $2)));
}

# loops through the proposed suggestions and replaces the token using the tagger data
# suggestions("suggestion", @tagsn)
sub suggestions
{
    if (-isarray $1)
    {
       return map(   lambda({ return suggestions($1, @tagsn); }, @tagsn => $2)   , $1);
    }

    if ($2 !is $null)
    {
       local('$index $value $s')
       $s = $1;
       foreach $index => $value ($2)
       {
          $s = strrep($s, '\\' . $index, $value[0]);
       }

       if (':' isin $1)
       {
          local('@temp');
          @temp = split(' ', $s);
          @temp = map(
          {
             if ([$1 endsWith: ":singular"])
             {
                return pluralToSingular(left($1, -9));      
             }
             else if ([$1 endsWith: ":lower"])
             {
                local('$w');
                $w = left($1, -6);
                if (lc($w) in $dictionary) { return lc($w); }
                return $w;
             }
             else if ([$1 endsWith: ":upper"])
             {
                local('$w');
                $w = left($1, -6);
                if (lc($w) in $dictionary) { return uc(charAt($w, 0)) . substr($w, 1); }
                return $w;
             }
             else if ([$1 endsWith: ":determiner"])
             {
                return determiner(left($1, -11), 0);
             }
             else if ([$1 endsWith: ":determiner-u"])
             {
                return determiner-u(left($1, -13), 0);
             }
             else if ([$1 endsWith: ":determiner2"])
             {
                return determiner(left($1, -12), 1);
             }
             else if ([$1 endsWith: ":determiner2-u"])
             {
                return determiner-u(left($1, -14), 1);
             }
             else if ([$1 endsWith: ":determiner3"])
             {
                return determiner(left($1, -12), 2);
             }
             else if ([$1 endsWith: ":determiner3-u"])
             {
                return determiner-u(left($1, -14), 2);
             }
             else if ([$1 endsWith: ":possessive"])
             {
                return pluralToSingular(left($1, -11)) . '\'s';      
             }
             else if ([$1 endsWith: ":nonposs"])
             {
                return singularToPlural(left($1, -10));
             }
             else if ([$1 endsWith: ":present"])
             {
                return presentParticipleVerb(left($1, -8));
             }
             else if ([$1 endsWith: ":participle"])
             {
                return pastParticipleVerb(left($1, -11));
             }
             else if ([$1 endsWith: ":base"])
             {
                return baseVerb(left($1, -5));
             }
             else if ([$1 endsWith: ":past"])
             {
                return simplePastVerb(left($1, -5));
             }
             else if ([$1 endsWith: ":plural"])
             {
                return singularToPlural(left($1, -7));
             }
             else if ([$1 endsWith: ":nosuffix"])
             {
                return noSuffix(left($1, -9));
             }
             else if ([$1 endsWith: ":positive"])
             {
                return positiveWord(left($1, -9));
             }

             return $1;
          }, @temp);

          return join(" ", @temp);
       }

       return $s;
    }
    return $1;
}

sub filterSuggestion
{
   local('$error $rule $text $path $context $sentence $next @tagsp @tagsn @temp $pre2 $next2');
   $error = $1;
   ($rule, $text, $path, $context, $next, @tagsp, @tagsn) = $1;

   if ($rule["word"] eq "")
   {
      local('$word');
      foreach $word (split('\s+', $path))
      {
         if ($word !in $dictionary && $rule['rule'] ne 'Spelling')
         {
            return;
         }
      }
      $error[4] = @();
   }
   else if ($rule["filter"] eq "sane") 
   {
      if ($rule["avoid"] ne "") {
         local('@w @avoid $a');
         @w = split(' ', lc($path));
         @avoid = split(',\s+', $rule['avoid']);
         foreach $a (@avoid) 
         {
            if ($a in @w)
            {
               return;
            }
         }
      }

      $error[4] = filter(lambda({ return iff(scoreSane($1) > 0.0, $1); }, \@tagsn), suggestions(split(', ', $rule["word"]), @tagsn));
      if (size($error[4]) == 0) { return; }

      local('$suggestion $start');

      foreach $suggestion ($error[4]) 
      {
         if ($suggestion eq $path) 
         {
            return;
         }
      }
   }
   else if ($rule["filter"] eq "none")
   {
      $error[4] = suggestions(split(', ', $rule["word"]), @tagsn);
   }
   else if ($rule["filter"] eq "die")
   {
      $error[4] = @();
   }
   else if ($rule["filter"] eq "homophone")
   {
      $pre2 = iff(size(@tagsp) >= 3, @tagsp[-2][0], iff(strlen($context) > 0 && -isupper charAt($context, 0) && -isletter charAt($context, 0), '0BEGIN.0',"")); # $pre2 $context $text
      $next2 = iff(size(@tagsn) >= 3, @tagsn[2][0], '0END.0');
      $error[4] = checkHomophone($hnetwork, $text, split(', ', $rule["word"]), $context, $next, @('UNK', 'UNK'), $pre2, $next2, $bias1 => 30.0, $bias2 => 10.0);
      if (size($error[4]) == 0)
      {
         return;
      }
   }
   else if ($rule["filter"] eq "stats")
   {
      $pre2 = iff(size(@tagsp) >= 3, @tagsp[-2][0], iff(strlen($context) > 0 && -isupper charAt($context, 0) && -isletter charAt($context, 0), '0BEGIN.0',"")); # $pre2 $context $text
      $next2 = iff(size(@tagsn) >= 3, @tagsn[2][0], '0END.0');
      $error[4] = checkHomophone($hnetwork, $text, split(', ', $rule["word"]), $context, $next, @('UNK', 'UNK'), $pre2, $bias1 => 100.0, $bias2 => 15.0);
      if (size($error[4]) == 0)
      {
         return;
      }
   }
   else if ($rule["filter"] eq "nextonly")
   {
      if (scoren(lc($text)) < scoren(lc(suggestions($rule["word"], @tagsn))))
      {
         $error[4] = @(suggestions($rule["word"], @tagsn));
      }
      else
      {
         return;
      }
   }
   else if ($rule["filter"] eq "indefarticle")
   {
      if (scorer(lc($text)) < scorer(lc(suggestions($rule["word"], @tagsn))))
      {
          $error[4] = @(suggestions($rule["word"], @tagsn));
      }
      else
      {
          return;
      }
   }
   else if ("pivots" in $rule)
   {
      local('$suggestions $score $s $n $p $tscore $_context $_next');
      $suggestions = ohash();

      # this filter is applied to more involved rules where the phrase may have more info.
      local('$pivots @temp');
      $pivots = suggestions(split(',', $rule["pivots"]), @tagsn);
         
      ($context, $next) = split("\\s+".$pivots[0]."\\s+", "$context $text $next");
           
      $context = split(' ', $context)[-1];
      $next = split(' ', $next)[0];
      $text = shift($pivots);

      $score = (score($context, $text, $next) * 1.0) + 0.00001;

      foreach $s (suggestions(split(', ', $rule["word"]), @tagsn))
      {
         $p = shift($pivots);

         if ($s eq $p)
         {
            ($_context, $_next) = split(" $p ", "$context $s $next");
         }
         else if ([$s startsWith: $p])
         {
            ($_context, $_next) = split(" $p ", "$context $s");
         }
         else if ([$s endsWith: $p])
         {
            ($_context, $_next) = split(" $p ", "$s $next");
         }
         else
         {
            ($_context, $_next) = split(" $p ", $s);
         }
            
         $n = score($_context, $p, $_next);

         if ($n >= $score && $p ne $text)
         {
            $suggestions[$s] = $score;
         }
      }

      if (size($suggestions) == 0)
      {
         return;
      }
      else
      {
         $error[4] = sort(lambda({ return $suggestions[$2] <=> $suggestions[$1]; }, \$suggestions), keys($suggestions));
         $error[5] = $suggestions;
      }
   }
   else
   {
      local('$suggestions $score $s $n $tscore');
      $suggestions = ohash();
      $score       = (score($context, $text, $next) * 0.50) + 0.00001;

      foreach $s (suggestions(split(', ', $rule["word"]), @tagsn))
      {
         $n = score($context, $s, $next);

         if ($n >= $score && $s ne $text)
         {
            $suggestions[$s] = $score;
         }
      }

      if (size($suggestions) == 0)
      {
         return;
      }
      else
      {
         $error[4] = sort(lambda({ return $suggestions[$2] <=> $suggestions[$1]; }, \$suggestions), keys($suggestions));
         $error[5] = $suggestions;
      }
   }

   return $error;
}

sub scoreSane {
	local('$word');
	foreach $word (split('\s+', $1)) {
		if (count($word) == 0 && count(lc($word)) == 0) {
			return 0.0;
		}
	}

	return 1.0;
}

sub scorer
{
   local('@words');
   @words = split('\s+', $1);
   return Pbigram2(@words[0], @words[1]);
}

sub scoren
{
   local('@words');
   @words = split('\s+', $1);
   return Pbigram2(@words[1], @words[2]);
}

sub score
{
   if ($2 eq "(omit)")
   {
      return Pbigram1($1, $3) / 2.0;
   }
   else
   {
      local('@left @words @right $x');
      @left = split('\s+', $1);
      @words = split('\s+', $2); 
      @right = split('\s+', $3);

      return (Pbigram1(@left[-1], @words[0]) + Pbigram2(@words[-1], @right[0])) / 2.0;

#      warn("Scoring: P(".@words[0]."|" . $1 . ") + P2(" . @words[-1] . "|".$3.") / 2.0"); 
#      warn("   PB1 = " . Pbigram1($1, @words[0]));
#      warn("   PB2 = " . Pbigram2(@words[-1], $3));
#      warn("   = $x");
#      return $x;
   }
}

sub fixWord
{
   if (strlen($1) > 0)
   {
      if (charAt($1, 0) eq '\'')
      {
         return fixWord(substr($1, 1));
      }
      if (charAt($1, -1) eq '\'')
      {
         return fixWord(substr($1, 0, -1));
      }
   }
   return replace($1, '[\W&&[^\'-/\p{Ll}\p{Lu}]]+', '');
}

sub processSentence
{
   local('@list @words @tags $engine $nospell $index');

   # tag the sentence
   @list = splitIntoWords($sentence);
   @words = copy(@list);
   @tags = taggerWithTrigrams(@list);       

   # push the end of the sentence onto the tags so the rule engine can find it.
   push(@tags, @('0END.0', 'UNK'));

   # push the hook for the beginning of the sentence.  
   add(@list, '0BEGIN.0');
   add(@tags, @('0BEGIN.0', 'UNK'));

   # check spelling
   if ($nospell is $null) 
   {
      checkSentenceSpelling(@words, \@results);
   }
   else
   {
      checkRepeatedWords(@words, \@results);
   }

   # run the various checkers against the sentence
   foreach $index => $engine ($rules) 
   {
      processSentenceWithRules(@list, @tags, $engine, $index, \@results, \$sentence);
   }
}

sub processSentenceWithRules 
{
   local('$from $previous $next @words @list @tags @backtags $rule $index $path @result $t $u $suggestion $rules');
   (@list, @tags, $rules) = @_;
   @backtags = @();

   $from = 0;

   $previous = '0BEGIN.0';
   $next     = '0END.0';
   
   while (size(@list) > 0)
   {
      # ($rule, index, path in fsm?)

      @result = check($rules, @tags);
      if (@result !is $null && @result[0]["filter"] ne "kill")
      {
          ($rule, $index, $path) = @result;

          $t = join(" ", sublist(@list, 0, $index));

          if (indexOf($sentence, $t) is $null)
          {
              local('$start $end @l');
              @l     = sublist(@list, 0, $index);
              $end   = indexOf($sentence, " " . @l[-1], $from) + 1 + strlen(@l[-1]);
              $start = lindexOf($sentence, @l[0], $end);
		
              $u = substr($sentence, $start, $end);
           }
           else
           {
              $u = $t;
           }

           $next = iff ($index >= size(@list), '0END.0', @list[$index]);     # set the current next value

           #warn("$[15]previous $[15]t $[15]next $[-15]index");

           if (size(@backtags) == 0)
           {
              $suggestion = filterSuggestion( 
                               @($rule, right($t, -9), $u, '0BEGIN.0', $next, @(), copy(sublist(@tags, 1)))
                            );
           }
           else
           {
              $suggestion = filterSuggestion( 
                               @($rule, $t, $u, $previous, $next, copy(@backtags), copy(@tags))
                            );
           }

           if ($suggestion !is $null)
           {
              $previous = @list[$index - 1]; # set the next previous value

              @list = sublist(@list, $index);
              putAll(@backtags, sublist(@tags, 0, $index));
              @tags = sublist(@tags, $index);
              $from += strlen($u);

              if ($rule['filter'] ne "die") 
              {
                 $suggestion[7] = $4;
                 push(@results, $suggestion);
              }
           }
           else
           {
              $from += strlen(@list[0]);
              $previous = @list[0];
              @list = sublist(@list, 1);
              push(@backtags, @tags[0]);
              @tags = sublist(@tags, 1);
           }
      } 
      else
      {
           $from += strlen(@list[0]);
           $previous = @list[0];
           @list = sublist(@list, 1);
           push(@backtags, @tags[0]);
           @tags = sublist(@tags, 1);
      }
   }
}

sub processDocument
{
  local('@paragraphs $paragraph $sentence @results @list $t $u $x $r @result $from $count $previous $next   $rule $index $path   $word @words  $dsize $dprob  @tags @backtags $2');

  @paragraphs = splitByParagraph($1);

  foreach $paragraph (@paragraphs)
  {
     foreach $sentence ($paragraph)
     {
        if ($sentence eq "")
        {
           continue;
        }

        processSentence(\$sentence, \@results, $nospell => $2);
#        print(strrep($sentence, "\xA0", '&nbsp;', "\xA1", '&iexcl;', "\xA2", '&cent;', "\xA3", '&pound;', "\xA4", '&curren;', "\xA5", '&yen;', "\xA6", '&brvbar;', "\xA7", '&sect;', "\xA8", '&uml;', "\xA9", '&copy;', "\xAA", '&ordf;', "\xAB", '&laquo;', "\xAC", '&not;', "\xAD", '&shy;', "\xAE", '&reg;', "\xAF", '&macr;', "\xB0", '&deg;', "\xB1", '&plusmn;', "\xB2", '&sup2;', "\xB3", '&sup3;', "\xB4", '&acute;', "\xB5", '&micro;', "\xB6", '&para;', "\xB7", '&middot;', "\xB8", '&cedil;', "\xB9", '&sup1;', "\xBA", '&ordm;', "\xBB", '&raquo;', "\xBC", '&frac14;', "\xBD", '&frac12;', "\xBE", '&frac34;', "\xBF", '&iquest;', "\xC0", '&Agrave;', "\xC1", '&Aacute;', "\xC2", '&Acirc;', "\xC3", '&Atilde;', "\xC4", '&Auml;', "\xC5", '&Aring;', "\xC6", '&AElig;', "\xC7", '&Ccedil;', "\xC8", '&Egrave;', "\xC9", '&Eacute;', "\xCA", '&Ecirc;', "\xCB", '&Euml;', "\xCC", '&Igrave;', "\xCD", '&Iacute;', "\xCE", '&Icirc;', "\xCF", '&Iuml;', "\xD0", '&ETH;', "\xD1", '&Ntilde;', "\xD2", '&Ograve;', "\xD3", '&Oacute;', "\xD4", '&Ocirc;', "\xD5", '&Otilde;', "\xD6", '&Ouml;', "\xD7", '&times;', "\xD8", '&Oslash;', "\xD9", '&Ugrave;', "\xDA", '&Uacute;', "\xDB", '&Ucirc;', "\xDC", '&Uuml;', "\xDD", '&Yacute;', "\xDE", '&THORN;', "\xDF", '&szlig;', "\xE0", '&agrave;', "\xE1", '&aacute;', "\xE2", '&acirc;', "\xE3", '&atilde;', "\xE4", '&auml;', "\xE5", '&aring;', "\xE6", '&aelig;', "\xE7", '&ccedil;', "\xE8", '&egrave;', "\xE9", '&eacute;', "\xEA", '&ecirc;', "\xEB", '&euml;', "\xEC", '&igrave;', "\xED", '&iacute;', "\xEE", '&icirc;', "\xEF", '&iuml;', "\xF0", '&eth;', "\xF1", '&ntilde;', "\xF2", '&ograve;', "\xF3", '&oacute;', "\xF4", '&ocirc;', "\xF5", '&otilde;', "\xF6", '&ouml;', "\xF7", '&divide;', "\xF8", '&oslash;', "\xF9", '&ugrave;', "\xFA", '&uacute;', "\xFB", '&ucirc;', "\xFC", '&uuml;', "\xFD", '&yacute;', "\xFE", '&thorn;', "\xFF", '&yuml;'));
     }

     $count += size(@results);
  }

  return @results;
}

sub denom
{
   this('$db');       

   if ($db is $null)
   {
      local('$handle $text $key $value');

      $db = %();

      $handle = openf("data/rules/denomdb.txt");
      while $text (readln($handle))
      {
         ($key, $value) = split('\t+', $text);
         $db[$key] = $value;
      }
      closef($handle);
   }

   return $db[$1];
}
