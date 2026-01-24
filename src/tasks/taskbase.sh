#!/bin/bash
TASKSBEINGRUN=()

function runTaskWithRunnerIfNeeded() {
    local args=("$@")

    local task="$1"
    
    local runner="$2"
    local runnerArgs=()
    arrayCopyOfRange args runnerArgs 2 "${#args[@]}"

    arrayExecOnceWithKey "$task" "TASKSBEINGRUN" "$runner" "$task" "${runnerArgs[@]}"
    return $?
}

function singleExecuteRunnerRelativeToProject() {
    local args=("$@")

    # Parse command
    local task="$1"
    local runnerArgs=()
    arrayCopyOfRange args runnerArgs 1 "${#args[@]}"

    # Get project properties
    local localProjectDir="$LOCALPROJECT"
    local baseProjectDir="$BASEPROJECT"
    local rootProjectDir="$ROOTPROJECT"
    local localProjectId="${projectsByDir[$localProjectDir]}"
    local baseProjectId="${projectsByDir[$baseProjectDir]}"
    local rootProjectId="${projectsByDir[$rootProjectDir]}"
    
    # First use the local project
    taskFound=false
    taskRunnerProjectSingle "$task" "$localProjectId" "$localProjectDir" "$runnerArgs"
    exit=$?
    if [ "$exit" != 0 ]; then
        return $exit
    fi
    if [ "$taskFound" == "true" ]; then
        return $exit
    fi
    taskRunnerProjectSingle "$task" "$baseProjectId" "$baseProjectDir" "$runnerArgs"
    exit=$?
    if [ "$exit" != 0 ]; then
        return $exit
    fi
    if [ "$taskFound" == "true" ]; then
        return $exit
    fi
    taskRunnerProjectSingle "$task" "$rootProjectId" "$rootProjectDir" "$runnerArgs"
    exit=$?
    if [ "$exit" != 0 ]; then
        return $exit
    fi
    if [ "$taskFound" == "true" ]; then
        return $exit
    fi

    # Try finding it in the runtime
    local runtimeTaskDir="$RUNTIMEPATH/builtin/tasks"
    if [ -d "$runtimeTaskDir" ]; then
        # Find task
        execTasksSingle "$task" "$runtimeTaskDir" false "" "" "${runnerArgs[@]}"

    fi

    # Not found
    return 1
}

function taskRunnerProjectSingle() {
    local args=("$@")

    # Parse command
    local task="$1"
    local projectId="$2"
    local projectDir="$3"
    local runnerArgs=()
    arrayCopyOfRange args runnerArgs 3 "${#args[@]}"

    # Check found
    if [ "$taskFound" == "true" ]; then
        return 0
    fi

    # Find task
    execTasksSingle "$task" "$projectDir/tasks" true "$projectId" "$projectDir" "${runnerArgs[@]}"
    exit=$?
    if [ "$taskFound" == "true" ]; then
        return $exit
    fi

    # Get list ID
    local subprojectListId="${projectsSubProjectSetIds["$projectId"]}"

    # Go through sub projects recursively
    # We stay relative to the current project
    eval 'subprojectsList=("${'"subprojects_$subprojectListId"'[@]}")'
    for subProjectId in "${subprojectsList[@]}"; do
        local subProjectDir="${projects["$subProjectId"]}"

        # Run in subproject
        taskRunnerProjectSingle "$task" "$subProjectId" "$subProjectDir" "${runnerArgs[@]}"
        exit=$?
        if [ "$exit" != 0 ]; then
            return $exit
        fi
        if [ "$taskFound" == "true" ]; then
            return $exit
        fi
    done

    # Go through dependencies recursively
    # We stay relative to the current project
    eval 'dependenciesList=("${'"dependencies_$subprojectListId"'[@]}")'
    for depId in "${dependenciesList[@]}"; do
        local depDir="${projects["$depId"]}"

        # Run in dependency
        taskRunnerProjectSingle "$task" "$depId" "$depDir" "${runnerArgs[@]}"
        exit=$?
        if [ "$exit" != 0 ]; then
            return $exit
        fi
        if [ "$taskFound" == "true" ]; then
            return $exit
        fi
    done
}

function execTasksSingle() {
    local args=("$@")

    # Parse command
    local task="$1"
    local tasksDir="$2"
    local isProject="$3" # if false, its a runtime task
    local projectId="$4"
    local projectDir="$5"
    local runnerArgs=()
    arrayCopyOfRange args runnerArgs 5 "${#args[@]}"

    # Find task
    if [ -d "$tasksDir" ]; then
        # Try to find task
        if [ -f "$tasksDir/$task.task" ]; then
            # Found task
            taskFound=true

            # Load task
            setupTaskEnvironment "$task" "$tasksDir/$task.task" "$isProject" "$projectId" "$projectDir" "${runnerArgs[@]}"
            source "$tasksDir/$task.task"

            # Call prepare
            if type "${task}_prepare" &>/dev/null; then
                runFunctionSafe "${task}_prepare" "${runnerArgs[@]}"
            fi

            # Call run
            runFunctionSafe "${task}_run" "${runnerArgs[@]}"

            # Call finish
            if type "${task}_finish" &>/dev/null; then
                runFunctionSafe "${task}_finish" "${runnerArgs[@]}"
            fi

            # Clean environment
            cleanTaskEnvironment "$task" "$tasksDir/$task.task" "$isProject" "$projectId" "$projectDir" "${runnerArgs[@]}"

            # Return
            return $exit
        fi
    fi
    return 1
}
