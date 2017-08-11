sub loadVerbData
{
   local('$handle $text $base $past $participle $plural $present $data $temp $_past $_participle $_plural $_present ');
   $handle = openf("data/rules/irregular_verbs.txt");

   $data = %(past => %(), base => %(), participle => %(), plural => %(), present => %());

   while $text (readln($handle))
   {
      ($base, $_past, $_participle, $_plural, $_present) = split('[\s\t]+', $text);
      $temp = %(  base       => $base, 
                  past       => sort({ return Pword($2) <=> Pword($1); }, split(',', $_past))[0], 
                  participle => sort({ return Pword($2) <=> Pword($1); }, split(',', $_participle))[0],
                  plural     => sort({ return Pword($2) <=> Pword($1); }, split(',', $_plural))[0],
                  present    => sort({ return Pword($2) <=> Pword($1); }, split(',', $_present))[0]
               );

      $data['base'][$base] = $temp;

      foreach $past (split(',', $_past))
      {
         $data['past'][$past] = $temp;
      }

      foreach $participle (split(',', $_participle))
      {
         $data['participle'][$participle] = $temp;
      }

      foreach $plural (split(',', $_plural))
      {
         $data['plural'][$plural] = $temp;
      }

      foreach $present (split(',', $_present))
      {
         $data['present'][$present] = $temp;
      }
   }

   return $data;
}

sub positiveWord
{
   local('$word');
   $word = $1;
   
   if ($1 eq "unusual") { return "common"; }
   if ($1 eq "until") { return "after"; }


   if (strlen($1) > 2  && substr($1, 0, 2) eq "un")
   {
      $word = substr($1, 2);
   }

   if ($word in $dictionary)
   {
      return $word;
   }
   else
   {
      return $1;
   }
}

sub determiner
{
   local('@determiners @top');
   @determiners = @('a', 'an', 'either', 'every', 'his', 'her', 'its', 'my', 'neither', 'one', 'our', 'that', 'the', 'their', 'this', 'your');
   @top = sort(lambda({ return Pbigram2($2, $word) <=> Pbigram2($1, $word); }, $word => $1), @determiners);
   return @top[$2];
}

sub determiner-u
{
   local('$value $w');
   if (lc($1) in $dictionary) { $w = lc($1); }
   else { $w = $1; }

   $value = determiner($w);
   if (strlen($value) == 1) { return uc($value); }
   return uc(charAt($value, 0)) . substr($value, 1);
}

#
# convert a verb to its base form
#
sub baseVerb
{
   if ($1 in $verbs['base'])
   {
      return $1;
   }
   else if ($1 in $verbs['past'])
   {
      return $verbs['past'][$1]['base'];
   }
   else if ($1 in $verbs['participle'])
   {
      return $verbs['participle'][$1]['base'];
   }
   else if ($1 in $verbs['present'])
   {
      return $verbs['present'][$1]['base'];
   }
   else if ($1 in $verbs['plural'])
   {
      return $verbs['plural'][$1]['base'];
   }
   else if ([$1 endsWith: "ing"])
   {
      local('$base');
      $base = left($1, -3);
      if (right($base, 1) !isin "oy" && "$base $+ e" in $dictionary)
      {
         return "$base $+ e";
      }
      else
      {
         return  $base;
      }
   }
   else if ([$1 endsWith: "ed"])
   {
      if ($1 ismatch "deed|exceed|heed|need|seed|speed|succeed|unheed|unneed|weed")
      {
         return $1;
      }
      else if ($1 eq "created")
      {
         return left($1, -1);
      }
      else if (left($1, -2) in $dictionary)
      {
         return left($1, -2);
      }
      else if (left($1, -1) in $dictionary)
      {
         return left($1, -1);
      }
   }
   else if ([$1 endsWith: "es"]) 
   {
      if ($1 in @('uses', 'changes', 'continues')) 
      {
         return left($1, -1);
      }
      else if (left($1, -2) in $dictionary)
      {
         return left($1, -2);
      }
   }
   else if ([$1 endsWith: "s"]) 
   {
      return pluralToSingular($1);
   }

   return $1;   
}

#
# convert a verb to its past participle form
#
sub pastParticipleVerb
{
   local('$base');
   $base = baseVerb($1);
   if ($base in $verbs['base'])
   {
      return $verbs['base'][$base]['participle'];
   }

   return simplePastVerb($base);
}

#
# convert a verb to its simple past form
#
sub simplePastVerb
{
   local('$base');

   $base = baseVerb($1);
   if ($base in $verbs['base'])
   {
      return $verbs['base'][$base]['past'];
   }   

   if ([$base endsWith: "y"])
   {
      if ((left($base, -1) . 'ied') in $dictionary)
      {
         return left($base, -1) . 'ied';
      }
   }

   if ("$base $+ ed" !in $dictionary)
   {
      return "$base $+ d";
   }

   return "$base $+ ed";
}

#
# convert a verb to its present participle form
#
sub presentParticipleVerb
{
   local('$base');

   if ([$1 endsWith: "ed"] && (substr($1, -2) . "ing") in $dictionary) 
   {
      return substr($1, -2) . "ing";
   } 

   $base = baseVerb($1);

   if ($base in $verbs['base'])
   {
      return $verbs['base'][$base]['present'];
   }

   if ([$base endsWith: "e"] && $base ne "be")
   {
      return substr($base, 0, -1) . "ing";
   }

   return "$base $+ ing";
}

#
# convert a singular to its plural form
#
sub singularToPlural
{
   this('$mappings $words');

   if ($mappings is $null)
   {
      ($mappings, $words) = getWordMappings();
      $words = putAll(%(), values($words), keys($words));	

      $mappings = copy($mappings);
      $mappings['s'] = $null;
      $mappings = putAll(%(), values($mappings), keys($mappings));	
   }

   if ($1 in $words)
   {
      return $words[$1];
   }
   else if ($1 in $verbs['base'])
   {
      return $verbs['base'][$1]["plural"];
   }
   else
   {
      local('$e_plural $e_singular $temp');

      foreach $e_plural => $e_singular ($mappings)
      {
         if ([$1 endsWith: $e_plural])
         {
            $temp = substr($1, 0, -1 * strlen($e_plural)) . $e_singular;

            if ($temp in $dictionary)
            {
               return $temp;
            }
         }
      }
   }

   if (right($1, 1) ne "s" && "$1 $+ s" in $dictionary)
   {
      return "$1 $+ s";
   }
   return $1;
}

sub getWordMappings
{
   this('$mappings $words');
   if ($mappings is $null)
   {
      $words = %(
         addenda         => 'addendum',
         algae           => 'alga',
         alumnae         => 'alumna',
         alumni          => 'alumnus',
         analyses        => 'analysis',
         antennas        => 'antenna',
         apparatuses     => 'apparatus',
         appendices      => 'appendix',
         axes            => 'axis',
         bacilli         => 'bacillus',
         bacteria        => 'bacterium',
         bases           => 'basis',
         beaux           => 'beau',
         bison           => 'bison',
         buffalos        => 'buffalo',
         bureaus         => 'bureau',
         busses          => 'bus',
         cactuses        => 'cactus',
         calves          => 'calf',
         children        => 'child',
         corps           => 'corps',
         corpora         => 'corpus',
         crises          => 'crisis',
         criteria        => 'criterion',
         curricula       => 'curriculum',
         data            => 'datum',
         deer            => 'deer',
         dice            => 'die',
         dwarfs          => 'dwarf',
         diagnoses       => 'diagnosis',
         echoes          => 'echo',
         elves           => 'elf',
         ellipses        => 'ellipsis',
         embargoes       => 'embargo',
         emphases        => 'emphasis',
         errata          => 'erratum',
         firemen         => 'fireman',
         fish            => 'fish',
         focuses         => 'focus',
         feet            => 'foot',
         formulas        => 'formula',
         fungi           => 'fungus',
         genera          => 'genus',
         geese           => 'goose',
         halves          => 'half',
         heroes          => 'hero',
         hippopotami     => 'hippopotamus',
         hoofs           => 'hoof',
         hypotheses      => 'hypothesis',
         indices         => 'index',
         knives          => 'knife',
         leaves          => 'leaf',
         lives           => 'life',
         loaves          => 'loaf',
         lice            => 'louse',
         men             => 'man',
         matrices        => 'matrix',
         means           => 'means',
         media           => 'medium',
         memoranda       => 'memorandum',
         millenniums     => 'millennium',
         moose           => 'moose',
         mosquitoes      => 'mosquito',
         mice            => 'mouse',
         nebulae         => 'nebula',
         neuroses        => 'neurosis',
         nuclei          => 'nucleus',
         oases           => 'oasis',
         octopi          => 'octopus',
         ova             => 'ovum',
         oxen            => 'ox',
         paralyses       => 'paralysis',
         parentheses     => 'parenthesis',
         people          => 'person',
         phenomena       => 'phenomenon',
         potatoes        => 'potato',
         prices          => 'price',
         radii           => 'radius',
         scarfs          => 'scarf',
         selves          => 'self',
         series          => 'series',
         sheep           => 'sheep',
         shelves         => 'shelf',
         scissors        => 'scissors',
         species         => 'species',
         stimuli         => 'stimulus',
         strata          => 'stratum',
         syllabi         => 'syllabus',
         symposia        => 'symposium',
         syntheses       => 'synthesis',
         synopses        => 'synopsis',
         tableaux        => 'tableau',
         those           => 'that',
         theses          => 'thesis',
         thieves         => 'thief',
         these           => 'this',
         tomatoes        => 'tomato',
         teeth           => 'tooth',
         torpedoes       => 'torpedo',
         vertebrae       => 'vertebra',
         vetoes          => 'veto',
         vitae           => 'vita',
         watches         => 'watch',
         wives           => 'wife',
         wolves          => 'wolf',
         women           => 'woman',
         zeros           => 'zero',

         # words that we're not going to guess with our super elite c0de
         children => 'child',
         men      => 'man',
         geese    => 'goose',
         oxen     => 'ox',
         women    => 'woman',
         feet     => 'foot',
         teeth    => 'tooth', 
         people   => 'person',

         # weird endings I was too lazy to devise a scheme for
         bacteria  => 'bacterium',
         corpora   => 'corpus',
         criteria  => 'criterion',
         curricula => 'curriculum',
         genera    => 'genus',
         media     => 'medium',
         memoranda => 'memorandum',
         phenomena => 'phenomenon',
         strata    => 'stratum',

         # words that are the same whether plural or singular         
         deer      => 'deer',
         sheep     => 'sheep',
         species   => 'species',
         means     => 'means',
         offspring => 'offspring',
         series    => 'series',
         fish      => 'fish',
         media     => 'media',     # this is debateable but I'd rather avoid the heart ache.
         data      => 'data',
         bachelors => 'bachelors',
         masters   => 'masters',
         tuna      => 'tuna',

         # words that are always plural
         none       => 'none',
         pants      => 'pants',
         shorts     => 'shorts',
         police     => 'police',
         jeans      => 'jeans',
         clippers   => 'clippers',
         scissors   => 'scissors', 
         binoculars => 'binoculars',
         i          => 'I',
         thermos    => 'thermos',
	 English    => 'English',
	 physics    => 'physics',
         economics  => 'economics',
	 selfishness => 'selfishness',
         blues       => 'blues'
      );	
 
      $mappings = ohash(
         men      => 'man',
         es       => 'is',
         ices     => 'ix',
         ies      => 'y',
         eaux     => 'eau',
         ae       => 'a',
         ouse     => 'ice',       
         i        => 'us',
         s        => '');
   }

   return @($mappings, $words);
}

#
# kill suffix
#
sub noSuffix
{
   local('$strip');

   if ([$1 endsWith: "able"] || [$1 endsWith: "ible"])
   {
      $strip = left($1, -4);

      if ("$strip $+ ated" in $dictionary)
      {
         return "$strip $+ ated";
      }
      else if ("$strip $+ e" in $dictionary)
      {
         return "$strip $+ e";
      }
      else if ("$strip $+ y" in $dictionary)
      {
         return "$strip $+ y";
      }
      else if ($strip in $dictionary)
      {
         return $strip;
      }
   }

   return $1;
}

#
# convert a plural noun to a singular noun (fun stuff)
#
sub pluralToSingular
{
   local('$words $mappings');
   ($mappings, $words) = getWordMappings();

   if ($1 in $words)
   {
      return $words[$1];
   }
   else if ($1 in $verbs['plural'])
   {
      return $verbs['plural'][$1]['base'];
   }
   else
   {
      local('$e_plural $e_singular $temp');

      foreach $e_plural => $e_singular ($mappings)
      {
         if ([$1 endsWith: $e_plural])
         {
            $temp = substr($1, 0, -1 * strlen($e_plural)) . $e_singular;

            if ($temp in $dictionary)
            {
               return $temp;
            }
         }
      }
   }

   return $1;
}
