#
# this script creates a dictionary definitions file for AtD from the raw text of the public
# domain OPTED dictionary (Online Plain Text English Dictionary)
#
# Available at: http://msowww.anu.edu.au/~ralph/OPTED/
#
# Depends on:
#   data/rules/homophonedb.txt (list of words we want to create def file for)
#   
# Outputs to:
#   data/rules/definitions.txt (a word<tab>definition file)

debug(7 | 34);

sub loadWords
{
   local('$handle $words $text $word $def');
   $handle = openf("data/rules/homophonedb.txt");
   $words = split(',\s+', join(", ",readAll($handle)));
   closef($handle);

   $handle = openf("data/rules/homo/definitions.txt");
   while $text (readln($handle))
   {
      ($word, $def) = split('\t+', $text);
      push($words, $word);
      %alts[$word] = $def;
   }
   closef($handle);

   map({ $dictionary[$1] = 1; }, sort({ return lc($1) cmp lc($2); }, $words));
}

sub suckUpDictFile
{
   local('$handle $text $word $pos $definition $check');
   $handle = openf($1);
   while $text (readln($handle))
   {
      if ($text ismatch '<P><B>(.*?)</B> \(<I>(.*?)</I>\) (.*?)</P>')
      {
         ($word, $pos, $definition) = matched();
         if ("See*" iswm $definition || "Alt. of*" iswm $definition || "pl. of" iswm $definition || "of *" iswm $definition)
         {
            continue;
         }

         if ($word in $dictionary && strlen($dictionary[$word]) == 1)
         {
            $dictionary[$word] = $definition;
         }
         if (lc($word) in $dictionary && strlen($dictionary[lc($word)]) == 1)
         {
            $dictionary[lc($word)] = $definition;
         }

         $check = lc($word) . "s";
         if ($check in $dictionary && strlen($dictionary[$check]) == 1)
         {
            $dictionary[$check] = "Plural of " . lc($word) . ". " . $definition;
         }
      }
   }

   closef($handle);
}


sub main
{
  global('$dictionary %alts');
  $dictionary = ohash();
  loadWords();

  [{ 
     if (-isDir $1)
     {
        map($this, ls($1));
     }
     else
     {
        suckUpDictFile($1);
     }
   }: "data/OPTED"];

   local('$word $definition');

   foreach $word => $definition ($dictionary)
   {
      if ($definition eq "1" || "See*" iswm $definition || "Alt. of*" iswm $definition || "of *" iswm $definition)
      {
         [[System err] println: "Substituting: $word = " . %alts[$word]];
         $definition = uc(charAt(%alts[$word], 0)) . substr(%alts[$word], 1);
      }
      else
      {
         $definition = split(';', $definition)[0];
      }

      println("$word $+ \t $+ $definition");
   }
}

invoke(&main, @ARGV);
