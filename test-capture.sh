#!/usr/bin/env bash

source altcalconv.sh

function whatever {
    echo "whatever $1 to stdout"
    stderr "whatever $1 to stderr"
    return 42
}

#source <(capture ret out err := whatever "hello \"friends")
eval $(capture ret out err := whatever "hello \"friends")
echo "ret:$ret out:$out err:$err"

