#!/usr/bin/env bash

source altcalconv.sh

function func2 {
    transmit 4 3 12 $(((99+$1)))
}

eval $(assign x1 x2 x3 x4 := func2 53)
echo "x1:$x1 x2:$x2 x3:$x3 x4:$x4"

