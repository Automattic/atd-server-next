./bin/compilespelltools.sh # don't do this as the build box doesn't have ant on it (yet)

#
# set some vars that may help the cause.
#
export LC_CTYPE=en_US.UTF-8
export LANG=en_US.UTF-8

#
# build the foundational NLP models
#
./bin/buildmodel.sh
#./bin/buildtaggersets.sh  # do not uncomment this

#
# intermediate stuff
#
./bin/buildrules.sh
./bin/testgr.sh
./bin/buildedits.sh

#
# train various models
#
#./bin/traintagger.sh     # no good reason to do this unless tagger data changes
./bin/trainspellcontext.sh
./bin/trainspellnocontext.sh
./bin/trainhomophones.sh
