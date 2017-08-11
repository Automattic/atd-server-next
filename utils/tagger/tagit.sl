# this script simply tags sentences in a file.  it assumes each setence is on a line by itself.

include("lib/engine.sl");
include("utils/rules/rules.sl");

sub initAll
{
   global('$__SCRIPT__ $model $rules $dictionary $network $dsize %edits $hnetwork $account $usage $endings $lexdb $trigrams $verbs');
   $model      = get_language_model();
   $dsize      = size($dictionary);
   $hnetwork   = get_network("hnetwork.bin");
   $verbs      = loadVerbData();
   initTaggerModels();
}

sub main
{
   local('$handle $sentence @results @past');

   initAll();

   $handle = openf($1);
   while $sentence (readln($handle))
   {
      println(taggerToString(taggerWithTrigrams(splitIntoWords($sentence))));
   }
} 

invoke(&main, @ARGV);
