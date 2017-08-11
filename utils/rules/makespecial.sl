#
# this script extracts relevant irregular verbs from the internal data to allow us to create rules
#


include("lib/engine.sl");
include("utils/rules/rules.sl");

sub checkSentenceSpelling
{
}

sub initAll
{
   global('$__SCRIPT__ $model $rules $dictionary $network $dsize %edits $hnetwork $account $usage $endings $lexdb $trigrams $verbs');
   $model      = get_language_model();
   $dictionary = dictionary();
   $dsize      = size($dictionary);
   $hnetwork   = get_network("hnetwork.bin");
   $verbs      = loadVerbData();
   initTaggerModels();
}

sub main
{
   initAll();

   local('$key $value $base $past $participle @results @past @base');

   foreach $key => $value ($verbs['base'])
   {
      ($base, $past, $participle) = values($value, @("base", "past", "participle"));
      if ($past ne $participle)
      {
         push(@past, $past);
         push(@results, $past);
      }

      if ($base ne $participle && $base ne $past)
      {
         push(@base, $base);
         push(@results, $base);
      }
   }

   @results = filter({ return iff(count($1) > 2, $1, println("Killed $[20]1 " .  count($1))  ); }, @results);
   @past = filter({ return iff(count($1) > 2, $1); }, @past);
   @base = filter({ return iff(count($1) > 2, $1); }, @base);

   println("Total words: " . size(@results));
   println("==== RESULTS ====");
   println(join("|", sorta(@results)));
   println("==== PAST ====");
   println(join("|", sorta(@past)));
   println("==== BASE ====");
   println(join("|", sorta(@base)));
}

invoke(&main, @ARGV);
