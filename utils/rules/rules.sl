import org.dashnine.preditor.* from: lib/spellutils.jar;
use(^SpellingUtils);

if (getFileName($__SCRIPT__) eq 'rules.sl') 
{
   # misc junk
   include("lib/dictionary.sl");
   global('$__SCRIPT__ $model $rules $dictionary $network $dsize %edits $hnetwork $account $usage $endings $lexdb $trigrams $verbs');
   $model      = get_language_model();
   $dictionary = dictionary();
   $dsize      = size($dictionary);
}
include("lib/fsm.sl");

#
# create our FSM rule engine.
#
global('$rules $homophones $agreement $voice $rcount');
$rules      = machine();
$homophones = machine();
$agreement  = machine();
$voice      = machine();

#
# load rules in general from a rules file (this thing handles POS tags as well)
#
# <rule file> format:
#
# rule..|[key=value|...]
#
# note that key=value are parsed and dumped into a hash.  This information is used by the system to
# filter out false positives and stuff.
#
# loadRules($rules, "filename", %(default hash))
sub loadRules
{
   local('$handle $text $rule %r @r $v $key $value $option');

   $handle = openf($2);
   while $text (readln($handle))    
   {
      if ($text ne "" && "#*" !iswm $text)
      {
         $rule = split('\:\:', $text)[0];       
         %r    = copy($3);

         foreach $v (sublist(split('\:\:', $text), 1))
         {
            ($key, $value) = split('=', $v);
            %r[$key] = $value;
         }

         @r = split(' ', $rule);
         @r = map(
         {          
            if ('*/*' iswm $1)
            {
               return split('/', $1);
            }
            else if ('&*' iswm $1)
            {
               return @(invoke($1), '.*');
            }
            return @($1, '.*');               
         }, @r); 

         if (@r[0][0] eq "")
         {
             addPath($1, %r, @r);
         }
         else if ('|' isin @r[0][0])
         {
            foreach $option (split('\|', @r[0][0]))
            {
               addPath($1, %r, concat(@(@($option, @r[0][1])), sublist(@r, 1)));  
            }
         }
         else
         {
            addPath($1, %r, @r);
         }
      }
   }       

   return $1;
}      

#
# passive voice tense rules.
#

sub tense
{
   return %(recommendation => { return "Revise <em> $+ $2 $+ </em> with active voice"; },
            view => "view/rules/empty.slp",
            rule => "Passive voice",
            description => "Active voice makes it clear who is doing what.  In an active sentence, the person that is acting is the subject.  Passive sentences obscure or omit the sentence 
subject.<br><br>Use passive voice when the sentence object is more important than the subject.  The active voice is generally easier to read.
<br>
<br><b>Examples</b> (<i><b>subject</b></i>, <u>object</u>)
<br>
<br>Before: <u>Our results</u> will be discussed.
<br>After: <i><b>We</b></i> will discuss <u>our results</u>.
<br>
<br>Before: <i><b>Wolverine</b></i> was made to be a <u>weapon</u>.
<br>After: <i><b>The government</b></i> made <u>Wolverine</u>. <i><b>Wolverine</b></i> is a <u>weapon</u>.",
            style => 'green',
            category => 'Passive'
          );
}

sub dictgrep
{
   local('$handle');
   $handle = openf("models/dictionary.txt");
   @words = readAll($handle);
   closef($handle);

   @words = filter( lambda({ return iff($pattern iswm $1, $1); }, $pattern => $1), @words);
   return @words;
}

sub selfwords
{
   return join('|', dictgrep("self-*"));
}

sub absolutes
{
   return 'dead|disappeared|empty|false|full|gone|illegal|infinite|invaluable|legal|perfect|pervasive|pregnant|professional|true|whole|vanished|(omni[a-z]+)';
}

sub uncountable
{
   return 'accommodation|advice|access|baggage|bread|equipment|garbage|luggage|money|cattle|knowledge|sand|furniture|meat|food|news|pasta|progress|research|water|freedom|maturity|intelligence|travel|pollution|traffic';
}

sub modal_verbs 
{
   return "can|could|may|must|should|will|would|can't|couldn't|mustn't|shouldn't|won't|wouldn't";
}

sub comparisons_base
{
   return 'good|bad|hot|cold|lame|less|more|great|heavy|light|smart|dumb|cheap|sexy|tall|short|fast|slow|old|young|easy|hard|high|low|large|small|big|soon|late|strong|loud|quiet|dark|bright';
}

sub comparisons
{
   local('$compares');
   @compares = split('\|', 'hotter|colder|lamer|less|lesser|more|greater|heavier|lighter|better|worse|smarter|dumber|cheaper|sexier|taller|shorter|faster|slower|older|younger|easier|harder|farther|closer|higher|lower|larger|smaller|sooner|later|weaker|stronger|louder|quieter|darker|brighter');
   @compares = concat(@compares, map({ return uc(charAt($1, 0)) . substr($1, 1); }, @compares));
   return join('|', @compares);
}

sub past
{
   # a regex to check if a word is a past participle or not.
   return '\w+ed|awoken|borne|beaten|become|begun|bent|bet|bitten|bled|blown|broken|bred|brought|built|burnt|burst|bought|caught|chosen|come|cost|cut|dealt|done|drawn|dreamt|drunk|driven|eaten|made|meant|met|paid|put|quit|read|ridden|rung|risen|run|said|seen|sought|sold|sent|set|shaken|shone|shot|shown|shut|sung|sunk|sat|slept|smelt|spoken|spent|spilt|spoilt|spread|stood|stolen|stuck|stung|stunk|struck|sworn|swum|taken|taught|torn|told|thought|thrown|understood|woken|worn|wept|won|written';
}

sub irregular_noun_singular
{
   return 'addendum|alumnus|analysis|axis|bacillus|bacterium|basis|calf|crisis|criterion|curriculum|datum|die|diagnosis|elf|ellipsis|emphasis|erratum|fireman|foot|genus|goose|half|hypothesis|knife|leaf|life|loaf|louse|man|matrix|medium|memorandum|mouse|neurosis|nucleus|oasis|ovum|paralysis|parenthesis|person|phenomenon|self|shelf|stimulus|stratum|synthesis|synopsis|that|thesis|thief|this|tooth|wife|wolf|woman';
}

sub irregular_noun_plural
{
   return 'addenda|alumni|analyses|axes|bacilli|bacteria|bases|calves|crises|criteria|curricula|data|dice|diagnoses|elves|ellipses|emphases|errata|firemen|feet|genera|geese|halves|hypotheses|knives|leaves|lives|loaves|lice|men|matrices|media|memoranda|mice|neuroses|nuclei|oases|ova|paralyses|parentheses|people|phenomena|selves|shelves|stimuli|strata|syntheses|synopses|those|theses|thieves|these|teeth|wives|wolves|women';
}

sub irregular_verb_past_perfect
{
   return 'arisen|awoken|backbitten|been|beaten|befallen|begotten|begun|begirt|bespoken|bestridden|betaken|bidden|bided|bitten|blawn|blown|bowstrung|broken|chosen|cleeked|counterdrawn|cowritten|crash-dived|crib-bitten|cross-bitten|crowed|dared|deep-frozen|dived|done|drawn|drunk|driven|eaten|fallen|farebeaten|flash-frozen|flown|flyblown|forbidden|fordone|foregone|foreknown|foreseen|forespoken|forgotten|forgiven|forlorn|forsaken|forsworn|free-fallen|frozen|frostbitten|ghostwritten|given|gone|grown|hagridden|halterbroken|hand-ridden|handwritten|hewn|hidden|hoten|housebroken|interwoven|known|lain|mischosen|misdone|misfallen|misgiven|misknown|misspoken|missworn|mistaken|misworn|miswritten|mown|outdone|outdrawn|outdrunk|outdriven|outflown|outgrown|outridden|outseen|outsung|outspoken|outsprung|outsworn|outswum|outthrown|outworn|outwritten|overborne|overblown|overdone|overdrawn|overdrunk|overdriven|overeaten|overflown|overgrown|overlain|overridden|overseen|overspoken|oversprung|overstridden|overtaken|overthrown|overworn|overwritten|partaken|predone|preshrunk|quick-frozen|redone|redrawn|regrown|retaken|retorn|retrodden|reworn|rewritten|ridden|rung|risen|rough-hewn|seen|shaken|shown|shrunk|shriven|sightseen|sung|sunk|skywritten|slain|smitten|sown|spoken|spun|sprung|stolen|stunk|stridden|striven|sworn|swollen|swum|swonken|taken|torn|test-driven|test-flown|thrown|trodden|typewritten|underdone|undergone|underlain|undertaken|underwritten|undone|undrawn|undrawn|unfrozen|unhidden|unspoken|unsworn|untrodden|unwoven|unwritten|uprisen|upsprung|uptorn|woken|worn|woven|wiredrawn|withdrawn|written';
}

sub irregular_verb_past
{
   return 'arose|ate|awoke|bade|beat|became|befell|began|begot|bespoke|bestrode|betook|bit|blew|bode|bore|broke|built|came|chose|cowrote|crew|did|dove|drank|drew|drove|fell|flew|forbade|forbore|foresaw|forewent|forgave|forgot|forsook|froze|gave|grew|hewed|hid|hight|knew|lay|misgave|misspoke|mistook|mowed|outdid|outgrew|outran|overbore|overcame|overlay|overran|overrode|oversaw|overthrew|overtook|partook|ran|rang|reawoke|redid|redrew|retook|rewrote|rived|rode|rose|sang|sank|saw|shook|shore|showed|shrank|slew|smote|sowed|span|spoke|sprang|stank|stole|strewed|strode|strove|swam|swelled|swore|threw|took|tore|trod|underlay|undertook|underwent|underwrote|undid|uprose|was|went|withdrew|woke|wore|wove|wrote';
}

sub irregular_verb_base
{
   return 'abide|alight|arise|awake|backlight|be|bear|befall|beget|begin|behold|belay|bend|beseech|bespeak|betake|bethink|bid|bide|bind|bite|bleed|blend|bless|blow|bowstring|break|breed|bring|build|burn|buy|catch|chide|choose|clap|cleave|cling|clothe|creep|crossbreed|crow|dare|daydream|deal|dig|disprove|dive|do|dogfight|dow|draw|dream|drink|drive|dwell|eat|engrave|fall|feed|feel|fight|find|flee|fling|fly|forbear|forbid|forego|foresee|foretell|forget|forgive|forsake|forswear|freeze|frostbite|gainsay|gaslight|geld|get|gild|gin|gird|give|gnaw|go|grave|grind|grow|hamstring|hang|have|hear|heave|hew|hide|hoist|hold|inbreed|inlay|interbreed|interweave|keep|ken|kneel|know|lade|landslide|lay|lead|lean|leap|learn|leave|lend|lie|light|lose|make|mean|meet|melt|mislead|misspell|mistake|misunderstand|moonlight|mow|outdo|outgrow|outlay|outride|outshine|overdo|overeat|overhang|overhear|overlay|overleap|overlie|overpass|override|oversee|overshoot|overspill|overtake|overthrow|overwrite|partake|pay|pen|plead|prove|rap|rebuild|redo|redraw|reeve|regrow|relay|relight|remake|rend|repay|resell|retake|retell|rethink|retrofit|rewind|rewrite|ride|ring|rise|saw|say|see|seek|sell|send|sew|shake|shave|shear|shew|shine|shoe|shoot|show|shrink|sing|sink|sit|slay|sleep|slide|sling|slink|smell|smite|sneak|sow|speak|speed|spell|spend|spill|spin|spoil|spring|stand|stave|steal|stick|sting|stink|strew|stride|strike|string|strip|strive|sunburn|swear|sweep|swell|swim|swing|take|teach|tear|tell|think|thrive|throw|tine|tread|troubleshoot|typewrite|unbend|unbind|undergo|underlay|underlie|underpay|undersell|undershoot|understand|undertake|underwrite|undo|unlearn|unmake|unsay|unwind|uphold|uprise|vex|wake|waylay|wear|weave|wed|weep|wend|whipsaw|win|wind|wit|withdraw|withhold|withstand|work|wrap|wreak|wring|write|zinc';
}

# singular nouns that want a determiner
sub determiner_wanted
{
    return "absence|adult|affair|agreement|airport|alliance|amount|angle|announcement|apartment|appearance|appointment|argument|arrangement|arrival|assertion|assumption|atmosphere|atom|attitude|aunt|author|automobile|bag|ballot|bar|barrel|beast|bird|birthday|bit|blade|boat|bottle|bottom|bow|breast|bridge|brother|bullet|bundle|burden|cabin|cabinet|canal|candle|car|career|carriage|case|castle|cat|cave|ceiling|centre|chamber|chapter|charm|chest|child|circumstance|citizen|clerk|clip|clock|coalition|colleague|collection|combination|companion|complaint|concept|conclusion|condition|constitution|continent|corner|coup|couple|cousin|cow|creator|creature|crew|crowd|crown|decade|default|defect|departure|description|desk|device|distance|dock|doctor|doctrine|document|dog|dome|dozen|draft|duration|ear|earthquake|edge|editorial|egg|election|employer|encyclopedia|endorsement|engagement|envelope|episode|equation|eruption|essay|establishment|estate|event|exception|expedition|explosion|extension|extent|fan|farmer|feast|fee|fence|field|finger|flood|floor|flower|fool|forehead|formation|fraction|framework|friend|frontier|future|gadget|gallon|gap|garden|gate|generation|gift|glance|glimpse|grandfather|group|guy|handful|harbour|hat|height|hero|hole|holiday|horizon|horse|hospital|hotel|hour|household|husband|iPhone|iPod|illustration|impression|impulse|institution|instrument|intention|interior|interval|interview|introduction|investigation|invitation|island|job|joke|journal|journey|kid|kitchen|knife|knight|lamp|laptop|lawsuit|lawyer|leg|legislature|lesson|lifetime|lion|lot|lover|manner|manuscript|margin|meal|message|method|mile|mill|mind|minimum|minute|mirror|mission|mixture|moment|monarch|monster|month|monument|moon|mouth|movie|museum|name|nation|needle|neighborhood|nest|nose|notebook|notion|nurse|oath|obligation|opinion|opponent|orchestra|organ|organism|ounce|outbreak|outcome|oven|pair|parent|partnership|path|patient|patron|pattern|peasant|pen|pencil|period|person|phenomenon|photo|photograph|phrase|picture|piece|pile|pilot|pint|pipe|plane|planet|plot|pocket|poem|portrait|pot|pound|presence|presentation|price|principle|prisoner|problem|product|profession|project|proposal|proposition|province|publication|pupil|puzzle|race|reader|realm|recession|redirect|refusal|regiment|region|reign|relationship|remainder|report|reporter|reputation|request|requirement|resolution|restaurant|ring|road|role|roof|rope|row|rumor|sake|scene|sea|seat|sentence|servant|shadow|shaft|ship|shore|signature|sister|situation|skin|slave|slope|smile|soldier|song|soul|speaker|sphere|stage|statement|statue|stomach|storm|stranger|street|student|successor|suggestion|sum|summit|sun|surface|sword|symbol|tail|tale|telescope|template|temple|term|theme|thing|threat|throat|throne|thumb|tide|tip|title|tomb|tongue|topic|transition|tree|trend|triangle|trick|trip|trunk|type|uncle|universe|verb|vessel|village|visitor|volcano|voyage|weapon|web|wedding|week|weekend|widow|window|winner|world|yard|effort|environment|genre|list|photo|picture|population|range|response|stake|suburb|thing|type|understanding|view|warning";
}

sub irregular_verb
{
   # a regex to check if a word is a present past with a different past participle   
   return 'abide|abode|alight|arise|arose|ate|awake|awoke|be|bear|became|befall|befell|began|beget|begin|begot|behold|bend|beseech|betake|bethink|betook|bind|bit|bite|bleed|blew|blow|bore|break|breed|bring|broke|browbeat|build|burn|buy|came|catch|chide|choose|chose|clap|cling|clothe|creep|dare|daydream|deal|did|dig|disprove|dive|do|dove|drank|draw|dream|drew|drink|drive|drove|dwell|eat|fall|feed|feel|fell|fight|find|flee|flew|fling|fly|forbade|forbear|forbid|forbore|forego|foresaw|foresee|foretell|forewent|forgave|forget|forgive|forgot|forsake|forsook|forswear|freeze|frostbite|froze|gainsay|gave|get|gild|give|go|grew|grind|grow|hang|have|hear|heave|hew|hewed|hid|hide|hold|inbreed|inlay|keep|kneel|knew|know|lade|landslide|lay|lead|lean|leap|learn|leave|lend|lie|light|lose|make|mean|meet|mislead|misspell|mistake|mistook|misunderstand|mow|outdid|outdo|outgrew|outgrow|outlay|outran|outride|outshine|overbore|overcame|overdo|overeat|overhang|overhear|overlay|overlay|overleap|overlie|overran|override|oversaw|oversee|overtake|overthrew|overthrow|overtook|overwrite|partake|partook|pay|plead|prove|ran|rang|rebuild|redid|redo|reeve|refit|regrow|relay|relight|remake|rend|repay|retake|retell|rethink|retook|rewind|rewrite|rewrote|ride|ring|rise|rived|rode|rose|sang|sank|saw|saw|say|see|seek|sell|send|sew|shake|shave|shear|sheared|shine|shoe|shook|shoot|show|showed|shrank|shrink|sing|sink|sit|slay|sleep|slide|sling|slink|smell|smite|sneak|sow|sowed|speak|speed|spell|spend|spill|spin|spoil|spoke|sprang|spring|stand|stank|stave|steal|stick|sting|stink|stole|strew|strewed|stride|strike|string|strip|strive|strode|strove|sunburn|swam|swear|sweep|swell|swelled|swim|swing|swore|take|teach|tear|tell|think|threw|thrive|throve|throw|took|tore|tread|troubleshoot|typewrite|unbend|unbind|undergo|underlay|underlay|underlie|undersell|understand|undertake|undertook|underwent|undid|undo|unlearn|unmake|unsay|unwind|uphold|vex|wake|was|waylay|wear|weave|wed|weep|went|whet|win|wind|withdraw|withdrew|withhold|withstand|woke|wore|wove|wring|write|wrote';
#   return 'abide|abode|alight|arise|arose|ate|awake|awoke|backbit|backbite|backslid|backslide|be|bear|became|befall|befell|began|beget|begin|begot|behold|bend|bereave|beseech|bestrew|betake|bethink|betook|bind|bit|bite|bleed|blew|blow|bore|break|breed|bring|broke|browbeat|build|burn|buy|came|catch|chide|choose|chose|clap|cling|clothe|colorbreed|creep|crossbreed|dare|daydream|deal|did|dig|disprove|dive|do|dove|drank|draw|dream|drew|drink|drive|drove|dwell|eat|enwind|fall|feed|feel|fell|fight|find|flee|flew|fling|fly|forbade|forbear|forbid|forbore|fordid|fordo|forego|foreknew|foreknow|foreran|foresaw|foresee|foreshow|foreshowed|forespeak|forespoke|foretell|forewent|forgave|forget|forgive|forgot|forsake|forsook|forswear|forswore|freeze|frostbit|frostbite|froze|gainsay|gave|get|gild|give|go|grew|grind|grow|hagride|hagrode|halterbreak|halterbroke|hamstring|hand-feed|handwrite|handwrote|hang|have|hear|heave|hew|hewed|hid|hide|hold|inbreed|inlay|interbreed|interlay|interweave|interwind|interwove|inweave|inwove|jerry-build|keep|kneel|knew|know|lade|laded|landslide|lay|lead|lean|leap|learn|leave|lend|lie|light|lose|make|mean|meet|misbecame|misdeal|misdid|misdo|mishear|mislay|mislead|mislearn|missay|missend|misspeak|misspell|misspend|misspoke|misswear|misswore|mistake|misteach|mistell|misthink|mistook|misunderstand|miswear|miswore|miswrite|miswrote|mow|outbreed|outdid|outdo|outdrank|outdraw|outdrew|outdrink|outdrive|outdrove|outfight|outflew|outfly|outgrew|outgrow|outlay|outleap|outlie|outran|outride|outrode|outsang|outsaw|outsee|outsell|outshine|outshoot|outsing|outsit|outsleep|outsmell|outspeak|outspeed|outspend|outspin|outspoke|outsprang|outspring|outstand|outswam|outswear|outswim|outswore|outtell|outthink|outthrew|outthrow|outwear|outwind|outwore|outwrite|outwrote|overate|overbear|overbore|overbreed|overbuild|overbuy|overcame|overdid|overdo|overdrank|overdraw|overdrew|overdrink|overeat|overfeed|overhang|overhear|overlay|overlay|overleap|overlie|overpay|overran|override|overrode|oversaw|oversee|oversell|oversew|oversewed|overshoot|oversleep|oversow|oversowed|overspeak|overspend|overspill|overspin|overspoke|oversprang|overspring|overstand|overstrew|overstrewed|overstride|overstrike|overstrode|overtake|overthink|overthrew|overthrow|overtook|overwear|overwind|overwore|overwrite|overwrote|partake|partook|pay|plead|prebuild|predid|predo|premake|prepay|presell|preshrank|preshrink|prove|quick-freeze|quick-froze|ran|rang|reawake|reawoke|rebind|rebuild|redeal|redid|redo|redraw|redrew|reeve|refit|regrew|regrind|regrow|rehang|rehear|reknit|relay|relearn|relight|remake|rend|repay|reran|resell|resend|resew|resewed|retake|reteach|retear|retell|rethink|retook|retore|rewake|rewear|reweave|rewin|rewind|rewoke|rewore|rewove|rewrite|rewrote|ride|ring|rise|rive|rived|rode|rose|sang|sank|saw|saw|say|see|seek|self-feed|self-sow|self-sowed|sell|send|sew|shake|shave|shear|sheared|shine|shoe|shook|shoot|show|showed|shrank|shrink|shrive|shrived|sing|sink|sit|skywrite|skywrote|slay|sleep|slide|sling|slink|smell|smite|sneak|sow|sowed|speak|speed|spell|spend|spill|spin|spoil|spoke|spoon-feed|sprang|spring|stall-feed|stand|stank|stave|steal|stick|sting|stink|stole|strew|strewed|stride|strike|string|strip|strive|strode|strove|sunburn|swam|swear|sweep|swell|swelled|swim|swing|swore|take|teach|tear|tell|test-drive|test-drove|test-flew|test-fly|think|threw|thrive|throve|throw|took|tore|tread|troubleshoot|typewrite|typewrote|unbear|unbend|unbind|unbore|unbuild|unclothe|underbuy|underfeed|undergo|underlay|underlay|underlie|underran|undersell|undershoot|underspend|understand|undertake|undertook|underwent|underwrite|underwrote|undid|undo|undraw|undrew|unfreeze|unfroze|unhang|unhid|unhide|unhold|unknit|unlade|unladed|unlay|unlead|unlearn|unmake|unreeve|unsay|unsew|unsewed|unsling|unspin|unstick|unstring|unswear|unswore|unteach|unthink|unweave|unwind|unwove|unwrite|unwrote|uphold|vex|wake|was|waylay|wear|weave|wed|weep|went|whet|win|wind|withdraw|withdrew|withhold|withstand|woke|wore|wove|wring|write|wrote';
}

sub loadPassiveRules
{
   addPath($voice, tense("simple present"), @("am", past()) );
   addPath($voice, tense("simple present"), @("is", past()) );
   addPath($voice, tense("simple present"), @("are", past()) );
   addPath($voice, tense("simple present"), @("is", past(), "by", "the"));
   addPath($voice, tense("simple present"), @("are", past(), "by", "the"));
   addPath($voice, tense("simple past"), @("was", past(), "by", "the"));
   addPath($voice, tense("simple past"), @("were", past(), "by", "the"));
   addPath($voice, tense("simple past"), @("was", past()) );
   addPath($voice, tense("simple past"), @("were", past()) );
   addPath($voice, tense("present continuous"), @("am", "being", past()));
   addPath($voice, tense("present continuous"), @("is", "being", past()));
   addPath($voice, tense("present continuous"), @("are", "being", past()));
   addPath($voice, tense("past continuous"), @("was", "being", past()));
   addPath($voice, tense("past continuous"), @("were", "being", past()));
   addPath($voice, tense("present perfect"), @("has", "been", past()));
   addPath($voice, tense("present perfect"), @("have", "been", past()));
   addPath($voice, tense("past perfect"), @("had", "been", past()));
   addPath($voice, tense("future perfect"), @("will", "have", "been", past()));
   addPath($voice, tense("future with will"), @("will", "be", past()));
   addPath($voice, tense("future with will not"), @("will", "not", "be"));
   addPath($voice, tense("future with won't"), @("won't", "be"));
   addPath($voice, tense("future with going to"), @("is", "going", "to", "be"));
   addPath($voice, tense("future with going to"), @("are", "going", "to", "be"));
   addPath($voice, tense("future with can"), @("can", "be"));
   addPath($voice, tense("future with can't"), @("can't", "be"));
   addPath($voice, tense("future with can not"), @("can", "not", "be"));
   addPath($voice, tense("future with may"), @("may", "be"));
   addPath($voice, tense("future with may not"), @("may", "not", "be"));
   addPath($voice, tense("future with might"), @("might", "not", "be"));
   addPath($voice, tense("future with might not"), @("might", "not", "be"));
   addPath($voice, tense("future with should"), @("should", "be"));
   addPath($voice, tense("future with shouldn't"), @("shouldn't", "be"));
   addPath($voice, tense("future with should not"), @("should", "not", "be"));
   addPath($voice, tense("future with ought to"), @("ought", "to", "be"));
   addPath($voice, tense("had better"), @("had", "better", "be"));
   addPath($voice, tense("had better not"), @("had", "better", "not", "be"));
   addPath($voice, tense("must"), @("must", "be"));
   addPath($voice, tense("must not"), @("must",  "not", "be"));
   addPath($voice, tense("to be"), @("to", "be"));
}

#
# nominilizations
#

sub nomit
{
   return '[a-z]+(ment|ion|ence|ance|ity|ent|ant|ancy)';
}

sub nom
{
   return %(recommendation => { return 'Use a strong verb for <em>' . split('\s+', $2)[$1["index"]] . '</em>'; },
            view => 'view/rules/nomit.slp',
            rule => 'Hidden Verbs',
            description => "A hidden verb (aka nominalization) is a verb made into a noun.  They often need extra words to make sense.  Strong verbs are easier to read and use less words.",
            style => 'green',
            category => 'Hidden Verb',
            index => $1
          );
}

sub loadNomRules
{
   local('$handle $text $v @t $idx $i');
   $handle = openf("data/rules/nomdb.txt");
   while $text (readln($handle))
   {
      $text = [$text trim];
      @t = split('\s+', $text);
      foreach $i => $v (@t)
      {
        if ($v eq "NOM")
        {
           $idx = $i;
           $v = nomit();
        }
      }

      addPath($voice, nom($idx), copy(@t));

      @t[0] = uc(charAt(@t[0], 0)) . substr(@t[0], 1);
      addPath($voice, nom($idx), @t);
   }
}

#
# grammar rules
#

sub toTagForm
{
   return map({ return split('/', $1); }, split(' ', $1));
}

# grammar("description", "suggestion", "...")
sub ghomophone
{
   return %(recommendation => {},
            view => "view/rules/homophone2.slp",
            options => iff(!-isarray $1, $1, join(',', $1)),
            description => "You may have used one word when you meant another.  A common cause of these errors are homophones.  A homophone is two words that sound alike but have different meanings and spellings.  Review the definition of the word you used and the word suggested.",
            rule => "Did you mean...",
            style => 'green',
            category => 'Grammar');
}

sub tryThisSuggestion
{
   return { return "Try: \"" . join("\" <b>or</b> \"", suggestions2(split(", ", $1["word"]), $2)) . "\""; };
}

sub grammar
{
   return %(recommendation => { return "Try: \"" . join("\" <b>or</b> \"", suggestions2(split(", ", $1["word"]), $2)) . "\""; },
            view => "view/rules/empty.slp",
            rule => $1,
            description => $3,
            style => 'green',
            category => 'Grammar');
}

sub loadGrammarRules
{
   local('$template');

   # missing prepositions
   $template = grammar("Missing Word", "", "A preposition indicates the relationship a noun has to another word. It's important that your writing has the right prepositions so your reader knows what you're talking about.");
   loadRules($rules, "data/rules/grammar/prepositions", $template);

   # missing determiners
   $template = grammar("Missing Word", "", "You're likely missing an article in this phrase. An article serves as a marker letting the reader know how many (or which) of the noun you're referring to.");
   loadRules($rules, "data/rules/grammar/determiners", $template);

   # a vs. an

   $template = ghomophone(@("a", "an"));
   $template['recommendation'] = { return "Try: \"" . suggestions2($1["word"], $2) . "\""; };
   $template['source'] = $null;
   $template['sourceurl'] = $null;
   $template['view'] = "view/rules/empty.slp";
   $template['rule'] = "Wrong article";
   $template['description'] = "<b>A</b> and <b>an</b> are indefinite articles.  An indefinite article is an adjective that says you want any of some noun.  For example \"I want a pony\" means I want any pony.<br><br>You select <b>a</b> or <b>an</b> based on the sound of the first letter of the following word.<br><br>If the first word starts with a vowel sound you use <b>an</b>.  If the first word has a consonant sound use <b>a</b>.";

   $template['recommendation'] = { return "Try: \"" . suggestions2($1["word"], $2) . "\""; };
   loadRules($rules, "data/rules/grammar/an", $template);

   # its vs. it's rules

   $template = ghomophone(@("it's", "its"));
   $template['recommendation'] = { return "\"" . suggestions2($1["word"], $2) . "\""; };

   loadRules($rules, "data/rules/grammar/its", $template); 
   loadRules($rules, "data/rules/grammar/its2", $template); 

   # where vs. were rules

   $template = ghomophone(@("were", "where"));
   $template['recommendation'] = { return "\"" . suggestions2($1["word"], $2) . "\""; };

   loadRules($rules, "data/rules/grammar/were", $template);

   # we're rules
   $template = ghomophone(@("we're", "were", "were"));
   $template['recommendation'] = { return "\"" . suggestions2($1["word"], $2) . "\""; };

   loadRules($rules, "data/rules/grammar/weare", $template);

   # your vs you're
   $template = ghomophone(@("your", "you're"));
   $template['recommendation'] = { return "\"" . suggestions2($1["word"], $2) . "\""; };

   loadRules($rules, "data/rules/grammar/your", $template);

   # too vs to
   $template = ghomophone(@("to", "too", "two"));
   $template['recommendation'] = { return "\"" . suggestions2($1["word"], $2) . "\""; };

   loadRules($rules, "data/rules/grammar/too", $template);
   
   # whose vs. who's
   $template = ghomophone(@("who's", "whose"));
   $template['recommendation'] = { return "\"" . suggestions2($1["word"], $2) . "\""; };

   loadRules($rules, "data/rules/grammar/whose", $template);
   
   # there vs. their
   $template = ghomophone(@("their", "there"));
   $template['recommendation'] = { return "\"" . suggestions2($1["word"], $2) . "\""; };

   loadRules($rules, "data/rules/grammar/their", $template);

   # misc confused words
   $template = ghomophone(@());
   $template['recommendation'] = { return "\"" . suggestions2($1["word"], $2) . "\""; };

   loadRules($rules, "data/rules/grammar/confused", $template);

   # contracted form of not
   loadRules($rules, "data/rules/grammar/contractedformnot", 
     grammar("Redundant not",
     "",
     "The contraction used here expands to not at the end.  This is redundant when combined with another not.")
   );

   # missing apostrophes
   loadRules($rules, "data/rules/grammar/apostrophes", %(style => "green", rule => "Missing apostrophe", recommendation => { return "\"" . suggestions2($1["word"], $2) . "\""; }, category => "Grammar", info => "none", view => "view/rules/empty.slp"));

   # repeated contractions
   loadRules($rules, "data/rules/grammar/repeats", %(style => "green", rule => "Redundant contraction", recommendation => { return "\"" . suggestions2($1["word"], $2) . "\""; }, category => "Grammar", info => "none", view => "view/rules/empty.slp"));
  
   # personal pronoun lowercase
   loadRules($rules, "data/rules/grammar/personal_pronoun_case",
     grammar("Make I uppercase",
      "",
      "The personal pronoun I is always uppercase. Contractions that use 'I' also require an upper-case I since they expand to two words e.g., I have and I will.")
   );
  
   # some misc rules
   loadRules($rules, "data/rules/grammar/misc", %(style => "green", rule => "Revise...", recommendation => { return "\"" . suggestions2($1["word"], $2) . "\""; }, category => "Grammar", info => "none", view => "view/rules/empty.slp"));

   # misheard phrases
   $template = grammar("Misheard Phrase", "", "Many typos come from writing phrases as we think we heard them, and not as they are.");
   loadRules($rules, "data/rules/grammar/misheard", $template);

   # subject verb agreement

   $template = grammar("Subject Verb Agreement", "", "In English, the subject has a count (singular, plural) and so does the verb.  These counts must agree for your sentence to be valid.");
   loadRules($rules, "data/rules/grammar/subject_verb_agreement", $template);
   loadRules($agreement, "data/rules/grammar/agreement", $template);

   # less vs. fewer
   $template = grammar("Less vs. Fewer", "", "Use the word <b>fewer</b> with countable nouns. Use the word <b>less</b> with uncountable nouns. <p>A countable noun is a noun that you can count. An uncountable noun is a noun that you can not count.</p><p>For example, it makes sense to say I have three dollars. Three money makes no sense. The noun dollars is countable. The noun money is not.</p>");
   loadRules($rules, "data/rules/grammar/count", $template); 

   # auxiliary verb agreement

   $template = grammar("Auxiliary Verb Agreement", "", "You need to use a past participle verb form after this auxiliary verb.  The words <b>has</b>, <b>had</b>, <b>have</b>, and <b>were</b> are auxiliary verbs that you should follow with a past participle.<br><br>Verbs that have the same simple past and past participle forms are known as regular verbs.  An irregular verb has different form for its past participle.  Apparently you encountered one of these.  Use the past participle form here and your sentence will make sense.");
   loadRules($rules, "data/rules/grammar/aux_noparticiple", $template);

   $template = grammar("Auxiliary Verb Agreement", "", "This auxiliary verb expects a past participle or present participle.  Revise your sentence with the right verb tense.");
   loadRules($rules, "data/rules/grammar/aux_been_was", $template);

   $template = grammar("Wrong Auxiliary Verb", "", "You used a plural noun with an auxiliary verb that expects a singular noun.  Revise your sentence with a different auxiliary verb or use a singular noun.");
   loadRules($rules, "data/rules/grammar/aux_wrong_verb", $template);

   $template = grammar("Auxiliary Verb Agreement", "", "You've used a present or past tense of a verb with this modal auxiliary verb.  Try using the base form of your verb to make this sentence make sense.");
   loadRules($rules, "data/rules/grammar/aux_modals", $template);

      # these rules look at <AUXILIARY VERB> <PREPOSITION> <TENSE>
   $template = grammar("Auxiliary Verb Agreement", "", "You've used the wrong verb tense with this auxiliary verb.  This doesn't make you a bad person.  Try using a different verb tense.");
   loadRules($rules, "data/rules/grammar/aux_wrong_tense", $template);

   # determiner agreement (plural vs. singular)

   $template = grammar("Determiner Agreement", "", "You used a singular noun after a determiner that expects a plural noun.  Revise your sentence with a different determiner or use a plural noun.");
   loadRules($rules, "data/rules/grammar/det_agreement_plural", $template);

   $template = grammar("Determiner Agreement", "", "The count (singular, plural) of your determiner and auxiliary verb need to agree.  Here they don't.  Use a different determiner or change your auxiliary verb.");
   loadRules($rules, "data/rules/grammar/det_agreement", $template);

   # infinitive phrases

   $template = grammar("Wrong Verb", "", "The word <b>to</b> followed by a verb marks the beginning of an infinitive phrase.  Use the base form of a verb in these phrases.");
   loadRules($rules, "data/rules/grammar/infinitives", $template);

   # indef articles with uncountable noun

   $template = grammar("Revise...", "", "You have used an indefinite article (a, an) with an uncountable noun.  Remove the article for the phrase to make sense.");
   loadRules($rules, "data/rules/grammar/indef_uncount", $template);

   # comprised vs. everything else

   loadRules($rules, "data/rules/grammar/comprised", grammar("Did you mean?", "", "A common mistake is to use comprise instead of compose or consists.  Saying some items comprises something else is to say those items are a part of that something else. Try mentally substituing comprise with constitutes.  If the resulting sentence makes sense, then you've used comprise correctly"));

   # lay vs. lie vs. laying etc..

   loadRules($rules, "data/rules/grammar/lay", grammar("Did you mean?", "", "Lay and lie are easy to confuse, they mean roughly the same thing.  Lay, a transitive verb, means put something in place and it requires an object to act on.  Lie, an intransitive verb, means to recline and does not take an object.  An easy way to remember what to use: you lie down, but you must lay something down.<br><br>Laid is the past tense of lay.  To make things confusing, lay is the past tense of lie."));

   # words to separate

   loadRules($rules, "data/rules/grammar/separate", %(style => "green", rule => "Separate...", recommendation => { return "\"" . suggestions2($1["word"], $2) . "\""; }, category => "Grammar", info => "none", view => "view/rules/empty.slp"));

   # words to combine

   loadRules($rules, "data/rules/grammar/combine", %(style => "green", rule => "Combine...", recommendation => { return "\"" . suggestions2($1["word"], $2) . "\""; }, category => "Grammar", info => "none", view => "view/rules/empty.slp"));
}

#
# possessive rules (usually converting a plural form word to a possessive)
#

sub possessive
{
   return %(word => tryThisSuggestion(),
             rule => "Possessive Ending",
             style => "green",
             category => "Grammar",
             filter => "none",
             view   => "view/rules/empty.slp",
             recommendation => { return "Use: \"" . suggestions2($1["word"], $2) . "\""; },
             description => 'A possessive noun form says that the noun owns something.  If the noun is singular and ends with s, z, or x you indicate possession with a single apostrophe at the end.  If the noun is plural and ends with an s you use a single apostrophe at the end as well.  Otherwise you indicate possession with an apostrophe s at the end of the word.'
    );
}

sub loadPossessiveRules
{
   loadRules($rules, "data/rules/grammar/possessive", possessive());
}

#
# hold the homophones...
#

sub homophone
{
   return %(recommendation => lambda({ return "Did you mean <i> $+ $word $+ </i>?"; }, $word => $1),
            word => $2,
            view => "view/rules/homophone.slp",
            rule => "Did you mean...",
            description => "You may have used one word when you meant another.  A common cause of these errors are homophones.  A homophone is two words that sound alike but have different meanings and spellings.  Review the definition of the word you used and the word suggested.",
            style => 'red',
            filter => 'homophone',
            category => 'Spelling');
}

sub loadHomophoneRules
{
   local('$handle $text $word $words %donotuse');

   # load homophone rules that we want to make exceptions for
   $handle = openf("data/rules/nohomophone.txt");
   map(lambda({ %donotuse[$1] = 1; }, \%donotuse), readAll($handle));
   closef($handle);

   $handle = openf("data/rules/homophonedb.txt");
   while $text (readln($handle))
   {
      $words = split(', ', $text);
      foreach $word ($words)
      {
         $word = [$word trim];

         if ($word !in %donotuse)
         {
            addPath($homophones, homophone($word, $text), @($word));
         }
      }
   }
}

#
# hyphenate words *pHEAR*
#

sub hyphenate
{
   return %(word => $1,
            rule => "Hyphen Required",
            style => 'green',
            info  => 'none',
            filter => 'none',
            category => 'Spelling');
}

sub loadHyphenRules
{
   import java.util.zip.*;
   import java.io.*;

   local('$stream $enum $entry $name');

   $handle = openf("models/dictionary.txt");
  
   while $name (readln($handle))
   {
      if ("*-" !iswm $name && "-*" !iswm $name && "-" isin $name)
      {
         local('$w1 $w2 $pw $pp $hyph');
         ($w1, $w2) = split('-', $name);

         if ($w1 in $dictionary && $w2 in $dictionary)
         {
            $pw = Pword($name);
            $pp = Pword("$w1 $w2");

            if ($pw > $pp)
            {
               addPath($rules, hyphenate($name), split('-', $name));
            }
         }
      }
   }   

   # add some nifty hyphenating rules
   loadRules($rules, "data/rules/hyphens.txt", hyphenate(""));
}

#
# Complex and Abstract Words
#

sub complex
{
   return %(recommendation => { return "Try a simpler word for <em> $+ $2 $+ </em>"; },
            word => $1,
            view => "view/rules/complex.slp",
            rule => "Complex Expression",
            description => "Where possible you should use a simple word over a complex word.  Simple words are easier to read and let your readers focus on your ideas.",
            style => 'yellow',
            category => 'Complex');
}

sub loadComplexRules
{
   local('$handle $text $bad $suggestion @rules $template');

   $handle = openf("data/rules/complexdb.txt");
   while $text (readln($handle))
   {
      ($bad, $suggestion) = split('\t+', $text);
      addPath($rules, complex($suggestion, $bad), split('\s+', $bad));
   }

   $template = complex();
   $template['recommendation'] = tryThisSuggestion();
   loadRules($rules, "data/rules/complex/been", $template);
   loadRules($rules, "data/rules/complex/misc", $template);
}

#
# Redundant Expressions
#

sub redundant_header
{
   local('$item $suggestion');

   $suggestion = $2;

   foreach $item (split(', ', $1["word"]))
   {
      $suggestion = replaceAt($suggestion, '<s><u>'.$item.'</u></s>', lindexOf($suggestion, $item), strlen($item));
   }

   return "Revise <em> $+ $suggestion $+ </em>"; 
}

sub applyChanges 
{
   local('$remove $c');
   $c = $1;
   foreach $remove (split('\s*,\s*', $2))
   {
      $c = strrep($c, $remove, '');
   }
#   warn("Rule is: $1 : $2 -> '" . [$c trim] . "'");
   return [$c trim];
}

sub redundant
{
   return %(recommendation => tryThisSuggestion(),
            view => "view/rules/empty.slp",
            word => applyChanges($2, $1),
            rule => "Redundant Expression",
            description => "You should avoid redundant expressions when possible.  A redundant expression has extra words that add no new meaning to the phrase.  By eliminating redundant expressions you will make your writing more clear and concise.",
            style => 'blue',
            category => 'Redundant');
}

sub loadRedundantRules
{
   local('$handle $text $expression $suggestion');

   $handle = openf("data/rules/redundantdb.txt");
   while $text (readln($handle))
   {
      ($expression, $suggestion) = split('\t+', $text);
      addPath($rules, redundant($suggestion, $expression), split('\s+', $expression));
   }   

   $template = redundant("");
   $template['recommendation'] = tryThisSuggestion();
   $template['filter'] = 'normal';
   loadRules($rules, "data/rules/redundant/misc", $template);
}

#
# bias rules (non-discrimination, gender neutral language)
# 

sub bias
{
   return %(recommendation => { return "Reword $2"; },
            view => "view/rules/bias.slp",
            rule => "Bias Language",
            description => "Bias words and phrases may express gender, ethnic, or racial bias.  These can turn people off.  Bias-free language has the same meaning and treats people with respect.",
            style => 'yellow',
            word => $1,
            category => 'Bias');
}

sub loadBiasRules
{
   local('$handle $text $expression $suggestion');

   $handle = openf("data/rules/biasdb.txt");
   while $text (readln($handle))
   {
      ($expression, $suggestion) = split('\t+', $text);
#      println("$[30]expression ... $suggestion");
      [$expression trim];
      [$suggestion trim];
      addPath($rules, bias($suggestion), split('\s+', $expression));
   }   
}

#
# cliche rules
#

sub cliche
{
   return %(recommendation => { return "Avoid \"<em> $+ $2 $+ </em>\""; },
            view => "view/rules/empty.slp",
            rule => "Cliches",
            description => 'Clich&eacute;s are phrases used so much they lose their original power.  Try revising the meaning of this phrase using your own words.  It will make a stronger impact on your reader.', 
            style => 'yellow',
            category => 'Cliche');
}

sub didYouMeanRule
{
   return %(recommendation => { return "Avoid \"<em> $+ $2 $+ </em>\""; },
            view => "view/rules/avoid.slp",
            rule => "Phrases to Avoid",
            description => "These phrases are misleading, vague, or talk down to your reader.  Consider avoiding them.",
            word => $1,
            style => 'yellow',
            category => 'Phrases to Avoid');
}

sub loadClicheRules
{
   local('$handle $text $trans $t');

   $handle = openf("data/rules/clichedb.txt");
   while $text (readln($handle))
   {
      addPath($voice, cliche($text), split('\s+', $text));
   }   

   $handle = openf("data/rules/avoiddb.txt");
   while $text (readln($handle))
   {
      ($t, $trans) = split('\t+', $text);
      addPath($voice, didYouMeanRule($trans), split('\s+', $t));
   }
}

#
# double negative rules
#

sub dneg
{
   return %(recommendation => tryThisSuggestion(),
            view => "view/rules/empty.slp",
            rule => "Double Negative",
            description => 'Two negatives in a sentence cancel each other out.  Sadly, this fact is not always obvious to your reader.  Try rewriting your sentence to emphasize the positive.',
            style => 'green',
            category => 'Double Negative');
}

sub negWords
{
   return 'until|unless|except|notwithstanding|un\w+|dis\w+|terminate|void|insufficient|cant|dont|not|wont|no';
}

sub loadDoubleNegativeRules
{
   loadRules($rules, "data/rules/grammar/dneg2", dneg());
}

#
# jargon rules
#

sub jargon
{
   return %(recommendation => { return "Replace <em> $+ $2 $+ </em>"; },
            word => $1,
            view => "view/rules/complex.slp",
            rule => "Jargon Language",
            description => 'Foreign words, jargon, and abbrevations will confuse those who don\'t know them.  Your readers may skip phrases they don\'t understand.  Help them out by using a plain term.',
            style => 'yellow',
            category => 'Complex');
}

sub loadJargonRules
{
   local('$handle $text $bad $suggestion @rules');

   $handle = openf("data/rules/foreigndb.txt");
   while $text (readln($handle))
   {
      ($bad, $suggestion) = split('\t+', $text);
      addPath($rules, jargon($suggestion, $bad), split('\s+', $bad));
   }
}

#
# Diacritic Rules
#
sub diacritics
{
   return %(recommendation => { return 'Accent your writing, try: <em>' . suggestions2(@($1['word']), $2)[0] . '</em>'; },
            view => "view/rules/empty.slp",
            rule => 'Diacritical Marks',
            description => 'English borrows many words from other languages. These borrowed words sometimes lose their accents in common use. Restore the accent to clarify which word you\'re referring to.
<br>
<br><b>Examples</b>
<br>
<br>Would you like to resume writing your resumé?
<br>
<br>For your sake, would you like some saké?',
            style => 'yellow',
            category => 'Diacritical Marks');
}

sub loadDiacriticRules
{
   local('$template');

   loadRules($rules, "data/rules/diacritic/main", diacritics() );

   $template = diacritics();
   $template['description'] = 'Proper nouns keep their accents as they refer to specific people, places, or things.';

   loadRules($voice, "data/rules/diacritic/propernouns", $template );

   $template = diacritics();
   $template['description'] = 'An old (and now uncommon) convention in English is to add a diaeresis to the second of two consecutive vowels in a word. This tells the reader to pronounce the second vowel separately as-in: coöperate, rëenter, etc.';

   loadRules($voice, "data/rules/diacritic/diaeresis", $template);
}

#
# load the rules
#

if (getFileName($__SCRIPT__) eq "rules.sl")
{
   loadHomophoneRules();
   loadGrammarRules();
   loadDiacriticRules();
   loadPossessiveRules();
   loadPassiveRules();
   loadNomRules();
   loadBiasRules();
   loadJargonRules();
   loadRedundantRules();
   loadClicheRules();
   loadDoubleNegativeRules();
   loadComplexRules();
   loadHyphenRules();

   $rcount = countRules($rules) + countRules($homophones) + countRules($agreement) + countRules($voice);
   $rcount = substr($rcount, 0, -3) . ',' . right($rcount, 3);

   [{
      local('$handle');

      $handle = openf(">models/rules.bin");
      writeObject($handle, $rcount);

      writeObject($handle, $homophones);
      writeObject($handle, $rules);
      writeObject($handle, $agreement);
      writeObject($handle, $voice);

      closef($handle);
   }];

   println("--- Normal rules:    " . countRules($rules));
   println("--- Homophone rules: " . countRules($homophones));
   println("--- Agreement rules: " . countRules($agreement));
   println("--- Voice  rules:    " . countRules($voice));
   println("Loaded $rcount rules... wheee");
}

