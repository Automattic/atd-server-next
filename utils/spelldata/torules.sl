#
# Generate a rule file from cut and paste Wikipedia rules data
# http://en.wikipedia.org/wiki/Wikipedia:Lists_of_common_misspellings/Grammar_and_Misc
#
# use java -jar lib/sleep.jar torules.sl wrong to generate a reverse rules file suitable for error corpus generation
#
# paste the contents into a text editor, then paste into a text file and process with this program
#

$handle = openf("wp.txt");

%sections = ohash();
setMissPolicy(%sections, { return @(); });

while $text (readln($handle))
{
   if ($text ismatch '.*?[\*\#] (.*?) \((.*?)\).*')
   {
      ($wrong, $correct) = matched();

      if (',' !isin $correct)
      {
         @a = split(' ', $wrong);
         @b = split(' ', $correct);
 
         if (size(@a) == size(@b))
         {
            foreach $index => $word (@a)
            {
               if ($word !in @b) { $special = $word; $replace = @b[$index]; }
            }

            if (@ARGV[0] eq 'wrong')
            {
               push(%sections["Confused word: $special"], "$correct $+ ::word= $+ $wrong");
            }
            else
            {
               push(%sections["Confused word: $special"], "$wrong $+ ::word= $+ $correct $+ ::pivots= $+ $special $+ , $+ $replace $+ ::options= $+ $special $+ , $+ $replace");
            }
         }
         else
         {
            if (@ARGV[0] eq 'wrong')
            {
               push(%sections["Multiple Options"], "$correct $+ ::word= $+ $wrong");
            }
            else
            {
               push(%sections["Multiple Options"], "$wrong $+ ::word= $+ $correct");
            }
         }
      }
      else
      {
         if (@ARGV[0] ne 'wrong')
         {
            push(%sections["Misc"], "$wrong $+ ::word= $+ $correct");
            #push(%sections["Misc"], "$correct $+ ::word= $+ $wrong");
         }
         else
         {
            @temp = split(', ', $correct);
            map(lambda({ push(%sections["Misc"], "$1 $+ ::word= $+ $wrong $+ ::options= $+ $correct"); }, \$wrong, \$correct), @temp);
         }
      }
   }
   else
   {
  #    push(%sections["__Rejects__"], $text);
   }
}

foreach $key => $value (%sections)
{
   println("\n#\n# $key \n#\n");
   printAll($value);
}
