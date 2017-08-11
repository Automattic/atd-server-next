#
# Natural Language Processing Tools for Sleep
#

# set our globals...
global('$eos $abbr');

# our end of sentence marker
$eos  = "\x01";

# abbreviations compiled into a regular expression pattern
$abbr = [{
            local('$handle @data');
            $handle = openf(getFileProper("data", "rules", "abbr.txt"));
            @data   = readAll($handle);
            closef(@data);

            return '(' . join("|", @data) . ')';
        }];


sub stripHTML
{
   # certain tags (like bold) are replaced by newlines to force AtD to treat them as new sentences.  This is important to make sure they don't carry context information with them

   $1 = strrep($1, '&nbsp;', ' ', '&quote;', '"', '&amp;', '&', '&eacute;', "\xe9", '&egrave;', "\xe8");
   $1 = replace(replace($1, '<[/]{0,1}(?i:p|b|br|span|strong|u|li|em|i|a|h\d|div).*?>', "\n"), '(<[^>]*?>)', '');
   #      $data = replace($data, '(\\&[^\\;]*?\\;)', '');
   return $1;
}

sub splitByParagraph
{
   return map(&splitIntoSentences, split('(\n\s*)+', $1));
}

sub splitIntoSentences
{
   # 0) kill all extra whitespace.

   local('$string');
   $string = tr($1, '\s', " ", "s");

   # 1) replace all punctuation characters with a end-of-sentence marker
   #    <punct> [A-Z][0-9]  - likely a start of sentence.

   $string = replace($string, '([!?\.])(\s+\w)', "\$1 $+ $eos $+ \$2");

   # 2) look for all words that preceed our end-of-sentence marker... invalidate if:
   #    number<EOS>number   - means we have a double or something
   #    abbreviation<EOS>   - means we have an abbreviation
   #    <white space>LETTER<EOS> - potentially an abbreviation (pretty generic)

   $string = replace($string, "(\\s*) $+ $abbr $+ \\. $+ $eos", '$1$2.');
   $string = replace($string, "(\\d+)\\. $+ $eos $+ (\\d+)", '$1.$2');
   $string = replace($string, '(\s+[A-Z]\.)' . $eos, '$1');
 
   # 3) special cases.
   #    ...  - not a new sentence
   #    [ap].m.\s+[A-Z0-9] - legit end of sentence
   #    [ap].m.\s+[a-z] - not end of sentence
   #    <EOS>..."<EOS>

   $string = replace($string, "\\. $+ $eos" x 3, '...');
   $string = replace($string, "([ap])\\. $+ $eos $+ m\\.(\s+[A-Z0-9])", '$1.m.$2');
   $string = replace($string, "([ap])\\. $+ $eos $+ m\\. $+ $eos", '$1.m.');

   # 4) return sentence objects

   return split($eos, $string);
}

sub groupProperNouns
{
   local('$x $value');

   foreach $x => $value ($1)
   {
      if ($value !ismatch '\p{Upper}\p{Lower}+')
      {
         break;
      }
   }

   if ($value eq "and" || $value eq "of")
   {
      return $x + groupProperNouns(sublist($1, $x + 1)) + 2;
   }

   return $x;
}

# group out comma'd clauses and quoted clauses.  eh?!?@
sub splitIntoClauses
{
   local('@results $len $buffer $r $x $index');
   $len    = strlen($1);
   $buffer = allocate($len);
   setEncoding($buffer, 'UTF-16');

   for ($x = 0; $x < $len; $x++)
   {
      if (charAt($1, $x) eq ',')
      {
         closef($buffer);
         push(@results, bread($buffer, 'U')[0]);
         closef($buffer);
         $buffer = allocate($len);
         setEncoding($buffer, 'UTF-16');
      }   
      else if (charAt($1, $x) eq '"')
      {
         closef($buffer);
         push(@results, bread($buffer, 'U')[0]);
         closef($buffer);
         $buffer = allocate($len);
         setEncoding($buffer, 'UTF-16');

         $index = indexOf($1, charAt($1, $x), $x + 1);

         if ($index !is $null)
         {
            foreach $r (splitIntoClauses(substr($1, $x + 1, $index)))
            {
               push(@results, $r);
            }

            $x = $index;          
         }
      }
      else
      {
         print($buffer, charAt($1, $x));
      }
   }

   closef($buffer);
   push(@results, bread($buffer, 'U')[0]);
   closef($buffer);
 
   return filter({ return iff(strlen(["$1" trim]) > 0, [$1 trim]); }, @results);
}

sub splitIntoWords
{
   local('@list $x @prop $value');
 
   @list = split('\s+', replace(replace($1, '([,\(\)\[\]\:\;\/]|https{0,1}\:\/\/[0-9a-zA-Z\/\:\~\-\.\_\?\%\&\=]*|-{2})', ' $1 '), '[^0-9a-zA-Z\p{Ll}\p{Lu}\\,\(\)\[\]\;\:\'\\\\\\-\\/ ]', ""));

   if (size(@list) > 0 && strlen(@list[0]) == 0)
   {
      shift(@list);
   }

   return @list;

#   @prop = @list;   

   # group proper nouns together.
 #  while (size(@prop) > 1)
 #  {
 #     if (@prop[0] ismatch '\p{Upper}\p{Lower}+')
 #     {
 #        $x = groupProperNouns(@prop);

#         if ($x > 1)
 #        {
  #          splice(@prop, @(join(" ", sublist(@prop, 0, $x))), 0, $x);
   #      }
    #  }
      
    #  @prop = sublist(@prop, 1);
  # }

   #return @list;
}
