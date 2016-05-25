#!/usr/bin/env bash

source altcalconv.sh

function func2 {
    transmit 4 3 12 $1
}

#source <(assign x1 x2 x3 x4 := func2 whatever)
eval $(assign x1 x2 x3 x4 := func2 whatever)
echo "x1:$x1 x2:$x2 x3:$x3 x4:$x4"

