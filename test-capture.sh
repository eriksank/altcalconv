#!/usr/bin/env bash

source altcalconv.sh

function whatever {
    echo "whatever $1 to stdout"
    stderr "whatever $1 to stderr"
    return 42
}

#source <(capture x1 x2 x3 := whatever "hello \"friends")
eval $(capture x1 x2 x3 := whatever "hello \"friends")
echo "x1:$x1 x2:$x2 x3:$x3"

