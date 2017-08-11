#
# process through corpus, our goal is to associate all misspelt words with a sentence.
#
# java -jar sleep.jar gen.sl corpus_file wordfile filetowriteto
#
# wordfile must be in bad\ngood\n order
#

debug(7 | 34);

sub getthree
{
   local('@words');
   @words = copy($1);
   add(@words, '0BEGIN.0');
   push(@words, '0END.0');

   while (size(@words) >= 3)
   {
      yield sublist(@words, 0, 3);
      @words = sublist(@words, 1);
   }
}

sub process
{
   local('@words $entry $previous $current $next');

   $1 = [$1 trim];
   if ($1 !ismatch '[A-Z][A-Za-z\' ]*?[\.\?\!]')
   {
      return;
   }

   @words = splitIntoWords($1);

   while $entry (getthree(@words))
   {
      ($previous, $current, $next) = $entry;

      if (%words[$current] !is $null && %dictionary[$previous] !is $null && %dictionary[$next] !is $null && %counts[$current] < 1)
      {
         println($output, "$previous * $next $+ |" . join(", ", @($current, rand(%dataset[$current]))) );
         %counts[$current] += 1;
      }
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

   include("lib/nlp.sl");
   include("lib/dictionary.sl");
   global('%dictionary');
   %dictionary = dictionary();
   %dictionary["0BEGIN.0"] = 1;
   %dictionary["0END.0"] = 1;

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
