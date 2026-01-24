#!/bin/bash

function setupTaskEnvironment() {
    local args=("$@")

    # Parse command
    local task="$1"
    local taskFile="$2"
    local isProject="$3" # if false, its a runtime task
    local projectId="$4"
    local projectDir="$5"
    local runnerArgs=()
    arrayCopyOfRange args runnerArgs 5 "${#args[@]}"

    # Set up environment
    # FIXME
}

function cleanTaskEnvironment() {
    local args=("$@")

    # Parse command
    local task="$1"
    local taskFile="$2"
    local isProject="$3" # if false, its a runtime task
    local projectId="$4"
    local projectDir="$5"
    local runnerArgs=()
    arrayCopyOfRange args runnerArgs 5 "${#args[@]}"

    # Set up environment
    # FIXME    
}