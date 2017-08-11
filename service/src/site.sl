debug(7 | 34);

include("lib/quality.sl");
include("lib/engine.sl");

sub service_init { }
if (-exists "service/src/local.sl")
{
   include("service/src/local.sl");
}

global('$lang $INFOURL');

$lang = systemProperties()["atd.lang"];
if ($lang ne "" && -exists "lang/ $+ $lang $+ /load.sl")
{ 
   include("lang/ $+ $lang $+ /load.sl"); 
}

# this variable defines the host used to reference explanations
$INFOURL = 'https://' . iff($lang ne "", "$lang $+ .") . 'service.afterthedeadline.com';

sub data
{
   local('$data');

   $data = [$session getSharedData];

   if ($data is $null)
   {
      $data = wait(fork(
      {
         local('$f');
         $f = lambda(
         {
            this('%shared $temp');

            local('$start');
           
            $start = ticks();

            warn("Working to load models...");

            global('$__SCRIPT__ $model $rules $dictionary $network $dsize %edits $hnetwork $usage $endings $lexdb $trigrams $verbs $locks $trie $lang');

            $lang = systemProperties()["atd.lang"];
            if ($lang ne "" && -exists "lang/ $+ $lang $+ /load.sl")
            { 
               include("lang/ $+ $lang $+ /load.sl"); 
            }

            $locks      = semaphore(1);
            initAllModels();

            # fix the dictionary (remove known misspelled words)
            fixDictionary($dictionary);

            $usage      = %(__last => ticks());

            warn("Models loaded in " . (ticks() - $start) . "ms");

            %shared = %(model => $model, dictionary => $dictionary, rules => $rules, network => $network, hnetwork => $hnetwork, 
                        edits => %edits, size => $dsize, usage => $usage, endings => $endings, lexdb => 
                        $lexdb, trigrams => $trigrams, verbs => $verbs, locks => $locks, trie => $trie);
   
            while (1)
            {
               yield %shared[$0];
            }
         });

         [$f rules];
         return $f;
      }));

      [$session setSharedData: $data];
   }
   return $data;
}

sub localProtect
{
   local('$temp');
   $temp = ohasha();

   setRemovalPolicy($temp, lambda({
      return iff([[$1 getData] size] > 128);
   }));

   setMissPolicy($temp, lambda({ 
      acquire($locks);
      local('$v $exception');
      try 
      {
         $v = $source[$2];
      }
      catch $exception 
      {
         warn("#Edits# $2 failed: $exception");
         warn(getStackTrace());
         $v = @();
      }
      release($locks);
      return $v;
   }, $source => $1));

   return $temp;
}

acquire([$session getSiteLock]);
   global('$__SCRIPT__ $model $rules $dictionary $network $dsize %edits $hnetwork $usage $endings $lexdb $trigrams $verbs $locks $trie');
   $dictionary = [data() dictionary]; 
   $model      = [data() model];    # this is safe to load for any session
   $rules      = [data() rules];
   $network    = [data() network];
   $hnetwork   = [data() hnetwork];
   %edits      = localProtect([data() edits]);
   $dsize      = [data() size];
   $usage      = [data() usage];
   $endings    = [data() endings];
   $lexdb      = [data() lexdb];
   $trigrams   = [data() trigrams];
   $verbs      = [data() verbs];
   $locks      = [data() locks];
   $trie       = [data() trie];
release([$session getSiteLock]);

[$session addHook: "/checkDocument", 
{
   local('$data');
   $data = stripHTML(%parms["data"]);
   display("service/src/view/service.slp", processDocument($data));
   return %(Content-type => "text/xml");
}];

[$session addHook: "/checkGrammar", 
{
   local('$data');
   $data = stripHTML(%parms["data"]);
   display("service/src/view/service.slp", processDocument($data, 'nospell'));
   return %(Content-type => "text/xml");
}];

[$session addHook: "/stats",
{
   local('$data');

   $data = stripHTML(%parms['data']);
   display("service/src/view/quality.slp", processDocumentQuality($data));

   return %(Content-type => "text/xml");     
}]; 

[$session addHook: "/verify",
{
   println('valid');
}];

[$session addHook: "/info.slp",
{
   local('$rule');
   $rule = copy( processSingle(%parms["text"], iff("tags" in %parms, %parms["tags"], $null), iff("engine" in %parms, %parms["engine"], $null)) );

   if ($rule is $null)
   {
      warn("Null rule: " . %parms);
      return;
   }

   $rule['rule'] = strrep($rule['rule'], 'Cliches', 'Clich&eacute;s');

   if (%parms["theme"] eq "wordpress")
   {
      display("service/src/view/wordpress_gen.slp", $rule, %parms["text"]);
   }
   else if (%parms["theme"] eq "tinymce")
   {
      display("service/src/view/wordpress_gen.slp", $rule, %parms["text"]);
   }
   else
   {
      display("service/src/view/rule.slp", $rule, %parms["text"]);
   }
}];

service_init();
