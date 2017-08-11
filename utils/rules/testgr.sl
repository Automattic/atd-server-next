# 
# This is a script to test grammar rules.  It's fun stuff.
#
# java -jar utils/rules/testgr.sl <sentences file> [missing|wrong]
#

debug(7 | 34);

include("lib/engine.sl");
include("utils/rules/rules.sl");
include("utils/common/score.sl");

sub checkSentenceSpelling
{
}

sub initAll
{
   global('$__SCRIPT__ $model $rules $dictionary $network $dsize %edits $hnetwork $account $usage $endings $lexdb $trigrams $verbs');
   $model      = get_language_model();
   $dictionary = dictionary();
   $rules      = get_rules(); 
   $dsize      = size($dictionary);
   $hnetwork   = get_network("hnetwork4.bin");
   $verbs      = loadVerbData();
   initTaggerModels();
}

sub measure
{
   local('@results $options $correct $score $s_score $good $index $r @suggs $debug');
   (@results, $options, $correct, $score, $s_score, $debug) = @_;

   if (size(@results) > 0)
   {
      foreach $index => $r (@results)
      {
         local('$rule $text $path $context @suggestions');
         ($rule, $text, $path, $context, @suggestions) = $r;

         if (!-isarray @suggestions) { @suggestions = split(', ', @suggestions); }

         if ($text eq $options[0])
         {
            @suggs = filter(lambda({ return iff($1 in $options, 1); }, $options => sublist($options, 1)), @suggestions); 

            if (size(@suggs) > 0)
            {
               [$score correctSugg];
               [$s_score correctSugg];

               if ($correct in @suggestions)
               {
                  [$score correct];
                  [$s_score correct];
               }
            }
            else if ('wrong' isin $debug)
            {
               println("$wrong => $text");
               println("  - entry:   " . $entry);
               println("  - expect:  " . sublist($options, 1));
               println("  - options: " . @suggestions);
               println("  - " . $rule['category'] . ' = ' . $rule['rule'] );
            }
            $good = 1;
   
            [$s_score record];
         }
      }
   }

   if (!$good)
   {
      [$score falseNegative]; # move if $text eq options[1] never happens

       if ('missing' isin $debug)
       {
          println("$wrong => $text");
          println("  - entry:   " . $entry);
          println("  - expect:  " . sublist($options, 1));
       }
   }

   [$score record];
}

sub main
{
   local('$handle $sentence $entry @results $options $correct $wrong $score1 $score2 $2');

   $score1 = newObject('score', "Suggestion score for $1");
   $score2 = newObject('score', "Grammar score for $1");

   initAll();

   $handle = openf($1);
   while $entry (readln($handle))
   {
      ($sentence, $options, $correct) = split('\|', $entry);
      $options = split(', ', $options);

      $wrong = strrep($sentence, ' * ', " " . $options[0] . " ");

      @results = @();
      processSentence($sentence => $wrong, \@results);

      measure(@results, $options, $correct, $score2, $score1, $2, \$entry, \$wrong);
   }

   [$score1 print];
   [$score2 print];
} 

invoke(&main, @ARGV);
