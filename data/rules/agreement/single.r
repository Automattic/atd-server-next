*prefix* are::word=*text* is, *transform*::avoid=police, sheep, will, cannot, i, read, majority, half, might, let, let's::filter=sane
*prefix* were::word=*text* was, *transform*::avoid=police, sheep, will, cannot, i, read, majority, half, might, let, let's::filter=sane
*prefix* don't::word=*text* doesn't, *transform*::avoid=police, sheep, will, cannot, i, read, majority, half, might, let, let's::filter=sane
*prefix* [a-z]+/VBP::word=*text* \X:plural, *transform*::avoid=police, sheep, will, cannot, i, read, majority, half, might, let::filter=sane
*prefix* be::filter=kill
*prefix* by::filter=kill
*prefix* [a-z]+/VB is::filter=kill
*prefix* [a-z]+/VB of|for::filter=kill
*prefix* [a-z]+/VB [a-z]+/VBD|VBZ::filter=kill
*prefix* [a-z]+/VB::word=*text* \X:plural, *transform*::avoid=police, sheep, will, cannot, i, read, majority, half, might, let, let's::filter=sane
*prefix* are [a-z]+/VBN::filter=kill
*prefix* [a-z]+/MD::filter=kill
One|Two|Three|Four|Five|Six|Seven|Eight|Nine|Ten|Eleven|Twelve|Thirteen|Fourteen|Fifteen|Sixteen|Seventeen|Eighteen|Nineteen|Twenty|Thirty|Fourty|Fifty|Sixty|Seventy|Eighty|Ninenty dollars|pounds|points|feet|inches|meters::filter=kill
