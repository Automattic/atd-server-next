#
# generate statistics about a datset to evaluate writing quality
#
debug(7 | 34);

include("lib/quality.sl");
include("lib/engine.sl");

global('$__SCRIPT__ $model $rules $dictionary $network $dsize %edits $hnetwork $account $usage $endings $lexdb $trigrams $verbs $locks $trie %common');

$model      = get_language_model();
$dictionary = dictionary();
$rules      = get_rules();
$network    = get_network("cnetwork.bin");
$hnetwork   = get_network("hnetwork.bin");
%edits      = initEdits();
$dsize      = size($dictionary);
$verbs      = loadVerbData();
%common     = loadCommonWords();
initTaggerModels();

sub report
{
   local('@keys $metric $words $sentences $a $b $key');

   @keys = sort({ return lc($1) cmp lc($2); }, keys($2));

   $words = double($2['words']);
   $sentences = double($2['sentences']);
  
   foreach $key (@keys)
   {
      $metric = double($2[$key]);
      $a      = ($metric / $words) * 100.0;
      $b      = ($metric / $sentences) * 100.0;
      println("$[20]1 : $[30]key : $[10]metric $[25]a $[25]b");
   }
}

sub checkDocument
{
   local('$data %stats $start');
   
   $start = ticks();

   # strip HTML please
   $data = strrep($2, '&nbsp;', ' ', '<br>', "\n", '<p>', "\n", '<span>', "\n", '&quote;', '"', '&amp;', '&');
   $data = replace($data, '(<[^>]*?>)', '');
    
   %stats = processDocumentQuality($data);
   report(getFileName($1), %stats);

   println("Time: " . (ticks() - $start) . "ms");
}

sub main
{
   local('$handle $data');
   $handle = openf($1);
   $data = readb($handle, -1);
   closef($handle);

   checkDocument($1, $data);   
}

invoke(&main, @ARGV)
