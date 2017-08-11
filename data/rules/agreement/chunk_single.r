.*/NNP [a-z]+/NN or [a-z]+/PRP.* [a-z]+/NN::\0 \1 and \3 \4
.*/NNP [a-z]+/NNS or [a-z]+/PRP.* [a-z]+/NN::\0 \1 and \3 \4
A [a-z]+/NN or [a-z]+/NN::\0 \1 and \3
An [a-z]+/NN or [a-z]+/NN::\0 \1 and \3
.*/NNP or [a-z]+/NNP::\0 and \2
Every one of [a-z]+/DT [a-z]+/NNS::\3:upper \4
One of [a-z]+/PRP.* [a-z]+/NNS::\2:upper \3
Each one of [a-z]+/PRP.* [a-z]+/NNS::\3:upper \4
The [a-z]+/NN [a-z]+/IN::\0 \1:plural \2
The [a-z]+/NN::\0 \1:plural
This [a-z]+/NN [a-z]+/IN::These \1:plural \2
This [a-z]+/NN::These \1:plural
One of [a-z]+/DT [a-z]+/NNS::\2:upper \3
.*/NNP,POS [a-z]+/JJ [a-z]+/NN::\0 \1 \2:plural
.*/NNP,POS [a-z]+/NN::\0 \1:plural
The [a-z]+/NN [a-z]+/IN [a-z]+/DT [a-z]+/NN::\0 \1:plural \2 \3 \4
This [a-z]+/NN [a-z]+/IN [a-z]+/DT [a-z]+/NN::These \1:plural \2 \3 \4
.*/RB one
The [a-z]+/JJ [a-z]+/NN::\0 \1 \2:plural
This [a-z]+/JJ [a-z]+/NN::\0 \1 \2:plural
Their [a-z]+/NN::\0 \1:plural
Their [a-z]+/JJ [a-z]+/NN::\0 \1 \2:plural
Their [a-z]+/JJ [a-z]+/NN [a-z]+/VB::\0 \1 \2 \3:plural
Your [a-z]+/NN::\0 \1:plural
Your [a-z]+/JJ [a-z]+/NN::\0 \1 \2:plural
Your [a-z]+/JJ [a-z]+/NN [a-z]+/VB::\0 \1 \2 \3:plural
His [a-z]+/NN::\0 \1:plural
His [a-z]+/JJ [a-z]+/NN::\0 \1 \2:plural
His [a-z]+/JJ [a-z]+/NN [a-z]+/VB::\0 \1 \2 \3:plural
Her [a-z]+/NN::\0 \1:plural
Her [a-z]+/JJ [a-z]+/NN::\0 \1 \2:plural
Her [a-z]+/JJ [a-z]+/NN [a-z]+/VB::\0 \1 \2 \3:plural
My [a-z]+/NN::\0 \1:plural
My [a-z]+/JJ [a-z]+/NN::\0 \1 \2:plural
My [a-z]+/JJ [a-z]+/NN [a-z]+/VB::\0 \1 \2 \3:plural
The [a-z]+/VBN [a-z]+/NN::\0 \1 \2:plural
This [a-z]+/VBN [a-z]+/NN::\0 \1 \2:plural
.*/CD dollars|pounds|points|feet|inches|meters
The [a-z]+/NN [a-z]+/VB [a-z]+/NN::\0 \1 \2 \3:plural
The [a-z]+/NN [a-z]+/VB [a-z]+/NN [a-z]+/VBP [a-z]+/JJ [a-z]+/NN
The [a-z]+/JJ [a-z]+/NN [a-z]+/VBP [a-z]+/JJ [a-z]+/NN
The [a-z]+/NN of [a-z]+/VB [a-z]+/NN::\0 \1 \2 \3 \4:plural
The [a-z]+/NN [a-z]+/VB
The [a-z]+/NN of [a-z]+/VB [a-z]+/NNS::\0 \1:plural of \3 \4
Either [a-z]+/NN
.*/NN::\0:plural
Either [a-z]+/NNP [a-z]+/NNS or [a-z]+/PRP.* [a-z]+/NN::\1:upper \2 and \4 \5
