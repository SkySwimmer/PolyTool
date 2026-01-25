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

function runTaskWithRunner() {
    local args=("$@")

    local task="$1"
    
    local runner="$2"
    local runnerArgs=()
    arrayCopyOfRange args runnerArgs 2 "${#args[@]}"

    runFunctionSafe "$runner" "$task" "${runnerArgs[@]}"
    return $?
}

function singleExecuteRunner() {
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
    local exit=$?
    if [ "$exit" != 0 ]; then
        return $exit
    fi
    if [ "$taskFound" == "true" ]; then
        return $exit
    fi
    taskRunnerProjectSingle "$task" "$baseProjectId" "$baseProjectDir" "$runnerArgs"
    local exit=$?
    if [ "$exit" != 0 ]; then
        return $exit
    fi
    if [ "$taskFound" == "true" ]; then
        return $exit
    fi
    taskRunnerProjectSingle "$task" "$rootProjectId" "$rootProjectDir" "$runnerArgs"
    local exit=$?
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
        local exit=$?
         if [ "$exit" != 0 ]; then
            return $exit
        fi
        if [ "$taskFound" == "true" ]; then
            return $exit
        fi
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
    local exit=$?
    if [ "$exit" != 0 ] && [ "$taskFound" == "true" ]; then
        return $exit
    fi
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
        runFuncLocalToProjTaskSys "$subProjectId" taskRunnerProjectSingle "$task" "$subProjectId" "$subProjectDir" "${runnerArgs[@]}"
        local exit=$?
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
        runFuncLocalToProjTaskSys "$depId" taskRunnerProjectSingle "$task" "$depId" "$depDir" "${runnerArgs[@]}"
        local exit=$?
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
                local exit=$?
                if [ "$exit" != 0 ]; then
                    cleanTaskEnvironment "$task" "$tasksDir/$task.task" "$isProject" "$projectId" "$projectDir" "${runnerArgs[@]}"
                    return $exit
                fi
            fi

            # Call run
            runFunctionSafe "${task}_run" "${runnerArgs[@]}"
            local exit=$?
            if [ "$exit" != 0 ]; then
                cleanTaskEnvironment "$task" "$tasksDir/$task.task" "$isProject" "$projectId" "$projectDir" "${runnerArgs[@]}"
                return $exit
            fi

            # Call finish
            if type "${task}_finish" &>/dev/null; then
                runFunctionSafe "${task}_finish" "${runnerArgs[@]}"
                local exit=$?
                if [ "$exit" != 0 ]; then
                    cleanTaskEnvironment "$task" "$tasksDir/$task.task" "$isProject" "$projectId" "$projectDir" "${runnerArgs[@]}"
                    return $exit
                fi
            fi

            # Clean environment
            cleanTaskEnvironment "$task" "$tasksDir/$task.task" "$isProject" "$projectId" "$projectDir" "${runnerArgs[@]}"

            # Return
            return $exit
        fi
    fi
    return 1
}


function allExecuteRunner() {
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
    taskRunnerProjectAllPrepare "$task" "$localProjectId" "$localProjectDir" "$runnerArgs"
    local exit=$?
    if [ "$exit" != 0 ]; then
        return $exit
    fi
    taskRunnerProjectAllPrepare "$task" "$baseProjectId" "$baseProjectDir" "$runnerArgs"
    local exit=$?
    if [ "$exit" != 0 ]; then
        return $exit
    fi
    taskRunnerProjectAllPrepare "$task" "$rootProjectId" "$rootProjectDir" "$runnerArgs"
    local exit=$?
    if [ "$exit" != 0 ]; then
        return $exit
    fi

    # Try finding it in the runtime
    local runtimeTaskDir="$RUNTIMEPATH/builtin/tasks"
    if [ -d "$runtimeTaskDir" ]; then
        # Find task
        execTasksAllPrepare "$task" "$runtimeTaskDir" false "" "" "${runnerArgs[@]}"
        local exit=$?
        if [ "$exit" != 0 ]; then
            return $exit
        fi
    fi

    # Check found
    if [ "$taskFound" != "true" ]; then
        # No tasks found
        echo ERROR
        return 1
    fi

    # Call run
    taskRunnerProjectAllRun "$task" "$localProjectId" "$localProjectDir" "$runnerArgs"
    local exit=$?
    if [ "$exit" != 0 ]; then
        return $exit
    fi
    taskRunnerProjectAllRun "$task" "$baseProjectId" "$baseProjectDir" "$runnerArgs"
    local exit=$?
    if [ "$exit" != 0 ]; then
        return $exit
    fi
    taskRunnerProjectAllRun "$task" "$rootProjectId" "$rootProjectDir" "$runnerArgs"
    local exit=$?
    if [ "$exit" != 0 ]; then
        return $exit
    fi

    # Try finding it in the runtime
    local runtimeTaskDir="$RUNTIMEPATH/builtin/tasks"
    if [ -d "$runtimeTaskDir" ]; then
        # Find task
        execTasksAllRun "$task" "$runtimeTaskDir" false "" "" "${runnerArgs[@]}"
        local exit=$?
        if [ "$exit" != 0 ]; then
            return $exit
        fi
    fi

    # Call run
    taskRunnerProjectAllFinish "$task" "$localProjectId" "$localProjectDir" "$runnerArgs"
    local exit=$?
    if [ "$exit" != 0 ]; then
        return $exit
    fi
    taskRunnerProjectAllFinish "$task" "$baseProjectId" "$baseProjectDir" "$runnerArgs"
    local exit=$?
    if [ "$exit" != 0 ]; then
        return $exit
    fi
    taskRunnerProjectAllFinish "$task" "$rootProjectId" "$rootProjectDir" "$runnerArgs"
    local exit=$?
    if [ "$exit" != 0 ]; then
        return $exit
    fi

    # Try finding it in the runtime
    local runtimeTaskDir="$RUNTIMEPATH/builtin/tasks"
    if [ -d "$runtimeTaskDir" ]; then
        # Find task
        execTasksAllFinish "$task" "$runtimeTaskDir" false "" "" "${runnerArgs[@]}"
        local exit=$?
        if [ "$exit" != 0 ]; then
            return $exit
        fi
    fi

    # Success
    return 0
}

function taskRunnerProjectAllPrepare() {
    local args=("$@")

    # Parse command
    local task="$1"
    local projectId="$2"
    local projectDir="$3"
    local runnerArgs=()
    arrayCopyOfRange args runnerArgs 3 "${#args[@]}"

    # Find task
    execTasksAllPrepare "$task" "$projectDir/tasks" true "$projectId" "$projectDir" "${runnerArgs[@]}"
    local exit=$?
    if [ "$exit" != 0 ]; then
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
        runFuncLocalToProjTaskSys "$subProjectId" taskRunnerProjectAllPrepare "$task" "$subProjectId" "$subProjectDir" "${runnerArgs[@]}"
        local exit=$?
        if [ "$exit" != 0 ]; then
            return $exit
        fi
    done

    # Go through dependencies recursively
    # We stay relative to the current project
    eval 'dependenciesList=("${'"dependencies_$subprojectListId"'[@]}")'
    for depId in "${dependenciesList[@]}"; do
        local depDir="${projects["$depId"]}"

        # Run in dependency
        runFuncLocalToProjTaskSys "$depId" taskRunnerProjectAllPrepare "$task" "$depId" "$depDir" "${runnerArgs[@]}"
        local exit=$?
        if [ "$exit" != 0 ]; then
            return $exit
        fi
    done
}

function taskRunnerProjectAllRun() {
    local args=("$@")

    # Parse command
    local task="$1"
    local projectId="$2"
    local projectDir="$3"
    local runnerArgs=()
    arrayCopyOfRange args runnerArgs 3 "${#args[@]}"

    # Find task
    execTasksAllRun "$task" "$projectDir/tasks" true "$projectId" "$projectDir" "${runnerArgs[@]}"
    local exit=$?
    if [ "$exit" != 0 ]; then
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
        runFuncLocalToProjTaskSys "$subProjectId" taskRunnerProjectAllRun "$task" "$subProjectId" "$subProjectDir" "${runnerArgs[@]}"
        local exit=$?
        if [ "$exit" != 0 ]; then
            return $exit
        fi
    done

    # Go through dependencies recursively
    # We stay relative to the current project
    eval 'dependenciesList=("${'"dependencies_$subprojectListId"'[@]}")'
    for depId in "${dependenciesList[@]}"; do
        local depDir="${projects["$depId"]}"

        # Run in dependency
        runFuncLocalToProjTaskSys "$depId" taskRunnerProjectAllRun "$task" "$depId" "$depDir" "${runnerArgs[@]}"
        local exit=$?
        if [ "$exit" != 0 ]; then
            return $exit
        fi
    done
}

function taskRunnerProjectAllFinish() {
    local args=("$@")

    # Parse command
    local task="$1"
    local projectId="$2"
    local projectDir="$3"
    local runnerArgs=()
    arrayCopyOfRange args runnerArgs 3 "${#args[@]}"

    # Find task
    execTasksAllFinish "$task" "$projectDir/tasks" true "$projectId" "$projectDir" "${runnerArgs[@]}"
    local exit=$?
    if [ "$exit" != 0 ]; then
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
        runFuncLocalToProjTaskSys "$subProjectId" taskRunnerProjectAllFinish "$task" "$subProjectId" "$subProjectDir" "${runnerArgs[@]}"
        local exit=$?
        if [ "$exit" != 0 ]; then
            return $exit
        fi
    done

    # Go through dependencies recursively
    # We stay relative to the current project
    eval 'dependenciesList=("${'"dependencies_$subprojectListId"'[@]}")'
    for depId in "${dependenciesList[@]}"; do
        local depDir="${projects["$depId"]}"

        # Run in dependency
        runFuncLocalToProjTaskSys "$depId" taskRunnerProjectAllFinish "$tas" "$depId" "$depDir" "${runnerArgs[@]}"
        local exit=$?
        if [ "$exit" != 0 ]; then
            return $exit
        fi
    done
}

function execTasksAllPrepare() {
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
                local exit=$?
                if [ "$exit" != 0 ]; then
                    cleanTaskEnvironment "$task" "$tasksDir/$task.task" "$isProject" "$projectId" "$projectDir" "${runnerArgs[@]}"
                    return $exit
                fi
            fi

            # Clean environment
            cleanTaskEnvironment "$task" "$tasksDir/$task.task" "$isProject" "$projectId" "$projectDir" "${runnerArgs[@]}"

            # Return
            return $exit
        fi
    fi
}

function execTasksAllRun() {
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

            # Call run
            runFunctionSafe "${task}_run" "${runnerArgs[@]}"
            local exit=$?
            if [ "$exit" != 0 ]; then
                cleanTaskEnvironment "$task" "$tasksDir/$task.task" "$isProject" "$projectId" "$projectDir" "${runnerArgs[@]}"
                return $exit
            fi

            # Clean environment
            cleanTaskEnvironment "$task" "$tasksDir/$task.task" "$isProject" "$projectId" "$projectDir" "${runnerArgs[@]}"

            # Return
            return $exit
        fi
    fi
}

function execTasksAllFinish() {
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

            # Call finish
            if type "${task}_finish" &>/dev/null; then
                runFunctionSafe "${task}_finish" "${runnerArgs[@]}"
                local exit=$?
                if [ "$exit" != 0 ]; then
                    cleanTaskEnvironment "$task" "$tasksDir/$task.task" "$isProject" "$projectId" "$projectDir" "${runnerArgs[@]}"
                    return $exit
                fi
            fi

            # Clean environment
            cleanTaskEnvironment "$task" "$tasksDir/$task.task" "$isProject" "$projectId" "$projectDir" "${runnerArgs[@]}"

            # Return
            return $exit
        fi
    fi
}

function runFuncLocalToProjTaskSys() {
    local args=("$@")

    # Parse command
    local project="$1"
    local function="$2"
    local functionParams=()
    arrayCopyOfRange args functionParams 2 "${#args[@]}"

    # Find project
    local projectPath="${projects["$project"]}"
    if [ "$projectPath" == "" ]; then
        # Found project with same ID but at different location
        crash "Call error: project not recognized: $project"
        return 1
    fi

    # Get project properties
    local baseForProject="${projectsBaseProject["$project"]}"
    local baseBuildForProject="${projectsBaseProject["$project"]}/build"
    local currentBaseProject="$BASEPROJECT"
    local currentBaseBuild="$BASEBUILDDIR"
    local currentBaseId="$BASEPROJECTID"
    local currentProjectId="$PROJECTID"
    local currentProjectBuild="$BUILDDIR"
    local currentProject="$LOCALPROJECT"

    # Update
    BASEPROJECT="$baseForProject"
    BASEBUILDDIR="$baseBuildForProject"
    BASEPROJECTID="$project"
    PROJECTID="$project"
    BUILDDIR="$projectPath/build"
    LOCALPROJECT="$projectPath"

    # Call
    runFunctionSafe "$function" "${functionParams[@]}"
    local exit=$?
    
    # Restore
    BASEPROJECT="$currentBaseProject"
    BASEBUILDDIR="$currentBaseBuild"
    BASEPROJECTID="$currentBaseId"
    PROJECTID="$currentProjectid"
    BUILDDIR="$currentProjectBuild"
    LOCALPROJECT="$currentProject"
    return $exit
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
