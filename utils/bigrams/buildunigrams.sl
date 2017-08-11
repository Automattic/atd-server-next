#
# code to load wordlists.
# we use this here because this code actually builds the corpus.
#
# java -jar sleep.jar buildunigrams.sl corpus/ outputfile.bin

import org.dashnine.preditor.* from: 'lib/spellutils.jar';

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
      [$model addUnigram: $next];
      @words = sublist(@words, 1);
   }

   [$model addUnigram: '0END.0'];
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
   map({ map(&process, $1); }, @paragraphs);
   warn("$1 complete");
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

   local('$handle');

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

invoke(&main, @ARGV);
