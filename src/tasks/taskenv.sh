#!/bin/bash

function callTask() {
    # Task caller function
    local args=("$@")

    # Parse command
    local task="$1"
    local taskParams=()
    arrayCopyOfRange args taskParams 1 "${#args[@]}"

    # Run task if needed
    runTaskWithRunnerIfNeeded "$task" singleExecuteRunner "$@"
    local result=$?
    if [ "$result" != 0 ]; then
        1>&2 echo "Error: task not recognized: $task"
        printStackTrace 1
        return 1
    fi
}
