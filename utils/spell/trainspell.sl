# 
# "train" a neural network to figure out which correction is best
#

debug(debug() | 7 | 34);

#include("tests/includes/utils.sl");
map({ iff('*.sl' iswm $1, include($1)); }, ls('utils/common'));

include("lib/object.sl");
include("lib/engine.sl");
include("lib/spellcheck.sl");
include("lib/neural.sl");
#include("tests/includes/spellcontext.sl");
#include("tests/includes/utils.sl");
include("lib/tagger.sl");

global('$__SCRIPT__ $model $rules $dictionary $dsize $trie %edits');          
$model      = get_language_model();
$rules      = get_rules();
$dictionary = dictionary();
$trie       = trie($dictionary);
$dsize      = size($dictionary);
initTaggerModels();
%edits      = initEdits(ohasha());

import org.dashnine.preditor.SpellingUtils from: lib/spellutils.jar;
setField(^SpellingUtils, noWordSeparation => 1);

sub trainNetwork
{
   local('$entry $bad $good @suggestions $suggestion $x $criteria');

   for ($x = 0; $x < 3; $x++)
   {
      while $entry (words($1))
      {
         ($bad, $good) = $entry;

         if ($dictionary[$good] !is $null && $dictionary[$bad] is $null)
         {
            @suggestions = %edits[$bad]; # save some time, why not.
                      # filterByDictionary($bad, $dictionary);
         
            foreach $suggestion (@suggestions)
            {
               $criteria = [$criteriaf: $bad, $suggestion, @suggestions];

               if ($suggestion eq $good)
               {
                  [$network trainquery: $criteria, %(result => 1.0)];
               }
               else
               {
                  [$network trainquery: $criteria, %(result => 0.0)];
               }
            }
         }
      }
      println("Iteration $x complete!");
   }

   println("Networked trained!");
}

sub trainme
{
   local('$suspect $correct @suggestions $suggestion $previous $next $criteria');
   ($suspect, $correct, @suggestions, $previous, $next) = @_;

   foreach $suggestion (@suggestions)
   {
      $criteria = [$criteriaf : $suspect, $suggestion, @suggestions, $previous, $next];
      [$network trainquery: $criteria, %(result => iff($suggestion eq $correct, 1.0, 0.0))];
#      warn("$correct -> $suggestion : $criteria");
   }

   #warn("Trained $previous ' $+ $suspect $+ ' $next -> $correct with " . size(@suggestions));
}

sub trainSpellcheckerContext
{
   local('$network @features $x');
   $network = newObject("nn", @("result"), $2);
   for ($x = 0; $x < 3; $x++)
   {
      testCorrectionsContext("sp_train_gutenberg_context.txt", lambda(&trainme, \$network, $criteriaf => criteria($2)));
      warn("Iteration $x complete");
   }
   save_network($1, $network);
   println("Done? $1");
}

#
# homobias
#
sub homobias::init
{
   this('%biasdb $network $criterf $criteria');

   $criterf  = criteria($2);
   $network  = get_network($1);
   $criteria = $2;
}

sub homobias::process
{
   local('$correct $wrong $wrongs $previous $next @temp %scores $ratio');
   ($correct, $wrong, $wrongs, $previous, $next) = @_;

   if ($wrong eq $correct)
   {
      (@temp, %scores) = checkAnyHomophone2($network, $wrong, copy($wrongs), $previous, $next, $criteriaf => $criterf);

      if (size(@temp) == 0)
      {
         @temp[0] = $wrong;
      }

      if (@temp[0] ne $correct)
      {
         $ratio = %scores[@temp[0]] / %scores[$correct];
#         %biasdb[$correct] += 1;
#         warn("FP! $correct (".%scores[$correct].") -> $wrongs = " . @temp[0] . "(" . %scores[@temp[0]] . ")");

         if ($ratio > %biasdb[$correct])
         {
            %biasdb[$correct] = $ratio;
         }
      }

   }
}

sub homobias::finish
{
   local('$key $value $handle');
   foreach $key => $value (%biasdb)
   {
      if ($value >= 30.0)
      {
         println("$[20]key $value");
      }
   }

   $handle = openf(">models/homobias.bin");
   writeObject($handle, %biasdb);
   closef($handle);

   warn("Model saved");
}

sub trainHomophonesBias
{
   local('$object');
   $object = newObject("homobias", $1, $2);
   loopHomophones("ho_fneg_gutenberg_pos_context.txt", $object);
#   loopHomophones("ho_special.txt", $object);
   [$object finish];
}

sub trainHomophonesByWord
{
   local('$object');
   $object = newObject("byword");
   loopHomophonesPOS("ho_fneg_gutenberg_pos_context.txt", $object);
   [$object save];
}

sub trainHomophonesPOS
{
   local('$x $entry $sentence $correct $wrongs $criterf $network $pre2 $pre1 $next $next2 $wrong $c $x $all $4');

   $criterf = criteria($2);
   $network = newObject("nn", @("result"), $2);

   for ($x = 0; $x < $3; $x++)
   {
      while $entry (sentences(iff($4, $4, "ho_train_gutenberg_pos_context.txt")))
      {
         ($sentence, $correct, $wrongs) = $entry;
         ($pre2, $pre1, $null, $next, $next2) = toTaggerForm(split(' ', $sentence));       

         if ($pre2[1] eq "UNK") { $pre2[1] = ""; }
         if ($pre1[1] eq "UNK") { $pre1[1] = ""; }

         foreach $wrong ($wrongs)
         {
             $c = [$criterf: $wrong, $wrong, $wrongs, $pre1[0], $next[0], @($pre2[1], $pre1[1]), $pre2[0], $next2[0]];
    #        warn("B: " . join(", ", @($wrong, $wrong, @(), $pre1[0], $next[0], @($pre2[1], $pre1[1]))) . " = " . $c);

            [$network trainquery: $c, %(result => 0.0)];
         }

         $correct = split('/', $correct);    
         $c = [$criterf: $correct[0], $correct[0], $wrongs, $pre1[0], $next[0], @($pre2[1], $pre1[1]), $pre2[0], $next2[0]];
   #      warn("G: " . join(", ", @($correct[0], $correct[0], @(), $pre1[0], $next[0], @($pre2[1], $pre1[1]))) . " = " . $c);

         [$network trainquery: $c, %(result => 1.0)];
      }
   }
   save_network($1, $network);
   println("Done? $1");
}

sub trainHomophones
{
   local('$entry $sentence $correct $wrongs $previous $next $criterf $network $x $wrong');

   $criterf = criteria($2);
   $network = newObject("nn", @("result"), $2);

   for ($x = 0; $x < 2; $x++)
   {
#      while $entry (sentences("sphomophones1.txt"))
      while $entry (sentences("ho_train_gutenberg_context.txt"))
#      while $entry (sentences("ho_test_wp_context.txt"))
      {
         ($sentence, $correct, $wrongs) = $entry;
         ($previous, $next) = split('\\*', $sentence);
         $previous = split('\\s+', [$previous trim])[-1];
         $previous = iff($previous eq "", '0BEGIN.0', $previous);
         $next     = split('\\s+', [$next trim])[0];
         $next     = iff($next eq "" || $next ismatch '[\\.!?]', '0END.0', $next);        
         $next     = iff(charAt($next, -1) ismatch '[\\.!?]', substr($next, 0, -1), $next);

         foreach $wrong ($wrongs)
         {
            [$network trainquery: [$criterf: $wrong, $wrong, @(), $previous, $next], %(result => 0.0)];
         }

         [$network trainquery: [$criterf : $correct, $correct, @(), $previous, $next], %(result => 1.0)];
      }
      println("Iteration $x complete");
   }
   save_network($1, $network);
   println("Done? $1");
}

sub save_network
{
   local('$handle');
   $handle = openf(">models/ $+ $1");
   writeObject($handle, $2);
   closef($handle);
}

sub trainSpellchecker
{
   local('$network @features');
   $network = newObject("nn", @("result"), $2);
   trainNetwork("train.txt", $criteriaf => criteria($2), \$network);
   save_network($1, $network);
}

sub trainNoContext
{
   # network3p.bin
   trainSpellchecker("network3p.bin", @("distance", "probability", "firstLetter"));

   # network3f.bin
   trainSpellchecker("network3f.bin", @("distance", "frequency", "firstLetter"));

   # network2p.bin - ala Norvig's corrector
#   trainSpellchecker("network2pd.bin", @("distance", "probability"));

   # networkp.bin
 #  trainSpellchecker("network1p.bin", @("probability"));

   # network4f.bin
  # trainSpellchecker("network3pf.bin", @("distance", "probability", "firstLetter", "frequency"));

   # networkpf.bin
  # trainSpellchecker("network2p.bin", @("probability", "frequency"));
}

sub trainWithContext
{
   trainSpellcheckerContext("cnetwork.bin", @("distance", "pref", "postf", "firstLetter"));
#   trainSpellcheckerContext("cnetwork2.bin", @("distance", "pref", "postf", "probability", "firstLetter"));
#   trainSpellcheckerContext("cnetwork3.bin", @("distance", "pref", "postf", "firstLetter", "phonetic", "transpose"));
#   trainSpellcheckerContext("cnetwork4.bin", @("distance", "pref", "postf", "firstLetter", "phonetic"));
#   trainSpellcheckerContext("cnetwork5.bin", @("distance", "pref", "postf", "firstLetter", "transpose"));
}

#trainNoContext();
#trainWithContext();

sub trainHomophoneModels
{
   trainHomophones("hnetwork.bin", @("pref", "postf", "probability"));
   trainHomophonesPOS("hnetwork2.bin", @("pref", "postf", "probability", "trigram"), 1);
   trainHomophonesPOS("hnetwork3.bin", @("postf", "probability", "trigram"), 1);
   trainHomophonesPOS("hnetwork4.bin", @("pref", "postf", "probability", "trigram", "trigram2"), 1);

   #trainHomophonesPOS("hnetwork4.bin", @("pref", "postf", "pos"), 1);
   #trainHomophonesPOS("hnetwork5.bin", @("pos", "assoc"), 1);
   #trainHomophonesPOS("hnetwork6.bin", @("pos", "posr"), 1);
   #trainHomophonesPOS("hnetwork8.bin", @("pref", "postf"), 20);
   #trainHomophonesPOS("hnetwork9.bin", @("assoc"), 1);
   #trainHomophonesBias("hnetwork.bin", @("pref", "postf", "probability"));
   #trainHomophonesPOS("hnetworka.bin", @("pref", "postf", "pos", "pos_unique"), 3);
   #trainHomophonesByWord();
   #trainHomophonesPOS("hnetwork2.bin", @("pos", "pref", "postf"), 3);
}

invoke(function('&' . shift(@ARGV)));
