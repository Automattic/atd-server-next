debug(7 | 34);

import java.util.List;
import java.io.BufferedReader;
import java.io.FileReader;

import edu.stanford.nlp.ling.Sentence from: stanford-postagger-2008-09-28.jar;
import edu.stanford.nlp.ling.TaggedWord from: stanford-postagger-2008-09-28.jar;
import edu.stanford.nlp.ling.HasWord from: stanford-postagger-2008-09-28.jar;
import edu.stanford.nlp.tagger.maxent.MaxentTagger from: stanford-postagger-2008-09-28.jar;

global('$x $semaphore $handle $file @array');

$semaphore = semaphore();
$handle = openf(@ARGV[1]);
$file = @ARGV[0];

sub doit
{
   local('$taggedLine $tagger $text $sentence');

   $tagger = [new MaxentTagger: $file];

   while $text (readln($handle))
   {
      $sentence = [Sentence toSentence: cast(split('\s+', strrep($text, "'", " '")), ^String)];
      $taggedLine = [$tagger tagSentence: $sentence];
      println([$taggedLine toString: 0]);
   }
}

doit();
