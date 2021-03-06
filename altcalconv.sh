#!/usr/bin/env bash

#------------------------------------------------------
# fix the _pid variable once 
#------------------------------------------------------

#fix this, if you ever want to support multithreading
__pid=$$
function _pid {
    return $__pid
}

#------------------------------------------------------
# main exports
#------------------------------------------------------

function transmit {
    eval "declare -ag $(_pid)__stack__=()"
    for i in $@; do
        eval "$(_pid)__stack__+=(\"$i\")"
    done
}

function assign {
    if _callingDealWithLocal "$@" ; then
        shift
        local local=local
    fi
    read -r toShift vars <<< $(_callingDealWithVars "$local" "local var=\$(__pop idx)" "$@")
    shift $toShift
    exitIfDifferent $1 := ":= expected"
    shift
    local command=$(_callingDealWithCommand "$@")
    exitIfEmpty $command "missing command in assigment"
    echo "$command; $vars; unset __stack__"
}

function capture {
    if _callingDealWithLocal "$@" ; then
        shift
        local local=local
    fi
    eval $(_captureCommandText "$@") | sed -e "s/declare --/$local/g"
}

#------------------------------------------------------
# additional exports
#------------------------------------------------------

function equal {
    if [ "$1" = "$2" ] ; then
        return 0
    else
        return 1
    fi
}

function empty {
    equal $1 ""
}

function append {
        local list="$1"
        local separator="$2"
        local item="$3"
        if empty $list ; then
            echo "$item"
        else
            echo "$list$separator$item"
        fi
}

function stderr {
    >&2 echo "$@"
}

function exitIfDifferent {
    if ! equal "$1" "$2"; then
        stderr "$3"
        exit 1
    fi
}

function exitIfEmpty {
    if empty $1 ; then
        stderr "$2"
        exit 1
    fi
}

#------------------------------------------------------
# private implementation
#------------------------------------------------------

function __pop {
    eval echo \${$(_pid)__stack__[$1]}
}

function _callingDealWithLocal {
    if equal $1 'local'; then
        return 0
    fi
    return 1
}

function _callingDealWithVars {
    declare -g _shift
    local local="$1"
    shift
    local varTemplate="$1"
    shift
    local i=0
    local vars=""
    while ! equal $1 := ; do
        if equal $# 0 ; then
            break
        fi
        local varClause=$(echo "$varTemplate" | \
                    sed -e "s/local/$local/g" -e "s/var/$1/g" -e "s/idx/$i/g" )
        local vars=$(append "$vars" "; " "$varClause")
        shift
        ((i=i+1))
    done
    if equal $i 0 ; then
        stderr "error: no variables available to assign to"
    fi
    echo $i
    echo "$vars"
}

function _callingDealWithCommand {
    local command=$1
    shift
    while ! equal $# 0 ; do
        local arg=$(echo "$1" | sed 's/"/\\"/g')
        local command=$(append "$command" " " "\"$arg\"")
        shift
    done
    echo "$command"
}

function _captureCommandText {
    local retCodeVar=$1
    local stdoutVar=$2
    local stderrVar=$3
    exitIfDifferent $4 := ":= expected"
    shift 4
    local command=$(_callingDealWithCommand "$@")
    echo "{ $stderrVar=\$( { $stdoutVar=\$($command); $retCodeVar=\$?; } 2>&1; 
        declare -p $stdoutVar $retCodeVar >&2 ) ; declare -p $stderrVar; } 2>&1 "
}

#------------------------------------------------------

