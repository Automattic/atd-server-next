#
# code to load wordlists.
# we use this here because this code actually builds the corpus.
#
# java -jar sleep.jar buildcorpus.sl corpus model wordlists homophones

import org.dashnine.preditor.* from: 'lib/spellutils.jar';

sub loadHomophones
{
   local('$handle $text $word $words %homophones');

   $handle = openf($1);
   while $text (readln($handle))
   {
      $words = split(', ', $text);
      foreach $word ($words)
      {
         $word = [$word trim];
         %homophones[$word] = 1;
      }
   }
 
   if ($1 eq "data/rules/homophonedb.txt")
   {
      local('@special');
      @special = @('their', 'there', 'they\'re', 'it\'s', 'its', 'where', 'were', 'then', 'than');

      foreach $word (@special)
      {
         %homophones[$word] = 1;
      }
   }

   return %homophones;
}

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
   map(lambda({ %dictionary[$1] = 1; }, \%dictionary), readAll($handle));
   closef($handle);
}

sub dictionary
{
   this('$dictionary');
   if ($dictionary is $null)
   {
      $dictionary = %();
      [lambda(&loadDicts, %dictionary => $dictionary) : $1];

      warn("Dictionary loaded: " . [[$dictionary getData] size] . " words");

      # add punctuation chars here

      $dictionary[","] = 1; # make sure commas are in the wordlist
      $dictionary["("] = 1; # make sure commas are in the wordlist
      $dictionary[")"] = 1; # make sure commas are in the wordlist
      $dictionary["["] = 1; # make sure commas are in the wordlist
      $dictionary["]"] = 1; # make sure commas are in the wordlist
      $dictionary[";"] = 1; # make sure commas are in the wordlist
      $dictionary[":"] = 1; # make sure commas are in the wordlist
   }
   return $dictionary;
}

#
# tool to build a corpus.  <3
#

debug(7 | 34);

sub process
{
   local('@words $head $next $previous');

   @words = splitIntoWords($1);
   add(@words, '0BEGIN.0', 0);

   [$model addUnigram: '0BEGIN.0'];

   while (size(@words) > 1)
   {
      ($head, $next) = @words;
      if ($head in %dictionary && $next in %dictionary)
      {
         [$model addUnigram: $next];
         [$model addBigram: $head, $next];

         if ($next in %homophones && $previous !is $null && $previous in %dictionary)
         {
            [$model addTrigram: $previous, $head, $next];
         }
         else if ($previous in %homophones && $next !is $null)
         {
            [$model addTrigram: $previous, $head, $next];
         }
      }
      @words = sublist(@words, 1);
      $previous = $head;
   }

   $head = @words[0];
   if ($head in %dictionary)
   {
      [$model addUnigram: '0END.0'];
      [$model addBigram: $head, '0END.0'];
   }
}

sub processFile
{
   local('$handle $key $data $text @paragraphs');

   # read in our corpus.
   $handle = openf($1);
   $text   = stripHTML(join("\n", readAll($handle)));
   closef($handle);

   # start processing it?!?
   @paragraphs = splitByParagraph($text);
   map({ map({ map(&process, splitIntoClauses($1)); }, $1); }, @paragraphs);
}

sub agent
{
   local('$next $key $data $size $ticks $lsize $lang');

   include("lib/nlp.sl");

   $lang = systemProperties()["atd.lang"];
   if ($lang ne "" && -exists "lang/ $+ $lang $+ /load.sl")
   {
      include("lang/ $+ $lang $+ /load.sl");
   }
   
   $next = @files[0];
   removeAt(@files, 0);
   $size = size(@files);

   println("ready!");

   while ($next !is $null)
   {
      processFile($next);
      $next = @files[0];
      @files = sublist(@files, 1);
   }
}

sub main
{
   global('%dictionary @files %homophones $model $lock');

   local('$handle $1 $2 $3 $4');

   if (-exists $2) 
   {
      $handle = openf($2);
      $model = readObject($handle);
      closef($handle);
   }
   else
   {
      $model = [new LanguageModel];
   }

   %dictionary = dictionary($3);
   %dictionary["0BEGIN.0"] = 1;

   if ($4 !is $null && -exists $4)
   {
      %homophones = loadHomophones($4);
   }

   # collect list of files.
   [{
      if (-isDir $1)
      {
         map($this, ls($1));
      }
      else if ("*Image*.html" !iswm $1 && "*User*.html" !iswm $1)
      {
         push(@files, $1);
      }
    }: $1];

   local('@agents @store $index $value $threads');

   $threads = 8;

   @store = @(@(), @(), @(), @(), @(), @(), @(), @());

   foreach $index => $value (@files)
   {
      push(@store[$index % $threads], $value);
   }

   for ($index = 0; $index < $threads; $index++)
   {
      push(@agents, fork(&agent, @files => copy(@store[$index]), \$model, \%homophones, \%dictionary));
   }

   foreach $index => $value (@agents)
   {
      wait($value);
      warn("Agent $index complete");
   }

   # save model
   $handle = openf("> $+ $2");
   writeObject($handle, $model);
   closef($handle);

   println("Done!");
}

if (size(@ARGV) == 1)
{
   push(@ARGV, 'models/model.bin');
   push(@ARGV, 'data/wordlists');
   push(@ARGV, 'data/rules/homophonedb.txt');
}

invoke(&main, @ARGV);
