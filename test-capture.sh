#!/usr/bin/env bash

source altcalconv.sh

function mycommand {
    echo "mycommand $1 to stdout"
    stderr "mycommand $1 to stderr"
    return 42
}

eval $(capture ret out err := mycommand "hello friends")
echo "ret:$ret out:$out err:$err"

