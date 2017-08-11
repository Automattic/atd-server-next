#
# code for a finite-state-machine in Sleep.
#

sub countRules
{
   local('$key $value $count');
   $count = 0;

   foreach $key => $value ($1)
   {
      [{
        local('$value');

        $3 *= strlen(tr($1["criteria"], '|.', '|', 'd')) + 1;

        foreach $value ($1["transitions"])
        {
           [$this: $value, $2, $3];
        }

        if ($1["result"] !is $null)
        {
           $2 += $3;
        }

        $3 /= strlen(tr($1["criteria"], '|.', '|', 'd')) + 1;

      }: $value, $count, 1];
   }

   return $count;
}

# transition($state, @("criton a", "criton b", ...), n)
sub transition2
{
   local('$value $match $count $word $tag');
   $count = $3 + 1;

   if (size($2) > 0)
   {
      ($word, $tag) = $2[0];

      foreach $value ($1["transitions"])
      {
         if ($word ismatch $value["criteria"] && $tag ismatch $value["tagc"])
         {
            $match = transition($value, sublist($2, 1), $count);
            if ($match !is $null)
            {
               return $match;
            }
         }
      }
   }

   if ('result' in $1)
   {
      return @($1["result"], $3, $1);
   }
}


# node($state, "criteria")
sub follow
{
   local('$value $next');

   foreach $value ($1["transitions"])
   {
      if ($value["criteria"] eq $2[0] && $value["tagc"] eq $2[1])
      {
         return $value;
      }
   }

   $next = %(criteria => $2[0], tagc => $2[1], transitions => @());
   push($1["transitions"], $next);

   return $next;
}

# addPath(%machine, "label", @("a", "b", "c", "d", "e"));
sub addPath
{   
   if (!-isarray $3[0])
   {
      # this is a simple backwards compatability mode
      return addPath($1, $2, map({ return @($1, '.*'); }, $3));
   }

   local('$machine');
 
   if ($3[0][0] ne ".*")
   {
      # create a machine for the first word.
      $machine = $1[$3[0][0]];
   }
   else
   {
      # create a machine for a tag.
      $machine = $1[$3[0][1]];
   }

   if ($machine !is $null)
   {
      _addPath($machine, $2, $3, join(" ", $3));
   }
   else
   {
      $machine = %(transitions => @(), criteria => "root");
      _addPath($machine, $2, $3, join(" ", $3));

      if ($3[0][0] ne ".*")
      {
         $1[$3[0][0]] = $machine; # ugly, yes.
      }
      else
      {
         $1[strrep($3[0][1], '\\', '')] = $machine; # ugly, yes.
      }
   }
}

sub _addPath
{
   if (size($3) == 0)
   {
#      warn(@_);

      $1["result"] = $2; 
      $2["path"] = $4;
      $2["id"] = unpack("H*", digest($4))[0];
   }
   else
   {
      _addPath(follow($1, $3[0]), $2, sublist($3, 1), $4); 
   }
}

sub check
{
   local('$start $result');

   if (size($2) > 0)
   {
      # use the first tag as a trigger... so long as there is no other result.
      if ($result is $null && $2[0][1] in $1)
      {
         $start = $1[$2[0][1]];
         $result = transition($start, $2, 0, '0BEGIN.0', '0END.0');
      }

      # use the first word as a trigger...  see which rules are associated with it
      if ($result is $null && $2[0][0] in $1) # $1[$2[0][0]] !is $null) # if $2[0] in $1 plz
      {
         $start = $1[$2[0][0]];
         $result = transition($start, $2, 0, '0BEGIN.0', '0END.0');
      }
   }
   return $result;
}

# checkPath($machine, @("a", "b", "c", ...))
sub checkPath
{
   local('$match');

   println("checkPath: $2");

   $match = check($1, $2, 0);
   if ($match !is $null)
   {
      println($match . " from: " . sublist($2, 0, $match[1]));
   }
}

sub printIT
{
   local('$t');
   println((" " x $2) . "Node: " . $1["criteria"] . " with: " . $1["result"]);
   foreach $t ($1["transitions"])
   {
      printIT($t, $2 + 3) 
   }
}

sub machine
{
   return %();
}

#$machine = machine();
#addPath($machine, %(title => "up to f"), @("a", "b", "c", "d", "e", "f"));
#addPath($machine, %(title => "3 a's"), @("a", "a", "a"));
#addPath($machine, %(title => "a b and 2 numbers"), @("a", "b", '\d', '\d'));
#addPath($machine, %(title => "3 a's and a b with a c"), @("a", "a", "a", "b", "c"));
#checkPath($machine, @("a", "a", "a", "b", "c", "d"));
  # 
#println("Number path");
#checkPath($machine, @("a", "b", 3, 6, 92, "c"));
