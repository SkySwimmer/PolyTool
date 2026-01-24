#!/bin/bash

function main() {    
    # Check dependencies
    local missingdep=false
    for cmd in "${requiredCommands[@]}"; do
        if ! checkInstalled "$cmd" ; then
            1>&2 echo "Error: missing required command $cmd, please make sure to install this dependency via your system package manager."
            missingdep=true
        fi
    done
    if [ "$missingdep" == "true" ]; then
        1>&2 echo "Error: cannot proceed, missing requirements"
        exit 1
    fi

    # Load project
    echo Loading projects...
    if ! loadProject "<root>" "$PWD" "<root project>" ; then
        if [ ! -f "$PWD/polyfile.pcb" ] && [ ! -f "$PWD/Polyfile.pcb" ]; then
            1>&2 echo "Error: cannot proceed, please make sure the polyfile exists prior to running polytool"
        else
            1>&2 echo "Error: cannot proceed, root project could not be loaded"
        fi
        exit 1
    fi 
    ROOTPROJECTID="$id"

    # Done loading
    echo

    # Setup
    echo "Root project: $name ($id), version $version"
    echo "Preparing environment..."
    # FIXME: set up    

    # FIXME tests
    loadProject "<root>" "$PWD" "<root project>"
    loadProject "<root>" "$PWD" "<root project>"
    loadProject "<root>" "$PWD" "<root project>"
    runLocalToProject testsub runTaskWithRunnerIfNeeded test singleExecuteRunnerRelativeToProject
    runLocalToProject testsub runTaskWithRunnerIfNeeded test singleExecuteRunnerRelativeToProject
    runLocalToProject testsub runTaskWithRunnerIfNeeded test singleExecuteRunnerRelativeToProject
}
