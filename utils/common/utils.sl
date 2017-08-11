sub toTaggerForm
{
   return map({ return split('/', $1); }, $1);
}

sub sentences
{
   local('$handle $sentence $candidates $line');

   $handle = openf("data/tests/ $+ $1");

   while $line (readln($handle))
   {
      ($sentence, $candidates) = split('\\|', $line);
      $candidates = split('[,;] ', $candidates);
      yield @($sentence, $candidates[0], sublist($candidates, 1));
   }

   closef($handle);
}

sub words
{
   local('$handle $bad $good');
   $handle = openf("data/tests/ $+ $1");
   while $bad (readln($handle))
   {
      $good = readln($handle);
      yield @($bad, $good);
   }
   closef($handle);
}

sub loopHomophones
{
   local('$entry $sentence $correct $wrongs $previous $next $wrong');

   while $entry (sentences($1))
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
         [$2 process: $correct, $wrong, $wrongs, $previous, $next];
      }
   }

   [$2 finish];
}
