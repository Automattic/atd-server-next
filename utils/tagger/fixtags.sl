sub main
{
   local('$handle $sentence $entry $word $tag $previous @s');
   $handle = openf($1);
   while $sentence (readln($handle))
   {
      @s = @();

      foreach $entry (split(' ', $sentence))
      {
         ($word, $tag) = split('/', $entry);
         if ("'" isin $word && size(@s) > 0)
         {
            if ($tag eq "''")
            {
               @s[-1] = @(@s[-1][0] . $word, @s[-1][1]);
            }
            else
            {
               @s[-1] = @(@s[-1][0] . $word, @s[-1][1] . ',' . $tag);
            }
         }
         else
         {
            push(@s, @(lc($word), $tag));
         }

      }
      println(  join(" ", map({ return join('/', $1); }, @s)) );
   }
}

invoke(&main, @ARGV);
