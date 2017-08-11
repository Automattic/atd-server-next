#
# Analyze a text file containing raw text data and show the top words not in the current wordlist data
#
#

sub loadWordlists
{
   if (-isDir $1)
   {
      map($this, ls($1));
   }
   else
   {
      loadWordlist($1, \%wordlist);
   }
}

sub loadWordlist
{
   local('$handle $word');
   $handle = openf($1);
   map(lambda({ %wordlist[$1] = 1; }, \%wordlist), split("\n", readb($handle, -1)));
   closef($handle);
}

sub wordlists
{
   this('$dictionary');
   if ($dictionary is $null)
   {
      $dictionary = %();
      [lambda(&loadWordlists, %wordlist => $dictionary) : "data/wordlists"];

      # add punctuation chars here

#      warn("Loaded: " . size($dictionary) . " words");

      $dictionary[","] = 1; # make sure commas are in the wordlist
   }
   return $dictionary;
}

#
# tool to build a corpus.  <3
#

debug(7 | 34);

sub process
{
   local('@words $head $next');

   @words = splitIntoWords($1);

   while (size(@words) > 1)
   {
      ($next) = @words;
 
      if ($next !in %wordlists && lc($next) !in %wordlists && !-isnumber $next)
      {
         %nots[$next] += 1;
      }

      @words = sublist(@words, 1);
   }
}

sub processFile
{
   local('$handle $key $data $text @paragraphs');

   # read in our corpus.
   $handle = openf($1);
   $text   = replace(readb($handle, -1), '<[^>]*?>', '');
   closef($handle);

   # start processing it?!?
   @paragraphs = splitByParagraph($text);
   map({ map({ map(&process, splitIntoClauses($1)); }, $1); }, @paragraphs);
}

sub main
{
   global('%wordlists %dictionary @files %current %nots');

   include("lib/nlp.sl");
   include("lib/dictionary.sl");

   %wordlists  = wordlists();

   processFile(@ARGV[0]);

   local('@words $word');

   # sort everything...

   @words = sort({ return %nots[$2] <=> %nots[$1]; }, filter(lambda({ return iff($min == 0 || %nots[$1] > $min, $1); }, $min => $2), keys(%nots)));

   foreach $word (@words)
   {
      if (($2 == 0 || %nots[$word] > $2))
      {
         if ($3 eq "")
         {
             println("$[50]word ... " . %nots[$word]);
         }
         else
         {
             println($word);
         }
      }
   }
}

invoke(&main, @ARGV);
