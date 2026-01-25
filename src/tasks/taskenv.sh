#!/bin/bash

function callTaskClearStack() {
    # Task caller function
    local args=("$@")

    # Check
    if [ "$1" == "" ]; then
        1>&2 echo "Error: missing argument 'task' in callTaskClearStack"
        printStackTrace 1
        exit 1
    fi

    # Parse command
    local task="$1"
    local taskParams=()
    arrayCopyOfRange args taskParams 1 "${#args[@]}"

    # Box recursion list, clear it
    local callTaskListLast=("${CALLINGTASKSLIST[@]}")
    CALLINGTASKSLIST=()

    # Run task if needed
    taskFound=false
    runTaskWithRunnerIfNeeded "$task" relativeExecuteRunner "$@"
    local result=$?

    # Revert list
    CALLINGTASKSLIST=("${callTaskListLast[@]}")

    # Handle
    if [ "$result" != 0 ]; then
        if [ "$taskFound" != true ]; then
            1>&2 echo "Error: task not recognized: $task"
            printStackTrace 1
            return 1
        else
            1>&2 echo "Error: task exited with non-zero exit code"
            printStackTrace 1
            return $result
        fi
    fi
}

function callTaskForcedClearStack() {
    # Task caller function
    local args=("$@")

    # Check
    if [ "$1" == "" ]; then
        1>&2 echo "Error: missing argument 'task' in callTaskForcedClearStack"
        printStackTrace 1
        exit 1
    fi

    # Parse command
    local task="$1"
    local taskParams=()
    arrayCopyOfRange args taskParams 1 "${#args[@]}"

    # Box recursion list, clear it
    local callTaskListLast=("${CALLINGTASKSLIST[@]}")
    CALLINGTASKSLIST=()

    # Run task if needed
    taskFound=false
    runTaskWithRunner "$task" relativeExecuteRunner "$@"
    local result=$?

    # Revert list
    CALLINGTASKSLIST=("${callTaskListLast[@]}")

    # Handle
    if [ "$result" != 0 ]; then
        if [ "$taskFound" != true ]; then
            1>&2 echo "Error: task not recognized: $task"
            printStackTrace 1
            return 1
        else
            1>&2 echo "Error: task exited with non-zero exit code"
            printStackTrace 1
            return $result
        fi
    fi
}

function callSingleTaskClearStack() {
    # Task caller function
    local args=("$@")

    # Check
    if [ "$1" == "" ]; then
        1>&2 echo "Error: missing argument 'task' in callSingleTaskClearStack"
        printStackTrace 1
        exit 1
    fi

    # Parse command
    local task="$1"
    local taskParams=()
    arrayCopyOfRange args taskParams 1 "${#args[@]}"

    # Box recursion list, clear it
    local callTaskListLast=("${CALLINGTASKSLIST[@]}")
    CALLINGTASKSLIST=()

    # Run task if needed
    taskFound=false
    runTaskWithRunnerIfNeeded "$task" singleExecuteRunner "$@"
    local result=$?

    # Revert list
    CALLINGTASKSLIST=("${callTaskListLast[@]}")

    # Handle
    if [ "$result" != 0 ]; then
        if [ "$taskFound" != true ]; then
            1>&2 echo "Error: task not recognized: $task"
            printStackTrace 1
            return 1
        else
            1>&2 echo "Error: task exited with non-zero exit code"
            printStackTrace 1
            return $result
        fi
    fi
}

function callSingleTaskForcedClearStack() {
    # Task caller function
    local args=("$@")

    # Check
    if [ "$1" == "" ]; then
        1>&2 echo "Error: missing argument 'task' in callSingleTaskForcedClearStack"
        printStackTrace 1
        exit 1
    fi

    # Parse command
    local task="$1"
    local taskParams=()
    arrayCopyOfRange args taskParams 1 "${#args[@]}"

    # Box recursion list, clear it
    local callTaskListLast=("${CALLINGTASKSLIST[@]}")
    CALLINGTASKSLIST=()

    # Run task if needed
    taskFound=false
    runTaskWithRunner "$task" singleExecuteRunner "$@"
    local result=$?

    # Revert list
    CALLINGTASKSLIST=("${callTaskListLast[@]}")

    # Handle
    if [ "$result" != 0 ]; then
        if [ "$taskFound" != true ]; then
            1>&2 echo "Error: task not recognized: $task"
            printStackTrace 1
            return 1
        else
            1>&2 echo "Error: task exited with non-zero exit code"
            printStackTrace 1
            return $result
        fi
    fi
}

function callTask() {
    # Task caller function
    local args=("$@")

    # Check
    if [ "$1" == "" ]; then
        1>&2 echo "Error: missing argument 'task' in callTask"
        printStackTrace 1
        exit 1
    fi

    # Parse command
    local task="$1"
    local taskParams=()
    arrayCopyOfRange args taskParams 1 "${#args[@]}"

    # Run task if needed
    taskFound=false
    runTaskWithRunnerIfNeeded "$task" relativeExecuteRunner "$@"
    local result=$?

    # Handle
    if [ "$result" != 0 ]; then
        if [ "$taskFound" != true ]; then
            1>&2 echo "Error: task not recognized: $task"
            printStackTrace 1
            return 1
        else
            1>&2 echo "Error: task exited with non-zero exit code"
            printStackTrace 1
            return $result
        fi
    fi
}

function callTaskForced() {
    # Task caller function
    local args=("$@")

    # Check
    if [ "$1" == "" ]; then
        1>&2 echo "Error: missing argument 'task' in callTaskForced"
        printStackTrace 1
        exit 1
    fi

    # Parse command
    local task="$1"
    local taskParams=()
    arrayCopyOfRange args taskParams 1 "${#args[@]}"

    # Run task if needed
    taskFound=false
    runTaskWithRunner "$task" relativeExecuteRunner "$@"
    local result=$?
    
    # Handle
    if [ "$result" != 0 ]; then
        if [ "$taskFound" != true ]; then
            1>&2 echo "Error: task not recognized: $task"
            printStackTrace 1
            return 1
        else
            1>&2 echo "Error: task exited with non-zero exit code"
            printStackTrace 1
            return $result
        fi
    fi
}

function callSingleTask() {
    # Task caller function
    local args=("$@")

    # Check
    if [ "$1" == "" ]; then
        1>&2 echo "Error: missing argument 'task' in callSingleTask"
        printStackTrace 1
        exit 1
    fi
    
    # Parse command
    local task="$1"
    local taskParams=()
    arrayCopyOfRange args taskParams 1 "${#args[@]}"

    # Run task if needed
    taskFound=false
    runTaskWithRunnerIfNeeded "$task" singleExecuteRunner "$@"
    local result=$?
    
    # Handle
    if [ "$result" != 0 ]; then
        if [ "$taskFound" != true ]; then
            1>&2 echo "Error: task not recognized: $task"
            printStackTrace 1
            return 1
        else
            1>&2 echo "Error: task exited with non-zero exit code"
            printStackTrace 1
            return $result
        fi
    fi
}

function callSingleTaskForced() {
    # Task caller function
    local args=("$@")

    # Check
    if [ "$1" == "" ]; then
        1>&2 echo "Error: missing argument 'task' in callSingleTaskForced"
        printStackTrace 1
        exit 1
    fi
    
    # Parse command
    local task="$1"
    local taskParams=()
    arrayCopyOfRange args taskParams 1 "${#args[@]}"

    # Run task if needed
    taskFound=false
    runTaskWithRunner "$task" singleExecuteRunner "$@"
    local result=$?
    
    # Handle
    if [ "$result" != 0 ]; then
        if [ "$taskFound" != true ]; then
            1>&2 echo "Error: task not recognized: $task"
            printStackTrace 1
            return 1
        else
            1>&2 echo "Error: task exited with non-zero exit code"
            printStackTrace 1
            return $result
        fi
    fi
}

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

    # Apply local properties to properties
    PROPERTIES+=("${LOCALPROPERTIES[@]}")

    # Read arguments
    local skip=0
    local i=0
    local len="${#runnerArgs[@]}"
    for arg in "${runnerArgs[@]}"; do
        # Check argument
        if ((skip > 0)); then
            skip=$((skip-1))
            continue
        fi
        if [[ "$arg" == "--"* ]]; then 
            # Substring it
            local key="${arg#*--}"
            local valuePresent=false
            local valueKeyPresent=false
            local valueKey=""
            local value=""

            # Check syntax
            if [[ "$key" == *:* ]]; then
                valueKey="${key#*:}"
                key="${key%:*}"
                valueKeyPresent=true
                if [[ "$valueKey" == *=* ]]; then
                    value="${valueKey#*=}"
                    valueKey="${valueKey%=*}"
                    valuePresent=true
                fi
            fi

            # Check key
            if ([ "$key" == "assign-local" ] || [ "$key" == "assign-global" ] || [ "$key" == "local-property" ] || [ "$key" == "global-property" ]); then
                if [ "$valueKeyPresent" != true ] && ((i + 1 < len)); then
                    i=$((i+1))
                    skip=$((skip+1))
                    valueKey="${runnerArgs[$i]}"
                    valueKeyPresent=true
                    if [[ "$valueKey" == *=* ]]; then
                        value="${valueKey#*=}"
                        valueKey="${valueKey%=*}"
                        valuePresent=true
                    fi
                fi
                if [ "$valuePresent" != true ] && ((i + 1 < len)); then
                    i=$((i+1))
                    skip=$((skip+1))
                    value="${runnerArgs[$i]}"
                    valuePresent=true
                fi
                if [ "$valuePresent" == true ] && [ "$valueKeyPresent" == true ]; then
                    # Update properties
                    PROPERTIES+=(["$key"]="$value")
                fi
            fi
        elif ([[ "$arg" == "-X"* ]] || [[ "$arg" == "-P"* ]]); then 
            # Global is handled by the polytool main method, but lets still assign here
            # -X = assign global
            # -P = assign property
            local key="${arg#*-X}"
            if [[ "$key" == *=* ]]; then
                value="${arg#*=}"
                key="${key%=*}"
                
                # Update properties
                PROPERTIES+=(["$key"]="$value")
            fi
        fi
        i=$((i+1))
    done

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

    # Clean up environment
    # FIXME    
}

function setupTaskDefineEnvironment() {
    local args=("$@")

    # Parse command
    local task="$1"
    local taskFile="$2"
    local isProject="$3" # if false, its a runtime task
    local projectId="$4"
    local projectDir="$5"
    local runnerArgs=()
    arrayCopyOfRange args runnerArgs 5 "${#args[@]}"

    # Defaults
    allowMultiExecute=false
    runtimeTaskShared=false
}

function applyTaskDefineEnvironment() {
    local args=("$@")

    # Parse command
    local task="$1"
    local taskFile="$2"
    local isProject="$3" # if false, its a runtime task
    local projectId="$4"
    local projectDir="$5"
    local runnerArgs=()
    arrayCopyOfRange args runnerArgs 5 "${#args[@]}"

    # Handle settings    
    if [ "$runtimeTaskShared" == true ]; then
        if [ "$isProject" != true ]; then
            TASKS_RUNTIME_SHARED+=("$task")
            if ! arrayContains "RUNTIME@$task" TASKSBEINGRUN_PREPARE && arrayContains "RUNTIME@$LOCALPROJECTID@$task" TASKSBEINGRUN_PREPARE; then
                # Add
                TASKSBEINGRUN_PREPARE+=("RUNTIME@$task")
            fi
            if ! arrayContains "RUNTIME@$task" TASKSBEINGRUN_RUN && arrayContains "RUNTIME@$LOCALPROJECTID@$task" TASKSBEINGRUN_RUN; then
                # Add
                TASKSBEINGRUN_RUN+=("RUNTIME@$task")
            fi
            if ! arrayContains "RUNTIME@$task" TASKSBEINGRUN_FINISH && arrayContains "RUNTIME@$LOCALPROJECTID@$task" TASKSBEINGRUN_FINISH; then
                # Add
                TASKSBEINGRUN_FINISH+=("RUNTIME@$task")
            fi
        fi
    fi
    if [ "$allowMultiExecute" == true ]; then
        if [ "$isProject" == true ]; then
            TASKS_PERMITTING_MULTIRUN+=("$projectId-$task")
        elif arrayContains "$task" TASKS_RUNTIME_SHARED ; then
            TASKS_PERMITTING_MULTIRUN+=("RUNTIME@$task")
        else
            TASKS_PERMITTING_MULTIRUN+=("RUNTIME@$LOCALPROJECTID@$task")
        fi
    fi
}

function cleanTaskDefineEnvironment() {
    local args=("$@")

    # Parse command
    local task="$1"
    local taskFile="$2"
    local isProject="$3" # if false, its a runtime task
    local projectId="$4"
    local projectDir="$5"
    local runnerArgs=()
    arrayCopyOfRange args runnerArgs 5 "${#args[@]}"

    # Reset
    unset allowMultiExecute
    unset runtimeTaskShared
}

