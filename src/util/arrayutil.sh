#!/bin/bash

function arrayContains {
    local key="$1"
    local array="$2"
    eval 'local arrIn=("${'"$array"'[@]}")'

    # Check
    for entry in "${arrIn[@]}"; do
        if [ "$entry" == "$key" ]; then
            return 0
        fi
    done
    return 1
}

function arrayCopyOfRange {
    local array="$1"
    local target="$2"
    local start="$3"
    local end="$4"
    local i=0
    local arrOut=()
    eval 'local arrIn=("${'"$array"'[@]}")'
    for arg in "${arrIn[@]}"; do
        if ((i < start)); then
            i=$((i + 1))
            continue
        elif ((i >= end)); then
            break
        fi
        
        arrOut+=("$arg")
        i=$((i + 1))
    done
    eval "$target"'=("${arrOut[@]}")'
}

function arrayExecOnceWithKey {
    local args=("$@")

    local key="$1"
    local array="$2"

    local function="$3"
    local functionParams=()
    arrayCopyOfRange args functionParams 3 "${#args[@]}"

    # Check
    if ! arrayContains "$key" "$array" ; then
        # Run
        eval "$array+=(\"$key\")"
        runFunctionSafe "$function" "${functionParams[@]}"
        return $?
    fi
}
