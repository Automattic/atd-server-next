debug(7 | 34);

sub process
{
   local('@words $entry $previous $current $next');

   $1 = [$1 trim];
   if ($1 !ismatch '[A-Z][A-Za-z\'\,0-9 ]*?[\.\?\!]')
   {
      return;
   }

   @words = splitIntoWords($1);

   if (size(@words) < 3)
   {
      return;
   }

#   foreach $entry (@words)
#   {
#      if (%dictionary[$entry] is $null)
#      {
#         return;
#      }
#   }

#    println($output, lc(join(" ", @words)) );
    println($output, join(" ", @words) );
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
}

sub main
{
   # setup our file that we're going to dump the output to.
   global('$output');
   $output = openf("> $+ $2");
   
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

invoke(&main, @ARGV);
