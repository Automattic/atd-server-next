#
# this program fixes the gutenberg corpus by looping through each file and collapsing paragraphs onto a single line.
# this will lead to a more accurate language model which is a really good thing.
#
# do not do this twice or bad things will happen!!!!
#

sub fixFile
{
   local('$handle $buffer $text $data');

   # read the file and populate our buffer please

   $buffer = allocate(lof($1));
   $handle = openf($1);
   while $text (readln($handle))
   {
      if ($text eq "")
      {
         print($buffer, "\n");
      }
      else
      {
         print($buffer, "$text ");
      }
   }
   closef($handle);
   closef($buffer);

   # read the contents of the buffer in

   $data = readb($buffer, -1);
   closef($buffer);

   # transfer the contents of the buffer to 

   $handle = openf("> $+ $1");
   writeb($handle, $data);
   closef($handle);
}


map({
   if (-isDir $1)
   {
      map($this, ls($1));
   }  
   else
   {
      fixFile($1);
   }
}, @ARGV);

println("Corpus Prepared");
