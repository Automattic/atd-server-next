include("lib/nlp.sl");

$handle = openf(@ARGV[0]);
$data = readb($handle, -1);
closef($handle);

foreach $paragraph (splitByParagraph($data))
{
   println("PARAGRAPH BEGIN!");

   foreach $sentence ($paragraph)
   {
      println("     $sentence");
   }
}
