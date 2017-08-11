# everything you need for Sleep OO 
sub object 
{ 
   local('$function'); 
   $function = function("& $+ $type $+ :: $+ $0"); 
   if ($function !is $null) 
   { 
      return invoke($function, @_, $0, $this => $this); 
   } 
   throw "$type $+ :: $+ $0 - no such method"; 
} 

sub newObject 
{ 
   local('$object'); 
   $object = lambda(&object, $type => $1); 
   # invoke the constructor 
   invoke($object, sublist(@_, 1), "init", $this => $object); 
   return $object; 
} 
