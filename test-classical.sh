#!/usr/bin/env bash

source altcalconv.sh

function whatever {
    echo "whatever $1 to stdout"
    stderr "whatever $1 to stderr"
    return 42
}

out=$(whatever "something else")
echo "ret:$?"
echo "out:$out"

