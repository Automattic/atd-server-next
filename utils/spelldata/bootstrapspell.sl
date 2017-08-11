# 
# Walk through a corpus and find spelling errors and their corrections
#
# java [all the memory junk here] -jar lib/sleep.jar utils/spelldata/bootstrapspell.sl data/corpus_wikipedia
#

debug(7 | 34);

include("lib/engine.sl");

global('$model $dictionary $trie $rules $network $hnetwork %edits $dsize $old_suggest %words');

$model      = get_language_model();
$dictionary = dictionary();
$rules      = get_rules();
$trie       = trie($dictionary);
$network    = get_network("cnetwork.bin");
$hnetwork   = get_network("hnetwork2.bin");
%edits      = initEdits();
setRemovalPolicy(%edits, { return 1; });
$dsize      = size($dictionary);
initTaggerModels();

$old_suggest = function('&getSuggestionPool');

sub getSuggestionPool
{
   local('$error $dict $pre $next @suggests %scores'); 
   ($error, $dict, $pre, $next) = @_;

   if ($error ismatch '[a-z]+\'{0,1}[a-z]+' && $pre ne "" && $next ne "" && ($pre ne '0BEGIN.0' || $next ne '0END.0') && $pre ismatch '[a-zA-Z0-9\\.,]+' && $next ismatch '[a-zA-Z0-9\\.,]+')
#   if ($error in %words && $pre ne "" && $next ne "" && ($pre ne '0BEGIN.0' || $next ne '0END.0') && $pre ismatch '[a-zA-Z0-9\\.,]+' && $next ismatch '[a-zA-Z0-9\\.,]+')
   {
      (@suggests, %scores) = invoke($old_suggest, @_);

      if (size(@suggests) > 0 && %seen[@_] is $null)
      {
         println("$pre * $next $+ |" . @suggests[0] . ", $error $+ |" . %scores[@suggests[0]]);
         %seen[@_] = 1;
      }

      return @(@suggests, %scores);
   }

   return @(@(), %());
}

sub checkIt
{
   local('$handle $data');
   $handle = openf($1);
   $data = readb($handle, -1);
   closef($handle);
 
   $data = stripHTML($data);
  
   processDocument($data)

   local('@paragraphs $paragraph $sentence');
   @paragraphs = splitByParagraph($data);
   
   foreach $paragraph (@paragraphs)
   {
      foreach $sentence ($paragraph)
      {
         if ($sentence eq "")
         {
            continue;
         }

         checkSentenceSpelling(splitIntoWords($sentence), @results => @());
      }
   }

   [System gc];
}

sub main
{
  # collect list of files.
   [{    
      if (-isDir $1)
      {
         map($this, ls($1));
      }
      else if ("*Image*.html" !iswm $1 && "*User*.html" !iswm $1)
      {
         checkIt($1);
      }
    }: $1];
}

invoke(&main, @ARGV);
