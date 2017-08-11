sub loadDicts
{
   if (-isDir $1)
   {
      map($this, filter({ return iff(!-isHidden $1, $1); }, ls($1)));
   }
   else
   {
      loadDict($1, \%dictionary);
   }
}

sub loadDict
{
   local('$handle $word');
   $handle = openf($1);
   map(lambda({ %dictionary[$1] = $file; }, \%dictionary, $file => getFileName($1)), split("\n", readb($handle, -1)));
   closef($handle);
}

sub extendDictionary
{
   local('$handle $word');
   $handle = openf($2);
   while $word (readln($handle))
   {
      $1[$word] = 1;
   }
   closef($handle);
}

sub fixDictionary
{
   local('$handle $word');
   $handle = openf("data/misspelled.txt");
   while $word (readln($handle))
   { 
      $1[$word] = $null;
   }
   size($1);
}

sub dictionary
{
   this('$dictionary');
   if ($dictionary is $null)
   {
      local('$handle $word $1'); 

      $dictionary = %();

      extendDictionary($dictionary, iff($1 is $null, 'models/dictionary.txt', $1) );

      $dictionary[','] = 1; # this is a hack until the corpus is rebuilt with comma's
      $dictionary['-'] = 1; 
      $dictionary['--'] = 1; 
      $dictionary['('] = 1; 
      $dictionary[')'] = 1; 
      $dictionary['/'] = 1;
      $dictionary[';'] = 1;
      $dictionary[':'] = 1;
      $dictionary['['] = 1;
      $dictionary[']'] = 1;
      $dictionary['http://'] = 1;
      $dictionary['https://'] = 1;

      warn("Dictionary loaded: " . size($dictionary) . " words");
   }
   return $dictionary;
}

#
# make a trie out of the dictionary
#
sub trie
{
   local('%trie $word $whocares $x $root $prefix');
   if (islowmem() eq "true") 
   {
      return %();
   }

   %trie = %(word => '', prefix => '', branches => %());

   foreach $word => $whocares ($1)
   {
      if ($word !isin '()[];:/,---')
      {
         $root = %trie;

         for ($x = 0; $x < strlen($word); $x++)
         {
            if (charAt($word, $x) !in $root['branches'])
            {
               $root['branches'][charAt($word, $x)] = %(prefix => substr($word, 0, $x), word => '', branches => %());
            }
            $root = $root['branches'][charAt($word, $x)];
         }

         $root['word'] = $word;
      }
   }
   return %trie;
}

# edits1(trie, word, @(), edits)
sub editst2
{
   local('$x $root $word $branch');

#   warn("Prefix: " . $1['prefix'] . " - $2 - $4");

   if (strlen($2) == 0 && $4 >= 0 && $1['word'] ne '')
   {
      $3[$1['word']] = 1;
   }

   if ($4 >= 1)
   {
      # deletion. [remove the current letter, and try it on the current branch--see what happens]

      if (strlen($2) > 1)
      {
         editst($1, substr($2, 1), $3, $4 - 1);
      }
      else
      {
         editst($1, "", $3, $4 - 1);
      }

      # insertion. [pass the current word, no changes, to each of the branches for processing]

      foreach $word => $branch ($1['branches'])
      {
         editst($branch, $2, $3, $4 - 1);
      }

      # substitution. [pass the current word, sans first letter, to each of the branches for processing]

      foreach $word => $branch ($1['branches'])
      {
         if (strlen($2) > 1)
         {
            editst($branch, substr($2, 1), $3, $4 - 1);
         }
         else
         {
             editst($branch, "", $3, $4 - 1);
         }
      }

      # transposition. [swap the first and second letters

      if (strlen($2) > 2)
      {
         editst($1, charAt($2, 1) . charAt($2, 0) . substr($2, 2), $3, $4 - 1);
      }
      else if (strlen($2) == 2)
      {
         editst($1, charAt($2, 1) . charAt($2, 0), $3, $4 - 1);
      }
   }

   # move on to the next letter. (no edits have happened)

   if (strlen($2) >= 1 && charAt($2, 0) in $1['branches'])
   {
      if (strlen($2) > 1)
      {
         editst($1['branches'][charAt($2, 0)], substr($2, 1), $3, $4);
      }
      else if (strlen($2) == 1)
      {
         editst($1['branches'][charAt($2, 0)], "", $3, $4);
      }
   }

   return keys($3);
}

sub islowmem 
{
   return systemProperties()["atd.lowmem"];
}

sub get_language_model
{
   local('$handle $data $1 $pool $count');

   if (islowmem() eq "true" && $1 is $null) 
   { 
      $handle = openf("models/stringpool.bin");
      $pool   = readObject($handle);
      $count  = readObject($handle);
      closef($handle);

      $data = [new org.dashnine.preditor.LanguageModelSmall: $pool, $count, [new java.io.File: "models/model.zip"]];
   }
   else   
   {
      $handle = openf(    iff($1 !is $null, $1, "models/model.bin")  );
      $data = readObject($handle);
      closef($handle);
   }

   [System gc];

   return $data;
}
