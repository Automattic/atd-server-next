#
# this is a script to run unit tests and calculute the effectiveness of the 
# preditor engine
#

debug(debug() | 7 | 34);

map({ iff('*.sl' iswm $1, include($1)); }, ls('utils/common'));

#include("tests/includes/score.sl");
#include("tests/includes/spelltests.sl");
#include("tests/includes/utils.sl");
#include("tests/includes/spellcontext.sl");

include("lib/engine.sl");
include("lib/object.sl");
include("lib/tagger.sl");

# preamble to set all this up
global('$__SCRIPT__ $model $rules $dictionary $dsize $biasdb $trie %edits');
$model      = get_language_model();
$rules      = get_rules();
$dictionary = dictionary();
fixDictionary($dictionary);
$trie       = trie($dictionary);
$dsize      = size($dictionary);
#$biasdb     = [{ local('$handle $o'); $handle = openf("models/homobias.bin"); $o = readObject($handle); closef($handle); return $o; }];
%edits      = initEdits(ohasha());
initTaggerModels();

import org.dashnine.preditor.SpellingUtils from: lib/spellutils.jar;
setField(^SpellingUtils, noWordSeparation => 1);

# makeTest("network file", "criteria", "desc")
inline makeNTest
{
   $score = newObject("score", $3);
   push(@scores, $score);
   push(@args, lambda(&NeuralNetworkScore, \$score, $network => get_network($1), $criteriaf => criteria($2)));
}

sub testHomophonesPOS
{                  
   loopHomophonesPOS($3, newObject("hotest", $1, $2, $3, $4));
}

sub testHomophones
{
   local('$network $criterf $entry $sentence $correct $wrongs $wrong @r $score $previous $next $comf $acc $s $t $cavg $wave $cmean $wmean @c @w $ch $cl $wh $wl $wrong $correct $s $acc $wrongs $score2 $score1 @temp');

   $score1  = newObject("score", "Correct   $4");
   $score2  = newObject("score", "Wrong     $4");
   $score   = newObject("score", "Composite $4");
   $network = get_network($1);
   $criterf = criteria($2);

   while $entry (sentences($3))
   {
      ($sentence, $correct, $wrongs) = $entry;
      ($previous, $next) = split('\\*', $sentence);      
      $previous = split('\\s+', [$previous trim])[-1];
      $previous = iff($previous eq "", '0BEGIN.0', $previous);
      $next     = split('\\s+', [$next trim])[0];
      $next     = iff($next eq "" || $next ismatch '[\\.!?]', '0END.0', $next);
      $next     = iff(charAt($next, -1) ismatch '[\\.!?]', substr($next, 0, -1), $next);

      push($wrongs, $correct);

      foreach $wrong ($wrongs)
      {
         @temp = checkHomophone($network, $wrong, copy($wrongs), $previous, $next);

         if (size(@temp) == 0)
         {
            @temp[0] = $wrong;
         }

         if (@temp[0] eq $correct)
         {
            if ($3 eq "ho_special.txt")
            {
               warn(":) $previous $wrong $next -> " . @temp);
            }

            [iff($wrong eq $correct, $score1, $score2) correct];
            [$score correct];
         }
         else
         {
            if ($wrong eq $correct)
            {
               if ($3 eq "ho_special.txt") 
               { 
                   warn("F+ $previous $wrong $next -> " . @temp);
                   warn("?cp " . Pbigram1($previous, $correct));
                   warn("?cn " . Pbigram2($correct, $next));
                   warn("?tp " . Pbigram1($previous, @temp[0]));
                   warn("?tn " . Pbigram2(@temp[0], $next));
               }
               [$score1 falsePositive];
               [$score falsePositive];
            }
            else
            {  
               if ($3 eq "ho_special.txt") 
               { 
                   warn("F- $previous $wrong $next -> " . @temp); 
               }
               [$score2 falseNegative];
               [$score falseNegative];
            }
         }
         [$score record];
         [iff($wrong eq $correct, $score1, $score2) record];
      }
   }

   [$score1 print];
   [$score2 print];
   [$score print];
   println("-" x 30);
}

sub distance
{
#   (@_) *= 1000.0;
   return sqrt( (($1 ** 2.0) - ($2 ** 2.0)) );
}

inline makeTest
{
   $score = newObject("score", $2);
   push(@scores, $score);
   push(@args, lambda($1, \$score));
}

sub runSpellingTest
{
   println("========== $[20]1 =========="); 

   local('$score @args @scores $file');
   push(@args, $1);

   makeNTest("network3f.bin", @("distance", "frequency", "firstLetter"), "3-factor");
   makeNTest("network3p.bin", @("distance", "probability", "firstLetter"), "3-factor w/ p");
#   makeNTest("network2pd.bin", @("distance", "probability"), "2-factor w/ p");
#   makeNTest("network1p.bin", @("probability"), "1-factor w/ p");
#   makeNTest("network3pf.bin", @("distance", "probability", "firstLetter", "frequency"), "all factors");
#   makeNTest("network2p.bin", @("probability", "frequency"), "p/f mixed");
#   makeTest(&RandomGuess, "Random Guess");
#   makeTest(&CombineFreqEdit, "Combined Freq/Edit");

   invoke(&testCorrectionsNoContext, @args);

   foreach $score (@scores)
   {
      [$score print];
   }
}

sub testHomophonesEXP
{                  
   loopHomophonesPOS("ho_test_wp_pos_context.txt", newObject("exp", $1, $2));
}

sub testHomophonesByWord
{                  
   loopHomophonesPOS("ho_fneg_gutenberg_pos_context.txt", newObject("byword", $1, $2, $3, $4));
}

sub runSpellingContextTest
{
   println("********** $[20]1 **********");

   local('$score @args @scores $file');
   push(@args, $1);
 
   # setup tests here.

   makeNTest("cnetwork.bin", @("distance", "pref", "postf", "firstLetter"), "Dist/Pre/Post/FL");
#   makeNTest("cnetwork2.bin", @("distance", "pref", "postf", "probability", "firstLetter"), "Dist/Pre/Post/Prob/FL");
#   makeNTest("cnetwork3.bin", @("distance", "pref", "postf", "firstLetter", "phonetic", "transpose"), "Pre/Post/FL/ph/tr");
#   makeNTest("cnetwork4.bin", @("distance", "pref", "postf", "firstLetter", "phonetic"), "Pre/Post/FL/ph");
#   makeNTest("cnetwork5.bin", @("distance", "pref", "postf", "firstLetter", "transpose"), "Pre/Post/FL/tr");

   makeTest(&RandomGuess, "Random Guess");
   makeTest(&CombineFreqEdit, "Combined Freq/Edit");

   invoke(&testCorrectionsContext, @args);

   foreach $score (@scores)
   {
      [$score print];
   }
}

# test datasets for no context
#runSpellingTest('sp_test_aspell_nocontext.txt');
#runSpellingTest('sp_test_wpcm_nocontext.txt');
#runSpellingTest("tests1.txt");
#runSpellingTest("tests2.txt");
#runSpellingTest("train.txt");
#runSpellingTest("spnocontext.txt");

# test datasets for contextual data
#runSpellingContextTest("sp_test_wp_context1.txt");
#runSpellingContextTest("sp_test_wp_context2.txt");
#runSpellingContextTest("sp_test_gutenberg_context1.txt");
#runSpellingContextTest("sp_test_gutenberg_context2.txt");

#runSpellingContextTest("sp_train_gutenberg_context.txt");
#runSpellingContextTest("sptestcontext.txt");
#runSpellingContextTest("sptestcontext2.txt");

#testSpellingContext("spcontext.txt"); # project gutenberg data
#runSpellingContextTest("sptraincontext2.txt");
#runSpellingContextTest("sptraincontext.txt");

sub runHomophoneTests
{
#   testHomophones("hnetwork.bin", @("pref", "postf", "probability"), "sphomophones1.txt", "Homophone Test");
#   testHomophones("hnetwork.bin", @("pref", "postf", "probability"), "sphomophones2.txt", "Homophone Test");
#   testHomophones("hnetwork.bin", @("pref", "postf", "probability"), "ho_test_gutenberg_context.txt", "Homophone Test (Gutenberg)");
#   testHomophones("hnetwork.bin", @("pref", "postf", "probability"), "ho_test_wp_context.txt", "Homophone Test (Wikipedia)");

   testHomophonesPOS("hnetwork.bin", @("pref", "postf", "probability"), "ho_test_gutenberg_pos_context.txt", "original (Gutenberg)");
   testHomophonesPOS("hnetwork.bin", @("pref", "postf", "probability"), "ho_test_wp_pos_context.txt", "original (Wikipedia)");

   testHomophonesPOS("hnetwork2.bin", @("pref", "postf", "probability", "trigram"), "ho_test_gutenberg_pos_context.txt", "pref/postf/prob/trigram (Gutenberg)");
   testHomophonesPOS("hnetwork2.bin", @("pref", "postf", "probability", "trigram"), "ho_test_wp_pos_context.txt", "pref/postf/prob/trigram (Wikipedia)");

   testHomophonesPOS("hnetwork3.bin", @("postf", "probability", "trigram"), "ho_test_gutenberg_pos_context.txt", "postf/prob/trigram (Gutenberg)");
   testHomophonesPOS("hnetwork3.bin", @("postf", "probability", "trigram"), "ho_test_wp_pos_context.txt", "postf/prob/trigram (Wikipedia)");

   testHomophonesPOS("hnetwork4.bin", @("pref", "postf", "probability", "trigram", "trigram2"), "ho_test_gutenberg_pos_context.txt", "pref/postf/prob/trigram/trigram2 (Gutenberg)");
   testHomophonesPOS("hnetwork4.bin", @("pref", "postf", "probability", "trigram", "trigram2"), "ho_test_wp_pos_context.txt", "pref/postf/prob/trigram/trigram2 (Wikipedia)");
}

#testHomophonesPOS("hnetwork2.bin", @("pref", "postf", "probability", "pos"), "ho_test_wp_pos_context.txt", "pref/postf/prob");
#testHomophonesPOS("hnetwork3.bin", @("pref", "postf", "probability", "pos"), "ho_test_wp_pos_context.txt", "pref/postf/prob/pos");
#testHomophonesPOS("hnetwork4.bin", @("pref", "postf", "probability", "pos", "assoc"), "ho_test_wp_pos_context.txt", "pref/postf/prob/pos/assoc");
#testHomophonesPOS("hnetwork5.bin", @("pos", "assoc"), "ho_test_wp_pos_context.txt", "pos/assoc");
#testHomophonesPOS("hnetwork6.bin", @("pos"), "ho_test_wp_pos_context.txt", "pos");
##testHomophonesPOS("hnetwork7.bin", @("pos", "pref", "postf"), "ho_test_wp_pos_context.txt", "pos/pref/postf");
#testHomophonesPOS("hnetwork8.bin", @("pref", "postf"), "ho_test_wp_pos_context.txt", "pref/postf");
#testHomophonesPOS("hnetwork9.bin", @("assoc"), "ho_test_wp_pos_context.txt", "assoc");
#testHomophonesPOS("hnetwork2.bin", @(), "ho_test_wp_pos_context.txt", "NULL"); 
#testHomophonesEXP("hnetwork.bin", @("pref", "postf", "probability"));
#testHomophonesEXP("hnetwork2.bin", @("pref", "postf", "probability", "pos"));
#testHomophonesByWord("hnetwork2.bin", @("pref", "postf", "probability"), "", @());
#testHomophonesPOS("hnetwork.bin", @("pref", "postf", "probability"), "ho_test_wp_pos_context.txt", "original");
#testHomophonesPOS("hnetwork2.bin", @("pref", "postf", "pos"), "ho_test_wp_pos_context.txt", "pref/postf/prob");

invoke(function('&' . shift(@ARGV)), @ARGV);
