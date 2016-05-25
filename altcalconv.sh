#!/usr/bin/env bash

#------------------------------------------------------
# main exports
#------------------------------------------------------

function transmit {
    declare -ag __stack__=()
    for i in $@; do
        __stack__+=("$i")
    done
}

function assign {
    if _callingDealWithLocal "$@" ; then
        shift
        local local=local
    fi
    local vars=$(_callingDealWithVars "$local" "local var=\$(__pop idx)" "$@")
    local assign_shift=$(selfSharedMemLoad assign_shift)
    shift $assign_shift
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

function selfSharedMemSave {
    local varName=$1
    local varValue="$2"
    echo "$varValue" > /dev/shm/$varName.$_pid        
}

function selfSharedMemLoad {
    local varName=$1
    local varValue=$(cat /dev/shm/$varName.$_pid)
    echo "$varValue"
}

function selfSharedMemRemove {
    local varName=$1
    rm -f /dev/shm/$varName.$_pid
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
# private functions
#------------------------------------------------------

_pid=$$

function __pop {
    echo "${__stack__[$1]}"
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
        local varClause=$(echo "$varTemplate" | sed -e "s/local/$local/g" -e "s/var/$1/g" -e "s/idx/$i/g" )
        local vars=$(append "$vars" "; " "$varClause")
        shift
        ((i=i+1))
    done
    selfSharedMemSave assign_shift $i
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

