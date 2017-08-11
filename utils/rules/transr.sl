# 
# this is a script to transform sentences in a corpus using rules from an AtD rule file
#
# java -jar utils/rules/testr.sl <rule file> <sentences file>
#
# <rule file> format:
#
# rule..|[key=value|...]
#
# note that key=value are parsed and dumped into a hash.  This information is used by the system to 
# filter out false positives and stuff.
#

include("lib/engine.sl");
include("utils/rules/rules.sl");

sub checkSentenceSpelling
{
}

setf('&score', let({
  local('$value');
  $value = invoke($oldf, @_);
  warn("Looking at: " . join("|", @_) . " = " . $value);
  return $value;
}, $oldf => &score));

sub initAll
{
   global('$__SCRIPT__ $model $rules $dictionary $network $dsize %edits $hnetwork $account $usage $endings $lexdb $trigrams $verbs');
   $model      = get_language_model();
   $dictionary = dictionary();
   $dsize      = size($dictionary);
   $hnetwork   = get_network("hnetwork4.bin");
   $verbs      = loadVerbData();
   initTaggerModels();
}

sub main
{
   local('$handle $sentence @results @past');

   initAll();

   if (function("& $+ $1") !is $null)
   {
      $rules = machine();
      invoke(function("& $+ $1"));
   }
   else
   {
      $rules = loadRules(machine(), $1, %());
   }

   $handle = openf($2);
   while $sentence (readln($handle))
   {
      @results = @();
      processSentence(\$sentence, \@results);

      @past = copy(@results);

      if (size(@past) > 0)
      {
#          println($sentence);
#          println(taggerToString(taggerWithTrigrams(splitIntoWords($sentence))));
          foreach $index => $r (@past)
          {
             local('$rule $text $path $context @suggestions');
             ($rule, $text, $path, $context, @suggestions) = $r;

             if ($r in @results)
             {
                $n = strrep($sentence, $text, @suggestions[0]);
                println($n);

                if ($n eq $sentence)
                {
                    println("===> $context $text => " . @suggestions);
                }

                break;
             }

             
         }

      }
   }
} 

invoke(&main, @ARGV);
