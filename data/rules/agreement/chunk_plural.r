The [a-z]+/JJ two|three|four|five|six|seven|eight|nine|ten|hundred|thousand|million|billion|trillion
My|Your|His|Her|Their pants
.*/NNP [a-z]+/NN and [a-z]+/PRP.* [a-z]+/NN::\0 \1 or \3 \4
.*/NNP [a-z]+/NNS and [a-z]+/PRP.* [a-z]+/NN::\0 \1 or \3 \4
.*/NNP and [a-z]+/NNP::\0 or \2
.*/NNP and [a-z]+/PRP.* [a-z]+/NNS::\0 or \2 \3:singular
The [a-z]+/NN and [a-z]+/DT [a-z]+/NNS::\0 \1 or \3 \4:singular 
The [a-z]+/NN or [a-z]+/DT [a-z]+/NNS::\0 \1 \2 \3 \4:singular
The [a-z]+/NN and [a-z]+/NN::The \1 or \3
The [a-z]+/NNS::\0 \1:singular
The [a-z]+/NNS::\0 \1:singular
These [a-z]+/NN and [a-z]+/DT [a-z]+/NNS::The \1 or the \4:singular
These [a-z]+/NN or [a-z]+/DT [a-z]+/NNS::word=The \1 \2 the \4:singular
These [a-z]+/NNS::The \1:singular
All||all of [a-z]+/DT [a-z]+/NNS::\2:upper \3:singular
The [a-z]+/NNS of|for [a-z]+/NN::\0 \1:singular \2 \3
These [a-z]+/NNS of|for [a-z]+/NN::Each \1:singular \2 \3
The [a-z]+/NNS of|for [a-z]+/JJ [a-z]+/NN::\0 \1:singular \2 \3 \4
These [a-z]+/NNS of|for [a-z]+/JJ [a-z]+/NN::Each \1:singular \2 \3 \4
.*/NNP,POS [a-z]+/NNS::\0 \1:singular
.*/NNP,POS [a-z]+/NNS in [a-z]+/DT [a-z]+/NN::\0 \1:singular \2 \3 \4
The [a-z]+/JJS [a-z]+/JJ [a-z]+/NNS of|for|from [a-z]+/NN [a-z]+/NN::\0 \1 \2 \3:singular \4 \5 \6
The [a-z]+/JJS [a-z]+/JJ [a-z]+/NNS::\0 \1 \2 \3:singular
.*/NNS of|for|from [a-z]+/NNS::\0:singular \1 \2:singular
.*/NNP,POS [a-z]+/NNS in [a-z]+/DT [a-z]+/NN::\0 \1:singular \2 \3 \4
.*/CD [a-z]+/NNS
The series of [a-z]+ [a-z]+/NNS::\0 \1 \2 \3 \4:singular
The series of [a-z]+/NNS::\0 \1 \2 \3:singular
The/DT [a-z]+/NN [a-z]+/IN [a-z]+/VB [a-z]+/NNS::\0 \1 \2 \3 \4:singular
The [a-z]+/NN [a-z]+/VB [a-z]+/NNS::\0 \1 \2 \3:singular
My [a-z]+/NN [a-z]+/VB [a-z]+/NNS::\0 \1 \2 \3:singular
Your [a-z]+/NN [a-z]+/VB [a-z]+/NNS::\0 \1 \2 \3:singular
His [a-z]+/NN [a-z]+/VB [a-z]+/NNS::\0 \1 \2 \3:singular
Her [a-z]+/NN [a-z]+/VB [a-z]+/NNS::\0 \1 \2 \3:singular
My [a-z]+/NNS::\0 \1:singular
Your [a-z]+/NNS::\0 \1:singular
Their [a-z]+/NNS::\0 \1:singular
His [a-z]+/NNS::\0 \1:singular
Her [a-z]+/NNS::\0 \1:singular
.*/JJ [a-z]+/NNS::\0 \1:singular
The [a-z]+/NN [a-z]+/IN [a-z]+/VB [a-z]+/NNS
My [a-z]+/NNS and I
My [a-z]+/NN and I
