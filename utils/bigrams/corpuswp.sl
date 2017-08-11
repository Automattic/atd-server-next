#
# Export posts (only!) from a WordPress WXR file and make the content as plain text as possible.
# use this to preprocess a file for adding to data/corpus_extra
#

$handle = openf(@ARGV[0]);
$data = readb($handle, -1);
closef($handle);

$data = join(' ', split("\n|\r", $data));
@data = matches($data, '\<content\:encoded\>\<\!\[CDATA\[(.*?)\]\]\>\</content\:encoded\>');

foreach $index => $data (@data)
{
   if (strlen($data) > 0)
   {
      $data = strrep($data, '&amp;', '&', '&nbsp;', ' ', '<br>', "\n", '<p>', "\n", '&quote;', '"', '&#8220;', "'", '&#8221;', "'", '&#8217;', "'", '&laquo;', '"', '&raquo;', '"', '&rsquo;', "'");
      $data = replace($data, '(<[^>]*?>)', '');
      println($data);
   }
}
