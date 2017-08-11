#
# Multilayer Perceptron Artificial Neural Network in Sleep
# (mostly ported from Ch 4, Collective Intelligence by Toby Segaran)
#
# Usage:
#
#  $network = newObject("nn", @outputs, $penalty)
#
#    creates a new neural network.  the network classifies tries to
#    map inputs to any of the possible outputs.  you may also specify
#    the penalty value applied to an input when it doesn't exist as
#    a link to a node.  $penalty is optional
#
#  [$network trainquery: %inputs, $output|%outputs, $weight]
#
#    trains the network to map to $output to the given set of 
#    @inputs.  $output must be from @outputs.  
#
#    Optionally you can specify %outputs which is a mapping between
#    one or more output variables (from @outputs) to any value.  Use 
#    this if you want a little more control.
#
#    $weight is optional and lets you specify how heavily to weigh 
#    this training data.  The default value is 0.5
#
#  %results = [$network getresult: %inputs]
#
#    obtain a hash containing the strength of possible output when
#    passed the specified input.  The input can be a combination the
#    network hasn't seen before.
#
#  [$network print]
# 
#    This exists for debugging purpoes and allows you to print the
#    contents of the network.  The network is an array of hashes
#    referencing hashes with the following meaning:
#
#    @network[0]["hiddenId"]["input"] = weight value
#      this represents the first layer, connections between inputs
#      and hidden ids in the network.
#
#    @network[1]["output"]["hiddenId"] = weight value
#      this is the second layer, connections between the hiddenIds
#      and the outputs.
#
#    Where is the input layer?  The input layer is assumed.  Present
#    features (when you provide an input) have a value of 1.0 and
#    everything else is 0.0.  
#
#  Persisting Training Data:
#
#    You can persist your neural network using writeObject and readObject
#    However when you load the neural network back from a handle use
#    [$network reinit] to reinitialize some values.  If you don't do this
#    you'll get null errors when the network sees new inputs.
#
# Contact:
#
#    Raphael Mudge (rsmudge@gmail.com)

# include object.sl if its not already included 
if (&newObject is $null || &object is $null)
{
   include('lib/object.sl');
}

#srand(0xCAFEBABEL);
srand(0xBEEFBABEL);

# neural network in Sleep is represented as:
# @%%[layer 0..1][to][from]

# @outputs, [$penalty]
sub nn::init
{
   # declare our class instance variables   

   this('$network $outputs $penalty $expected');

   # check our arguments

   assert -isarray $1 : "potential outputs must be an array!";

   # setup our layers please

   local('$x $output $2');

   $network = @();

   for ($x = 0; $x < 2; $x++)
   {
      $network[$x] = %();
   }

   # setup our potential outputs

   $outputs = $1;
   
   foreach $output ($1)
   {
      $network[1][$output] = ohash();
      setMissPolicy($network[1][$output], { return 0.0; });
   }

   # setup our hidden nodes.

   local('$x $to %temp $3');
   $to = size($2) * 2;
   for ($x = 0; $x < $to; $x++)
   {
      %temp = putAll(%temp, $2, { return rand(); });
      [$this generate_hidden_node: $x, %temp];
   }

   # setup our penalty value

   $penalty = iff($3 !is $null, $3, -0.2);

   $expected = $2;
}

# reinitializes the network after deserializing it
sub nn::reinit
{
   local('$node $key');

   foreach $key => $node ($network[1])
   {
      setMissPolicy($node, { return 0.0; });
   }

   foreach $key => $node ($network[0])
   {
      setMissPolicy($node, lambda({ return double($penalty); }, \$penalty)); 
   }
}

# ($unique_id, $features)
sub nn::generate_hidden_node
{
   if ($network[0][$1] is $null)
   {
      local('$node $feature $hiddenvalue $output %weights $weight');
    
      # create our node and give it a layer 0 default value of $penalty
      # we want non-existent features to count against the query a little bit

      $node = ohash();  
      setMissPolicy($node, lambda({ return double($penalty); }, \$penalty)); 

      # input layer (mapping feature to hidden id)

      foreach $feature => $weight ($2)
      {
         $hiddenvalue = $weight / size($2);
         $node[$feature] = $hiddenvalue;
      }

      $network[0][$1] = $node;

      # output layer (map hidden id to potential outputs)

      foreach $output => %weights ($network[1])
      {
         %weights[$1] = 0.1;
      }
   }
}

# $features
sub nn::feedforward
{
   return feedforward($1, $network[0], $network[1]);

   local('$sum $feature $iid $hid $oid $weight %weights %inputs %ahidden %aoutput $value');
 
   # activate input layer

     # assuming a 1.0 for all our features. <3

   # activate hidden nodes

   foreach $hid => %weights ($network[0])
   {
      $sum = 0.0;

      foreach $feature => $weight ($1)
      {
         $sum += %weights[$feature] * $weight; # there is an implied * 1.0 here
      }

      %ahidden[$hid] = [Math tanh: $sum];
   }

   # activate the output layer

   foreach $oid => %weights ($network[1])
   {
      $sum = 0.0;
      foreach $hid => $value (%ahidden)
      {
         $sum += $value * %weights[$hid];
      }

      %aoutput[$oid] = [Math tanh: $sum];
   }

   assert feedforward($1, $network[0], $network[1]) eq @(%aoutput, %ahidden, $1) : "Something went wrong: \n\t" . feedforward($1, $network[0], $network[1]) . " vs. \n\t" . @(%aoutput, %ahidden, $1);

   return @(%aoutput, %ahidden, $1);
}

# @features, $selected
sub nn::trainquery
{
   local('$results $desired $3 $4');

#   if ([[$network[0] getData] size] < 25)
#   {
#      # create a hidden node if one doesn't already exist, eh.
#      [$this generate_hidden_node: unpack("H*", digest($1, "MD5"))[0], $1];
#   }

   # feed the result through the network and give us some base values
   $results    = [$this feedforward: $1];

   # setup what the result should be
   $desired    = ohash();
   setMissPolicy($desired, lambda({ return double($default); }, $default => iff($4 is $null, 0.0, $4)));

   if (-ishash $2)
   {
      putAll($desired, keys($2), values($2));
   }
   else
   {
      $desired[$2] = 1.0;
   }

   # propagate it through
   [$this backPropagate: $desired, $results, iff($3 is $null, 0.5, $3)]; 
}

# $query
sub nn::getresult
{
   return [$this feedforward: $1][0];
}

# $desired, @(%outputs, %hidden, @features), $adjustTo = 0.5
sub nn::backPropagate
{
   local('$oid $hid $feature %output_deltas %hidden_deltas $error $delta $change %aoutput %ahidden @features $value $weight');

   (%aoutput, %ahidden, @features) = $2;

   # calculate errors against the output

   foreach $oid => $value (%aoutput)
   {
      $error = $1[$oid] - $value; 
      %output_deltas[$oid] = dtanh($value) * $error;
   }

   # claculate errors for hidden layer      

   foreach $hid => $value (%ahidden)
   {
      $error = 0.0;
      foreach $oid => $delta (%output_deltas)
      {
         $error += $delta * $network[1][$oid][$hid];
      }

      %hidden_deltas[$hid] = dtanh($value) * $error;
   }   

   # update output weights

   foreach $hid => $value (%ahidden)
   {
      foreach $oid => $delta (%output_deltas)
      {
         $change = $delta * $value;
         $network[1][$oid][$hid] += $3 * $change;
      }
   }

   # update input weights

   foreach $feature => $weight (@features)
   {
      foreach $hid => $delta (%hidden_deltas)
      {
         $network[0][$hid][$feature] += $3 * $delta * $weight;
      } 
   }
}

# print out the network (for debugging purposes)
sub nn::print
{
   println("Potential outputs: " . $outputs);
   println("Network:\n $+ $network");
}

sub dtanh
{
   return 1.0 - ($1 ** 2.0);
}
