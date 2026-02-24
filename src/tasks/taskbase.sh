#!/bin/bash
TASKS_FOUND=()
TASKS_RELATIVE_TO_CALLER=()
TASKS_PERMITTING_MULTIRUN=()
TASKSBEINGRUN_PREPARE=()
TASKSBEINGRUN_RUN=()
TASKSBEINGRUN_FINISH=()
TASKS_RUNTIME_SHARED=()

function taskLoadError() {
    1>&2 echo "Error: could not load task \"$1\": an error occurred while evaluating the task"
    exit 1
}

function runTask() {
    local args=("$@")

    # Parse
    local task="$1"    
    local taskArgs=()
    arrayCopyOfRange args taskArgs 1 "${#args[@]}"

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

function loadIndividualTask() {
    local taskName="$1"
    
    # Resolve task
    resolveTask "$taskName" callbackLoadTask
}

function callbackLoadTask() {
    # Parse command
    local task="$1"
    local taskFile="$2"
    local isProject="$3" # if false, its a runtime task
    local projectId="$4"
    local projectDir="$5"

    # Get last env
    declare -A taskEnvLast=()
    copyAssociativeArray PROPERTIES taskEnvLast
    PROPERTIES=()

    # Populate properties
    copyAssociativeArray GLOBALPROPERTIES PROPERTIES
    copyAssociativeArray LOCALPROPERTIES PROPERTIES
    copyAssociativeArray taskEnvLast PROPERTIES

    # Load task
    setupTaskEnvironment "$task" "$taskFile" "$isProject" "$projectId" "$projectDir"
    source "$taskFile" || taskLoadError "$task.task"

    # Check local
    local localTaskFile="${projectsPolyLocalFolders["$LOCALPROJECTID"]}/tasks/$task.task"
    if [ -f "$localTaskFile" ]; then
        # Local overload
        source "$localTaskFile" || taskLoadError "<local>/polylocal/tasks/$task.task"
    fi

    # Set up
    dependsList=()
    loadOntoList=()
    loadAfterList=()
    loadBeforeList=()

    # Define
    if type "${task}_define" &>/dev/null; then
        # Set up environment
        setupTaskDefineEnvironment "$task" "$tasksDir/$task.task" "$isProject" "$projectId" "$projectDir"
        runFunctionSafe "${task}_define" "${runnerArgs[@]}"
        local exit=$?

        # Apply and clean
        applyTaskDefineEnvironment "$task" "$tasksDir/$task.task" "$isProject" "$projectId" "$projectDir"
        cleanTaskDefineEnvironment "$task" "$tasksDir/$task.task" "$isProject" "$projectId" "$projectDir"
        if [ "$exit" != 0 ]; then
            PROPERTIES=()
            copyAssociativeArray taskEnvLast PROPERTIES
            1>&2 echo Error: task discovery failed due to a failed define call, please check the log for errors
            exit $exit
        fi
    else
        # Set up environment (dummy)
        setupTaskDefineEnvironment "$task" "$tasksDir/$task.task" "$isProject" "$projectId" "$projectDir"

        # Apply and clean
        applyTaskDefineEnvironment "$task" "$tasksDir/$task.task" "$isProject" "$projectId" "$projectDir"
        cleanTaskDefineEnvironment "$task" "$tasksDir/$task.task" "$isProject" "$projectId" "$projectDir"
    fi

    # Clean environment
    unset -f "${task}_prepare"
    unset -f "${task}_run"
    unset -f "${task}_finish"
    unset -f "${task}_define"
    cleanTaskEnvironment "$task" "$tasksDir/$task.task" "$isProject" "$projectId" "$projectDir"

    # Reset
    PROPERTIES=()
    copyAssociativeArray taskEnvLast PROPERTIES
}

function findAllTasks() {
    local args=("$@")

    local projectId="$1"
    local projectDir="$2"
    local callback="$3"
    local projectListToUse="$4"
    local callbackParams=()
    arrayCopyOfRange args callbackParams 4 "${#args[@]}"

    local baseProjectId="${projectsBaseProjectIds["$projectId"]}"
    local baseProjectDir="${projects["$baseProjectId"]}"
    local rootProjectId="$ROOTPROJECTID"
    local rootProjectDir="${projects["$rootProjectId"]}"
    
    # Initialize project
    findAllTasksProject "$projectId" "$projectDir" "$callback" "$projectListToUse" "${callbackParams[@]}"
}

function findAllTasksProject() {
    local args=("$@")

    # Parse command
    local projectId="$1"
    local projectDir="$2"
    local callback="$3"
    local projectListToUse="$4"
    local callbackParams=()
    arrayCopyOfRange args callbackParams 4 "${#args[@]}"

    # Check project list
    if arrayContains "$projectDir" "$projectListToUse"; then
        return
    fi
    eval "$projectListToUse"'+=("$projectDir")'

    # Check found
    if [ "${PROJECTS_TASKS_LISTS["$projectDir-$projectId"]}" != "" ]; then
        # Return all tasks
        local tasksListId="${PROJECTS_TASKS_LISTS["$projectDir-$projectId"]}"
        eval 'local tasksList=("${tasks_'"$tasksListId"'[@]}")'
        for task in "${tasksList[@]}"; do
            # Call callback
            local projectInst="${PROJECTS_TASKS_PROJECTINSTS["$task"]}"
            local isProject="${PROJECTS_TASKS_ISPROJECT["$task"]}"
            local projectId="${PROJECTS_TASKS_PROJECTID["$task"]}"
            local projectDir="${PROJECTS_TASKS_PROJECTDIR["$task"]}"
            taskSensitiveRunLocalToProject "$isProject" "$projectId" "$(basename "${task%*.task}")" "$projectInst" runFunctionSafe "$callback" "$(basename "${task%*.task}")" "$(readlink -f "$task")" "$isProject" "$projectId" "$projectDir" "${callbackParams[@]}"
        done
        return
    fi

    # Create task list
    local setIdTaskList="$(tr -dc A-Za-z0-9 </dev/urandom | head -c 24)"
    while arrayContains "$setIdTaskList" setIds ; do
        setIdTaskList="$(tr -dc A-Za-z0-9 </dev/urandom | head -c 24)"
    done
    setIds+=("$setIdTaskList")
    PROJECTS_TASKS_LISTS+=(["$projectDir-$projectId"]="$setIdTaskList")
    eval "tasks_$setIdTaskList"'=()'

    # Get list ID
    local setId="${projectsSetIds["$projectId"]}"

    # Go through dependencies recursively
    # We stay relative to the current project
    eval 'local dependenciesList=("${'"dependencies_$setId"'[@]}")'
    for depId in "${dependenciesList[@]}"; do
        local depDir="${projects["$depId"]}"

        # Run in dependency
        findAllTasksProject "$depId" "$depDir" "$callback" "$projectListToUse" "${callbackParams[@]}"
        local exit=$?
        if [ "$exit" != 0 ]; then
            return $exit
        fi
    done

    # Find task
    execFindAllTasks "${projectsTasksFolders["$projectId"]}" true "$projectId" "$projectId" "$projectDir" "$callback" "$projectListToUse" "${callbackParams[@]}"
    local exit=$?
    if [ "$exit" != 0 ]; then
        return $exit
    fi

    # Try finding it in the runtime
    local runtimeTaskDir="$RUNTIMEPATH/builtin/tasks"
    if [ -d "$runtimeTaskDir" ]; then
        # Find task
        execFindAllTasks "$runtimeTaskDir" false "$projectId" "" "" "$callback" "$projectListToUse" "${callbackParams[@]}"
        local exit=$?

        # Handle exit
        if [ "$exit" != 0 ]; then
            return $exit
        fi
    fi

    # Go through sub projects recursively
    # We stay relative to the current project
    eval 'local subprojectsList=("${'"subprojects_$setId"'[@]}")'
    for subProjectId in "${subprojectsList[@]}"; do
        local subProjectDir="${projects["$subProjectId"]}"

        # Run in subproject
        findAllTasksProject "$subProjectId" "$subProjectDir" "$callback" "$projectListToUse" "${callbackParams[@]}"
        local exit=$?
        if [ "$exit" != 0 ]; then
            return $exit
        fi
    done
}

function execFindAllTasks() {
    local args=("$@")

    # Parse command
    local tasksDir="$1"
    local isProject="$2" # if false, its a runtime task
    local projectInst="$3"
    local projectId="$4"
    local projectDir="$5"
    local callback="$6"
    local projectListToUse="$7"
    local callbackParams=()
    arrayCopyOfRange args callbackParams 7 "${#args[@]}"

    # Find task
    if [ -d "$tasksDir" ]; then
        for task in "$tasksDir/"*.task; do
            if [ -f "$task" ]; then
                # Found task

                # Add task
                local setId="${PROJECTS_TASKS_LISTS["$projectDir-$projectId"]}"
                if ! arrayContains "$task" "tasks_$setId"; then
                    eval 'tasks_'"$setId"'+=("$task")'
                fi
                
                # Set task properties
                PROJECTS_TASKS_NAMES+=(["$task"]="$(basename "${task%*.task}")")
                PROJECTS_TASKS_PROJECTID+=(["$task"]="$projectId")
                PROJECTS_TASKS_PROJECTDIR+=(["$task"]="$projectDir")
                PROJECTS_TASKS_ISPROJECT+=(["$task"]="$isProject")
                PROJECTS_TASKS_PROJECTINSTS+=(["$task"]="$projectInst")

                # Run
                taskSensitiveRunLocalToProject "$isProject" "$projectId" "$(basename "${task%*.task}")" "$projectInst" runFunctionSafe "$callback" "$(basename "${task%*.task}")" "$(readlink -f "$task")" "$isProject" "$projectId" "$projectDir" "${callbackParams[@]}"
            fi
        done
    fi
}

function resolveTask() {
    local args=("$@")

    # Parse command
    local task="$1"
    local callback="$2"
    local callbackParams=()
    arrayCopyOfRange args callbackParams 2 "${#args[@]}"

    # Check if the task is to run local to another project
    if [[ "$task" == *:* ]]; then
        # It is
        local projectId="${task%:*}"
        local task="${task#*:}"
        runLocalToProject "$projectId" resolveTask "$task" "$callback" "${callbackParams[@]}"
        return $?
    fi

    # Set state
    taskFile=""
    taskResolveFound=false

    # Get project properties
    local localProjectDir="$LOCALPROJECT"
    local baseProjectDir="$BASEPROJECT"
    local rootProjectDir="$ROOTPROJECT"
    local localProjectId="$LOCALPROJECTID"
    local baseProjectId="$BASEPROJECTID"
    local rootProjectId="$ROOTPROJECTID"

    # First use the local project
    resolveTaskInProject "$task" "$localProjectId" "$localProjectDir" "$callback" "${callbackParams[@]}"
    local exit=$?
    if [ "$exit" != 0 ]; then
        return $exit
    fi
    if [ "$taskResolveFound" == "true" ]; then
        return $exit
    fi
    if [ "$baseProjectId" != "$localProjectId" ]; then
        resolveTaskInProject "$task" "$baseProjectId" "$baseProjectDir" "$callback" "${callbackParams[@]}"
        local exit=$?
        if [ "$exit" != 0 ]; then
            return $exit
        fi
        if [ "$taskResolveFound" == "true" ]; then
            return $exit
        fi
    fi

    # Check found
    if [ "$taskResolveFound" == "true" ]; then
        return 0
    fi

    # Not found
    return 1
}

function resolveTaskInProject() {
    local args=("$@")

    # Parse command
    local task="$1"
    local projectId="$2"
    local projectDir="$3"
    local callback="$4"
    local callbackParams=()
    arrayCopyOfRange args callbackParams 4 "${#args[@]}"

    # Check task
    if [ "$task" != "restore" ]; then 
        # Find task
        runLocalToProject "$projectId" resolveTaskFileExec "$task" "${projectsTasksFolders["$projectId"]}" true "$projectId" "$projectDir" "$callback" "${callbackParams[@]}"
        local exit=$?
        
        # Handle exit
        if [ "$exit" != 0 ] || [ "$taskResolveFound" == "true" ]; then
            return $exit
        fi

        # Get list ID
        local setId="${projectsSetIds["$projectId"]}"

        # Go through sub projects recursively
        # We stay relative to the current project
        eval 'local subprojectsList=("${'"subprojects_$setId"'[@]}")'
        for subProjectId in "${subprojectsList[@]}"; do
            local subProjectDir="${projects["$subProjectId"]}"

            # Run in subproject
            runLocalToProject "$subProjectId" resolveTaskInProject "$task" "$subProjectId" "$subProjectDir" "$callback" "${callbackParams[@]}"
            local exit=$?
            if [ "$exit" != 0 ] || [ "$taskResolveFound" == "true" ]; then
                return $exit
            fi
        done

        # Go through dependencies recursively
        # We stay relative to the current project
        eval 'local dependenciesList=("${'"dependencies_$setId"'[@]}")'
        for depId in "${dependenciesList[@]}"; do
            local depDir="${projects["$depId"]}"

            # Run in dependency
            runLocalToProject "$depId" resolveTaskInProject "$task" "$depId" "$depDir" "$callback" "${callbackParams[@]}"
            local exit=$?
            if [ "$exit" != 0 ] || [ "$taskResolveFound" == "true" ]; then
                return $exit
            fi
        done
    fi

    # Try finding it in the runtime
    local runtimeTaskDir="$RUNTIMEPATH/builtin/tasks"
    if [ -d "$runtimeTaskDir" ]; then
        # Find task
        runLocalToProject "$projectId" resolveTaskFileExec "$task" "$runtimeTaskDir" false  "" "" "$callback" "${callbackParams[@]}"
        local exit=$?

        # Handle exit
        if [ "$exit" != 0 ]; then
            return $exit
        fi
    fi
}

function resolveTaskFileExec() {
    local args=("$@")

    # Parse command
    local task="$1"
    local tasksDir="$2"
    local isProject="$3" # if false, its a runtime task
    local projectId="$4"
    local projectDir="$5"
    local callback="$6"
    local callbackParams=()
    arrayCopyOfRange args callbackParams 6 "${#args[@]}"

    # Find task
    if [ -d "$tasksDir" ]; then
        # Try to find task
        if [ -f "$tasksDir/$task.task" ]; then
            # Found task
            taskResolveFound=true
            taskFile="$(readlink -f "$tasksDir/$task.task")"
            if [ "$callback" != "" ]; then
                runFunctionSafe "$callback" "$task" "$taskFile" "$isProject" "$projectId" "$projectDir" "${callbackParams[@]}"
            fi

            # Return success
            return 0
        fi
    fi
}
