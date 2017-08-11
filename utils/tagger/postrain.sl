#
# train various models related to the tagger. *uNF*
#

debug(debug() | 7 | 34);

include("lib/object.sl");
include("lib/tagger.sl");

sub train
{
   local('$handle $sentence $tokens $pre2 $pre1 $current $f $pfile');

   foreach $pfile (@ARGV)
   { 
      $handle = openf($pfile);
      while $sentence (readln($handle))
      {
         $tokens = map({ return split('/', $1); }, split(' ', $sentence));

         ($pre2, $pre1) = @(@("", ""), @("", ""));
         foreach $current ($tokens)
         {
            foreach $f (@_)
            {
               [$f train: $current, $pre1, $pre2];
            }          

            $pre2 = $pre1;
            $pre1 = $current;
         }
      }
   }

   foreach $f (@_)
   {
      [$f save];
   }
}

sub lexicon
{
   this('%lexicon');

   if ($0 eq "train")
   {
      local('$word $tag $pw1 $pw2 $t1 $t2');
      ($word, $tag) = $1; 
      %lexicon[$word][$tag] += 1;     
   }
   else
   {
      local('$word $tags $tag $count $total');

      # reprocess all the words and convert them into percentages
      foreach $word => $tags (%lexicon)
      {
         $total = 0.0;
         foreach $tag => $count ($tags)
         {
            $total += $count;
         }

         foreach $tag => $count ($tags)
         {
            $count /= $total;
         }
      }

      # dump the lexicon
      local('$handle');
      $handle = openf(">models/lexicon.bin");
      writeObject($handle, %lexicon);
      closef($handle);
      warn("lexicon saved!");  
   }
}

sub neural
{
   this('$network $trigrams $lexicon');

   if ($network is $null)
   {
      $network = newObject("nn", @("result"), @("trigram", "wordtag"));
      $trigrams = loadTrigramData();
      $lexicon  = loadLexiconData2();
   } 

   if ($0 eq "train")
   {
      local('$word $tag $pw1 $pw2 $t1 $t2 $tagv $value $base');
      ($word, $tag) = $1; 
      ($pw1, $t1) = $2;
      ($pw2, $t2) = $3;

      $base = $trigrams[$t2][$t1];

      foreach $tagv => $value ($lexicon[$word])
      {
#         warn("$t2 $t1 $tagv ( $+ $tag $+ ) for $word $+ : $+ $value = " .  %(trigram => iff($base !is $null && $base[$tagv] !is $null, $base[$tagv], 0.0), wordtag => $value) . " => " . %(result => iff($tag eq $tagv, 1.0, 0.0)));
         [$network trainquery: %(trigram => iff($base !is $null, $base[$tagv], 0.0), wordtag => $value), %(result => iff($tag eq $tagv, 1.0, 0.0))];
      }
   }
   else
   {
      local('$handle');
      $handle = openf(">models/network.bin");
      writeObject($handle, $network);
      closef($handle);
   }
}

sub trigrams
{
   this('%trigrams %trigramsr $counter');

   if ($0 eq "train")
   {
      local('$word $tag $pw1 $pw2 $t1 $t2');
      ($word, $tag) = $1; 
      ($pw1, $t1) = $2;
      ($pw2, $t2) = $3;
      
      %trigrams[$t2][$t1][$tag] += 1;
      %trigramsr[$t1][$tag][$t2] += 1;
      $counter++;
   }
   else
   {
      local('$ok $ov $ik $iv $total $count $view');

      foreach $view (@(%trigrams, %trigramsr))
      {
         foreach $ok => $ov (%trigrams)
         {
            foreach $ik => $iv ($ov)
            {
               $total = 0.0; 
               foreach $tag => $count ($iv)
               {
                  $total += $count;
               }

               foreach $tag => $count ($iv)
               {
                  $count /= $total;
               }
            }
         }
      }

      local('$handle');
      $handle = openf(">models/trigrams.bin");
      writeObject($handle, %trigrams);
      writeObject($handle, %trigramsr);
      closef($handle);
      warn("trigrams saved!");  
   }
}

sub endings
{
   this('%endings');

   if ($0 eq "train")
   {
      local('$word $tag');

      ($word, $tag) = $1;

      if (strlen($word) >= 3)
      {
         %endings[right($word, 3)][$tag] += 1;
      }   
      else
      {
         %endings[$word][$tag] += 1;
      }
   }
   else
   {
      local('$ok $ov $ik $iv $total $count $tag');

      foreach $ik => $iv (%endings)
      {
         $total = 0.0; 
         foreach $tag => $count ($iv)
         {
            $total += $count;
         }

         foreach $tag => $count ($iv)
         {
            $count /= $total;
            assert $count <= 1.0 : "$count for $word -> $tag over 1.0 from $total : " . $iv;
         }
      }

      local('$handle');
      $handle = openf(">models/endings.bin");
      writeObject($handle, %endings);
      closef($handle);
      warn("endings saved");
   }
}

try
{
#train(&neural);
train(&endings, &trigrams, &lexicon);
}
catch $ex
{
   printAll(getStackTrace());
}
