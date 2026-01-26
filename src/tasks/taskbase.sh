#!/bin/bash
TASKS_FOUND=()
TASKS_RELATIVE_TO_CALLER=()
TASKS_PERMITTING_MULTIRUN=()
TASKSBEINGRUN_PREPARE=()
TASKSBEINGRUN_RUN=()
TASKSBEINGRUN_FINISH=()

CALLINGTASKSLIST=()
TASKS_RUNTIME_SHARED=()

function taskLoadError() {
    1>&2 echo "Error: could not load task \"$1\": an error occurred while evaluating the task"
    exit 1
}

function taskSensitiveRunLocalToProject() {
    local args=("$@")

    # Get cwd
    local currentId="$id"
    local currentCwd="$PWD"

    # Parse command
    local isProject="$1"
    local projectId="$2"
    local task="$3"
    local targetProject="$4"
    local function="$5"
    local functionParams=()
    arrayCopyOfRange args functionParams 5 "${#args[@]}"

    # Get key
    local taskKey="$projectId-$task"
    if [ "$isProject" != true ]; then
        taskKey="RUNTIME@$LOCALPROJECTID@$task"
    fi

    # Check properties
    if arrayContains "$taskKey" TASKS_RELATIVE_TO_CALLER; then
        # Run right here
        runFunctionSafe "$function" "${functionParams[@]}"
    else
        # Run local to target
        runLocalToProject "$targetProject" "$function" "${functionParams[@]}"
    fi
}
