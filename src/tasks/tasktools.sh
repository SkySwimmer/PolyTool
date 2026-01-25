#!/bin/bash

function runTask() {
    local args=("$@")

    # Parse
    local task="$1"    
    local taskArgs=()
    arrayCopyOfRange args taskArgs 2 "${#args[@]}"

    # Run
    runTaskWithRunnerIfNeeded "$task" "allExecuteRunner" "${taskArgs[@]}"
    return $?
}

function runTaskWithRunnerIfNeeded() {
    local args=("$@")

    # Parse
    local task="$1"    
    local runner="$2"
    local runnerArgs=()
    arrayCopyOfRange args runnerArgs 2 "${#args[@]}"

    # Run
    runFunctionSafe "$runner" true "$task" "${runnerArgs[@]}"
    return $?
}

function runTaskWithRunner() {
    local args=("$@")

    # Parse
    local task="$1"
    local runner="$2"
    local runnerArgs=()
    arrayCopyOfRange args runnerArgs 2 "${#args[@]}"

    # Run
    runFunctionSafe "$runner" false "$task" "${runnerArgs[@]}"
    return $?
}
