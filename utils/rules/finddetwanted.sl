#
# a tool to inspect the language model
#

import org.dashnine.preditor.* from: lib/spellutils.jar;
use(^SpellingUtils);

# misc junk
include("lib/dictionary.sl");
include("lib/tagger.sl");
global('$__SCRIPT__ $model $rules $dictionary $network $dsize %edits $hnetwork $account $usage $endings $lexdb $trigrams $verbs $lexdb @yes @no @determiners @adjectives @verbs');
$model      = get_language_model();
$dictionary = dictionary();
$dsize      = size($dictionary);
$lexdb      = loadModelObject("lexicon.bin");

global('@determiners %base');
@determiners = @('a', 'an', 'either', 'every', 'his', 'her', 'its', 'my', 'neither', 'one', 'our', 'that', 'the', 'this', 'their', 'your',
                 'A', 'An', 'Either', 'Every', 'His', 'Her', 'Its', 'My', 'Neither', 'One', 'Our', 'That', 'The', 'This', 'Their', 'Your');

%base = ohash();
setMissPolicy(%base, { return 1.0; });

# sort words correctly
foreach $word (filter({ return iff(lc($1) in $lexdb && count($1) > 50, $1); }, keys($dictionary)))
{
   $tag = findWordTag(%base, $lexdb[lc($word)]);
   if ($tag eq 'JJ') { push(@adjectives, $word); }
   else if ($tag eq 'VBP' || $tag eq 'VBZ') { push(@verbs, $word); }
}
push(@verbs, 'adds');
#@adjectives = filter({ return iff(lc($1) in $lexdb && count($1) > 50 && findWordTag(%base, $lexdb[lc($1)]) eq 'JJ', $1); }, keys($dictionary));

@no = @('anyone', 'sort', 'way', 'chance', 'conference', 'ground', 'maximum', 'habit', 'room', 'different', 'man', 'truth', 'difference', 'past', 'woman', 'purpose', 'winter', 'summer', 'leader', 'provision', 'fall', 'spring', 'east', 'west', 'north', 'south', 'matter', 'number', 'subject', 'result', 'head', 'governor', 'adoption', 'age', 'area', 'arm', 'autumn', 'ball', 'bank', 'battle', 'beginning', 'belief', 'book', 'border', 'boy', 'breath', 'chair', 'circle', 'coat', 'commitment', 'context', 'conversation', 'conviction', 'copyright', 'creation', 'desert', 'determination', 'direction', 'distinction', 'door', 'end', 'entrance', 'existence', 'experiment', 'eye', 'face', 'fact', 'father', 'forest', 'fortune', 'game', 'girl', 'hand', 'heart', 'hive', 'house', 'incident', 'invention', 'issue', 'key', 'kind', 'lack', 'letter', 'morning', 'mother', 'mountain', 'novel', 'object', 'occasion', 'opening', 'opposite', 'owner', 'page', 'point', 'priest', 'privilege', 'prospect', 'pursuit', 'question', 'railroad', 'replacement', 'resignation', 'rest', 'scope', 'selection', 'separation', 'shade', 'size', 'source', 'spirit', 'state', 'string', 'struggle', 'table', 'task', 'time', 'top', 'total', 'tournament', 'town', 'victim', 'vision', 'wall', 'wheel', 'wife', 'word', 'year', 'youth', 'flavor', 'day', 'ranking', 'choice', 'portion', 'fate', 'growth', 'uniform', 'position', 'expense', 'origin', 'shoulder', 'founder', 'member', 'teacher', 'passage', 'imagination', 'audience', 'goal', 'son', 'daughter', 'ruling', 'idea', 'survey', 'foot', 'professor', 'acquaintance', 'evening', 'morning', 'afternoon', 'night', 'quarter', 'mistake', 'dream');
@yes = split(' ', 'effort environment founder genre growth leader list photo picture population portion professor range ranking response stake suburb thing type understanding uniform view warning');
@yes = filter({ return iff($1 !in @no, $1); }, @yes);

sub scoreWordDeterminer 
{
   local('$determiner $score $adjective');

   foreach $determiner (@determiners)
   {
      $score += Pbigram2($determiner, $1);
   }
   return $score;
}

sub scoreWordVerb
{
   local('$score $verb');
   foreach $verb (@verbs) 
   {
      $score += Pbigram2($verb, $1);
#      $score += Pbigram2($adjective, $1);
   }
   return $score;
}

sub scoreWordAdjective
{
   local('$score $adjective');
   foreach $adjective (@adjectives) 
   {
      $score += %a[$adjective] * Pbigram2($adjective, $1);
#      $score += Pbigram2($adjective, $1);
   }
   return $score;
}

sub scoreWord 
{
   return scoreWordAdjective($1) + scoreWordDeterminer($1);
}

foreach $adj (@adjectives)
{
   %a[$adj] = scoreWordDeterminer($adj);
}

sub isCountable 
{
   local('$word');
   ($word) = @_;
#   return iff(count($word) > 500 && scoreWord($word) > 0.80, $1);
#   return iff(count($word) > 500 && lc($word) in $lexdb && findWordTag(%base, $lexdb[lc($word)]) eq 'NN' && count($word) > 500 && $word !in @no && scoreWord($word) > 0.25 && ((scoreWordVerb($word) < 0.0001) || scoreWord($word) > 0.90), $1);
   return iff (count($word) > 500 &&
               "$word $+ s" in $dictionary && 
               lc($word) in $lexdb && findWordTag(%base, $lexdb[lc($word)]) eq 'NN' && 
               $word !in @no &&
               scoreWordVerb($word) < 0.007 && scoreWord($word) > 0.50, $1); 
#   return iff ($word !in @no && count($word) > 500 && ($word in @yes || scoreWord($word) > 0.725), $1); 
}

@countable = filter(&isCountable, sorta(keys($dictionary)));
@countable = concat(@countable, @yes);
foreach $countw (@countable)
{
   ($aa, $dd, $vv, $cc) = @(scoreWordAdjective($countw), scoreWordDeterminer($countw), scoreWordVerb($countw), count($countw));
   println("$[20]countw $[20]aa $[20]dd $[20]vv $cc");
}

println(join('|', @countable));
