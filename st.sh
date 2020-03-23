tokei -s lines -f -t=D -e tests
dscanner --styleCheck \
    | grep -v Assert.condition.is.always.true
git status
