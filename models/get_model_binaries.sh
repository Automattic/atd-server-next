#!/bin/sh
svn export https://openatd.svn.wordpress.org/atd-server/models/cnetwork.bin
svn export https://openatd.svn.wordpress.org/atd-server/models/cnetwork2.bin
svn export https://openatd.svn.wordpress.org/atd-server/models/dictionary.txt
svn export https://openatd.svn.wordpress.org/atd-server/models/edits.bin
svn export https://openatd.svn.wordpress.org/atd-server/models/endings.bin
svn export https://openatd.svn.wordpress.org/atd-server/models/hnetwork.bin
svn export https://openatd.svn.wordpress.org/atd-server/models/hnetwork2.bin
svn export https://openatd.svn.wordpress.org/atd-server/models/hnetwork4.bin
svn export https://openatd.svn.wordpress.org/atd-server/models/lexicon.bin
svn export https://openatd.svn.wordpress.org/atd-server/models/model.bin
svn export https://openatd.svn.wordpress.org/atd-server/models/model.zip
svn export https://openatd.svn.wordpress.org/atd-server/models/network3f.bin
svn export https://openatd.svn.wordpress.org/atd-server/models/network3p.bin
svn export https://openatd.svn.wordpress.org/atd-server/models/not_misspelled.txt
svn export https://openatd.svn.wordpress.org/atd-server/models/stringpool.bin
svn export https://openatd.svn.wordpress.org/atd-server/models/trigrams.bin
./bin/buildrules.sh
