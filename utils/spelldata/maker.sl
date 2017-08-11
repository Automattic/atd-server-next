# 
# This is a script to generate an AtD test corpus from a rule file (assumes you used torules.sl or something similar to generate the file)
#
# java -jar utils/rules/maker.sl <rule file> <sentences file>
#
# <rule file> format:
#
# correct text|word=wrong text
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

      if (size(@past) == 1)
      {
          foreach $index => $r (@past)
          {
             local('$rule $text $path $context @suggestions');
             ($rule, $text, $path, $context, @suggestions) = $r;
            
             %count[$rule['word']] += 1;

             if (%count[$rule['word']] < 5)
             {
                println(strrep($sentence, " $text ", ' * ') . '|' . $rule['word'] . ', ' . iff($rule['options'] ne "", $rule['options'], $text) . '|' . $text);
             }
          }
      }
   }
} 

invoke(&main, @ARGV);
