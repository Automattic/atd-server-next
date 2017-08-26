#!/bin/sh
svn export https://openatd.svn.wordpress.org/atd-server/models/cnetwork.bin ./models/cnetwork.bin
svn export https://openatd.svn.wordpress.org/atd-server/models/cnetwork2.bin ./models/cnetwork2.bin
svn export https://openatd.svn.wordpress.org/atd-server/models/dictionary.txt ./models/dictionary.txt
svn export https://openatd.svn.wordpress.org/atd-server/models/edits.bin ./models/edits.bin
svn export https://openatd.svn.wordpress.org/atd-server/models/endings.bin ./models/endings.bin
svn export https://openatd.svn.wordpress.org/atd-server/models/hnetwork.bin ./models/hnetwork.bin
svn export https://openatd.svn.wordpress.org/atd-server/models/hnetwork2.bin ./models/hnetwork2.bin
svn export https://openatd.svn.wordpress.org/atd-server/models/hnetwork4.bin ./models/hnetwork4.bin
svn export https://openatd.svn.wordpress.org/atd-server/models/lexicon.bin ./models/lexicon.bin
svn export https://openatd.svn.wordpress.org/atd-server/models/model.bin ./models/model.bin
svn export https://openatd.svn.wordpress.org/atd-server/models/model.zip ./models/model.zip
svn export https://openatd.svn.wordpress.org/atd-server/models/network3f.bin ./models/network3f.bin
svn export https://openatd.svn.wordpress.org/atd-server/models/network3p.bin ./models/network3p.bin
svn export https://openatd.svn.wordpress.org/atd-server/models/not_misspelled.txt ./models/not_misspelled.txt
svn export https://openatd.svn.wordpress.org/atd-server/models/stringpool.bin ./models/stringpool.bin
svn export https://openatd.svn.wordpress.org/atd-server/models/trigrams.bin ./models/trigrams.bin
./bin/buildrules.sh
