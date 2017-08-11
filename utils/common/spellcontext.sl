#
# test out spelling with associated context information
#

sub suggestTest
{
   local('$suspect $dict $previous $next @suggestions $f');
   ($suspect, $dict, $previous, $next) = @_;

   @suggestions = %edits[$suspect];

   if ($correct in @suggestions)
   {
      foreach $f (@functions)
      {
         [$f : $suspect, $correct, copy(@suggestions), $previous, $next];
      }
    #  warn("Done for $previous $suspect $next -> $correct");
   }

   return @();
}

sub testCorrectionsContext
{
   local('$score $entry $sentence $correct $wrongs @results @words $rule $wrong $previous $next $func');

   while $entry (sentences($1))
   {
      ($sentence, $correct, $wrongs) = $entry;
      ($previous, $next) = split(' \\* ', $sentence);
      $func = lambda(&suggestTest, \$score, \$correct, @functions => sublist(@_, 1));

      #
      # check for a false negative
      #
      foreach $wrong ($wrongs)
      {
         [$func: $wrong, $dictionary, $previous, $next]
      } 
   }
}

sub checkAnyHomophone
{
   return invoke(&checkAnyHomophone2, @_, parameters => %(\$criteriaf))[0];
}

sub checkAnyHomophone2
{
   local('$current $options $pre $next %scores $criteriaf @results $option $hnetwork $tags $pre2 $next2');
   ($hnetwork, $current, $options, $pre, $next, $tags, $pre2, $next2) = @_;

   # setup the criteria function
#   $criteriaf = criteria(@("pref", "postf", "probability"));

#   $options = filter(lambda({ return iff(Pbigram1($pre, $1) > 0.0 || Pbigram2($1, $next) > 0.0, $1); }, \$pre, \$next), $options);

   # score the options
   foreach $option ($options)    
   {
#      warn(@_ . " -> " . [$criteriaf: $current, $option, $options, $pre, $next, $tags]);
      %scores[$option] = [$hnetwork getresult: [$criteriaf: $current, $option, $options, $pre, $next, $tags, $pre2, $next2]]["result"];
      if ($option eq $current)              
      {
#         warn(Pword($current));
         %scores[$option] *= 10.0; # * (1.0 - (Pword($current) * 2500));
      }
   }   

   # filter out any unacceptable words
   @results = filter(lambda({ return iff(%scores[$1] >= %scores[$current] && $1 ne $current && %scores[$1] > 0.0, $1, $null); }, \%scores, \$current), $options);

   # sort the remaining results (probably only one left at this point)
   @results = sort(lambda({ return %scores[$2] <=> %scores[$1]; }, \%scores), @results);

   if (size(@results) > 0)
   {
     # warn("checkHomophone: " . @_ . " -> " . @results);
     # warn("                " . %scores);
   }

   # return the results
   return @(@results, %scores);
}
