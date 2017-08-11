#
# process through corpus, our goal is to associate all misspelt words with a sentence.
#
# java -jar sleep.jar gen.sl corpus_file wordfile filetowriteto
#
# wordfile must be in bad\ngood\n order
#

debug(7 | 34);

sub getnext
{
   local('@words');
   @words = copy($1);
   add(@words, @('0BEGIN.0', 'UNK'));
   push(@words, @('0END.0', 'UNK'));

   while (size(@words) >= 5)
   {
      yield sublist(@words, 0, 5);
      @words = sublist(@words, 1);
   }
}

sub process
{
   local('@words $entry $previous $current $next $pre2 $pre1 $next1 $next2');

   $1 = [$1 trim];
   if ($1 !ismatch '[A-Z][A-Za-z\'\,\- ]*?[\.\?\!]{0,1}')
   {
      return;
   }

   @words = taggerWithTrigrams(splitIntoWords($1));

   while $entry (getnext(@words))
   {
      ($pre2, $pre1, $current, $next1, $next2) = map({ return $1[0]; }, $entry);

      if (%words[$current] !is $null && %dictionary[$pre2] !is $null && %dictionary[$pre1] !is $null && %dictionary[$next1] !is $null && %dictionary[$next2] !is $null && %counts[$current] < $max)
      {
         ($pre2, $pre1, $current, $next1, $next2) = map({ return join('/', $1); }, $entry);

         println($output, "$pre2 $pre1 * $next1 $next2 $+ |" . join("; ", concat($current, %dataset[$entry[2][0]])) );
         %counts[$entry[2][0]] += 1;
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
   map(lambda({ map(lambda(&process, \$max), $1); }, \$max), @paragraphs);

   #warn("Processed $1 $+ !");
}

sub main
{
   global('%dataset $goal %words %counts');

   # load the words we're interested in.
   local('$handle $text $good');

      $handle = openf($1);
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
   include("lib/tagger.sl");

   global('%dictionary');
   %dictionary = dictionary();
   %dictionary["0BEGIN.0"] = 1;
   %dictionary["0END.0"] = 1;

   initTaggerModels();

   # collect list of files.
   [{
      if (-isDir $1)
      {
         map($this, ls($1));
      }
      else if ("*Image*.html" !iswm $1 && "*User*.html" !iswm $1)
      {
         processFile($1, \$max);
      }
    }: $2, $max => $4];


   closef($output);
   println("Done!");
}

assert size(@ARGV) == 4 : "java -jar sleep.jar corpus_data wordlist outputfile max_entries_per_word";

invoke(&main, @ARGV);
