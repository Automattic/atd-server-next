#
# process through corpus, our goal is to associate all misspelt words with a sentence.
#
# java -jar sleep.jar gen.sl corpus_file wordfile filetowriteto
#
# wordfile must be in bad\ngood\n order
#

debug(7 | 34);

sub process
{
   local('@words $head $next $count $candidate $prev $indict');

   $1 = [$1 trim];
   if ($1 !ismatch '[A-Z][A-Za-z\' ]*?[\.\?\!]')
   {
      return;
   }

   if ("we're" isin $1 || "they're" isin $1 || "it's" isin $1)
   {
      warn("Could be? $1");
   }

   @words = splitIntoWords($1);
   $count = 0;

   # make sure there is only one misspelling in this sentence.
   foreach $word (@words)
   {
      if (%words[$word] !is $null)
      {
         $candidate = $word;
         $count++;
      }

      if (%dictionary[$word] is $null)
      {
         $indict++;
      }
   }

   if ($count == 1 && size(@words) >= 3 && %counts[$candidate] < 10 && $indict == 0)
   {
      $change = replace($1, "\\b $+ $candidate $+ \\b", '*');   

      println($output, "$change $+ |" . join(", ", concat(@($candidate), %dataset[$candidate]) ));
      %counts[$candidate] += 1;
   }
   else if ("we're" isin $1 || "they're" isin $1 || "it's" isin $1)
   {
      warn("Could be? $1 - Nope: $count and " . %counts[$candidate] . " and $indict");
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
   map({ map(&process, $1); }, @paragraphs);

   #warn("Processed $1 $+ !");
}

sub main
{
   global('%dataset $goal %words %counts');

   # load the words we're interested in.
   local('$handle $text $good');

      $handle = openf($2);
      while $text (readln($handle))
      {
         $good = readln($handle);

         if (%dataset[$good] is $null) { %dataset[$good] = @(); }
         push(%dataset[$good], $text); 
         %words[$good] += 1;
      }
      closef($handle);

   $goal = size(%dataset);

   # setup our file that we're going to dump the output to.
   global('$output');
   $output = openf("> $+ $3");
   
   # ok go through all the junk parsing through the files.

   include("nlp.sl");
   include("dictionary.sl");
   global('%dictionary');
   %dictionary = dictionary();

   # collect list of files.
   [{
      if (-isDir $1)
      {
         map($this, ls($1));
      }
      else if ("*Image*.html" !iswm $1 && "*User*.html" !iswm $1)
      {
         processFile($1);
      }
    }: $1];


   closef($output);
   println("Done!");
}

assert size(@ARGV) == 3 : "java -jar sleep.jar corpus_data wordlist outputfile";

invoke(&main, @ARGV);
