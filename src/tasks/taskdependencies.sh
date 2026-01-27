#!/bin/bash
declare PROJECTMEMORYREFSCANNER_INIT=()
declare TASKMEMORYREFSCANNER_INIT=()
declare PROJECTMEMORYREFSCANNER_POPULATE=()
declare TASKMEMORYREFSCANNER_POPULATE=()
declare PROJECTMEMORYREFSCANNER_SCANNER=()
declare TASKMEMORYREFSCANNER_SCANNER=()

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
    if [ "$rootProjectId" != "$localProjectId" ]; then
        resolveTaskInProject "$task" "$rootProjectId" "$rootProjectDir" "$callback" "${callbackParams[@]}"
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
        runLocalToProject "$projectId" resolveTaskFileExec "$task" "$projectDir/tasks" true "$projectId" "$projectDir" "$callback" "${callbackParams[@]}"
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
        runLocalToProject "$projectId" resolveTaskFileExec "$task" "$runtimeTaskDir" true  "" "" "$callback" "${callbackParams[@]}"
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
            runFunctionSafe "$callback" "$task" "$taskFile" "${callbackParams[@]}"

            # Return success
            return 0
        fi
    fi
    return 1
}

function tasksDependenciesExecPre() {
    local args=("$@")

    # Parse command
    local task="$1"
    local isProject="$2" # if false, its a runtime task
    local projectId="$3"
    local projectDir="$4"

    # Check
    local taskKey="$projectId-$task"
    if [ "$isProject" != true ]; then
        taskKey="RUNTIME@$LOCALPROJECTID@$task"
    fi
    
    # Get task properties
    taskFile="${TASKMEMORYREFSCANNER_FILES["$taskKey"]}"
    local setId="${TASKS_DEPENDENCY_LIST_IDS["$taskKey"]}"
    if [ "$setId" != "" ]; then
        # Got sets!
        eval 'local dependsList=("${'"requiresTask_$setId"'[@]}")'
        eval 'local loadOntoList=("${'"addTo_$setId"'[@]}")'
        eval 'local loadAfterList=("${'"afterTask_$setId"'[@]}")'
        eval 'local loadBeforeList=("${'"beforeTask_$setId"'[@]}")'
        
        # Run the afterTask tasks as the current task wants to be run AFTER those tasks
        for tsk in "${dependsList[@]}"; do
            if [ "$tsk" != "" ]; then
                if arrayContains "$tsk" loadAfterList; then
                    callTask "$tsk" || return 1
                fi
            fi
        done
    fi
}

function tasksDependenciesExecPost() {
    local args=("$@")

    # Parse command
    local task="$1"
    local isProject="$2" # if false, its a runtime task
    local projectId="$3"
    local projectDir="$4"

    # Check
    local taskKey="$projectId-$task"
    if [ "$isProject" != true ]; then
        taskKey="RUNTIME@$LOCALPROJECTID@$task"
    fi
    
    # Get task properties
    taskFile="${TASKMEMORYREFSCANNER_FILES["$taskKey"]}"
    local setId="${TASKS_DEPENDENCY_LIST_IDS["$taskKey"]}"
    if [ "$setId" != "" ]; then
        # Got sets!
        eval 'local dependsList=("${'"requiresTask_$setId"'[@]}")'
        eval 'local loadOntoList=("${'"addTo_$setId"'[@]}")'
        eval 'local loadAfterList=("${'"afterTask_$setId"'[@]}")'
        eval 'local loadBeforeList=("${'"beforeTask_$setId"'[@]}")'
        
        # Run the beforeTask tasks as the current task wants those tasks after the current task
        for tsk in "${dependsList[@]}"; do
            if [ "$tsk" != "" ]; then
                if arrayContains "$tsk" loadBeforeList; then
                    callTask "$tsk" || return 1
                fi
            fi
        done
    fi
}

function environmentPrepareProjectTasks() {
    local args=("$@")

    # Parse command
    local task="$1"
    local projectId="$2"
    local projectDir="$3"
    local runnerArgs=()
    arrayCopyOfRange args runnerArgs 3 "${#args[@]}"

    # Here we set up task depenencies
    # How it works is that each task can set up tasks they require as well as when to load the given task, like if the current should run after a target task, or before the target task
    # Tasks can also add themselves to another target task
    #
    # Normally, tasks are only run when requested, except if they are added to a given target task using addTaskTo
    # Before and After statements only run if the current task is being executed, this can either happen when it is executed itself by the cli, or by a target task calling it when either it runs the current task, or the current task binds to the target task
    #
    #
    # Require - forwards bind, calls the target task when the current task is run, by default unless overridden, AfterTask is automatiaclly applied to the target task
    # AddTo - reverse bind, the current task will run when the target is run
    # AfterTask - run the CURRENT task after the target task, only works if Require is used by the target task or AddTo adds the current task to the target
    # BeforeTask - run the CURRENT task before the target task, only works if Require is used by the target task or AddTo adds the current task to the target
    #
    
    # Initialize project
    findAllTasks "$projectId" "$projectDir" onPrepareTaskFound_Init PROJECTMEMORYREFSCANNER_INIT
    findAllTasks "$projectId" "$projectDir" onPrepareTaskFound_Populate PROJECTMEMORYREFSCANNER_POPULATE
    findAllTasks "$projectId" "$projectDir" onPrepareTaskFound_Scanner PROJECTMEMORYREFSCANNER_SCANNER
}

function onPrepareTaskFound_Init() {
    local task="$1"
    local taskFile="$2"
    local isProject="$3" # if false, its a runtime task
    local projectId="$4"
    local projectDir="$5"

    # Check
    local taskKey="$projectId-$task"
    if [ "$isProject" != true ]; then
        taskKey="RUNTIME@$LOCALPROJECTID@$task"
    fi
    if arrayContains "$taskKey" TASKMEMORYREFSCANNER_INIT; then
        return 0
    fi
    TASKMEMORYREFSCANNER_INIT+=("$taskKey")
    TASKMEMORYREFSCANNER_KEYS+=(["$taskFile-$LOCALPROJECTID"]="$taskKey")
    
    # Load task
    setupTaskEnvironment "$task" "$taskFile" "$isProject" "$projectId" "$projectDir"
    source "$taskFile" || taskLoadError "$task.task"

    # Check local
    local localTaskFile="$LOCALPROJECT/polylocal/tasks/$task.task"
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
            1>&2 echo Error: task discovery failed due to a failed define call, please check the log for errors
            exit $exit
        fi
    fi

    # Create dependency lists
    local setId="$(tr -dc A-Za-z0-9 </dev/urandom | head -c 24)"
    while arrayContains "$setId" setIds ; do
        setId="$(tr -dc A-Za-z0-9 </dev/urandom | head -c 24)"
    done
    setIds+=("$setId")
    TASKS_DEPENDENCY_LIST_IDS+=(["$taskKey"]="$setId")
    eval "declare -g requiresTask_$setId"'=("${dependsList[@]}")'
    eval "declare -g addTo_$setId"'=("${loadOntoList[@]}")'
    eval "declare -g afterTask_$setId"'=("${loadAfterList[@]}")'
    eval "declare -g beforeTask_$setId"'=("${loadBeforeList[@]}")'
    dependsList=()
    loadOntoList=()
    loadAfterList=()
    loadBeforeList=()

    cleanTaskEnvironment "$task" "$tasksDir/$task.task" "$isProject" "$projectId" "$projectDir"
}

function onPrepareTaskFound_Populate() {
    local task="$1"
    local taskFile="$2"
    local isProject="$3" # if false, its a runtime task
    local projectId="$4"
    local projectDir="$5"

    # Check
    local taskKey="$projectId-$task"
    if [ "$isProject" != true ]; then
        taskKey="RUNTIME@$LOCALPROJECTID@$task"
    fi
    if arrayContains "$taskKey" TASKMEMORYREFSCANNER_POPULATE; then
        return 0
    fi
    TASKMEMORYREFSCANNER_POPULATE+=("$taskKey")
    TASKMEMORYREFSCANNER_KEYS+=(["$taskFile-$LOCALPROJECTID"]="$taskKey")
    
    # Get list
    local setId="${TASKS_DEPENDENCY_LIST_IDS["$taskKey"]}"
    if [ "$setId" != "" ]; then        
        # Got sets!
        eval 'local dependsList=("${'"requiresTask_$setId"'[@]}")'
        eval 'local loadOntoList=("${'"addTo_$setId"'[@]}")'
        eval 'local loadAfterList=("${'"afterTask_$setId"'[@]}")'
        eval 'local loadBeforeList=("${'"beforeTask_$setId"'[@]}")'
        local requiredDependencies=()
        
        # First resolve dependencies
        for id in "${dependsList[@]}" ; do
            if ! arrayContains "$id" requiredDependencies; then
                requiredDependencies+=("$id")
            fi
        done

        # Add to target tasks's dependencies so this task is run
        # Adding to dependsList to guarantee running our task, and with beforeTask to control that our task is loaded after the target task
        for id in "${loadOntoList[@]}"; do
            # Get order for target
            # Default is for the target to load this task after itself 
            # If the current task wants to be loaded before the target, itll add it to the target's afterTask list
            local targetOrderList="beforeTask"
            if arrayContains "$id" loadBeforeList; then
                targetOrderList="afterTask"
            fi 

            # Resolve
            eval "requiresTask_$setId"'=("${dependsList[@]}")'
            eval "addTo_$setId"'=("${loadOntoList[@]}")'
            eval "afterTask_$setId"'=("${loadAfterList[@]}")'
            eval "beforeTask_$setId"'=("${loadBeforeList[@]}")'
            resolveTask "$id" resolveTaskAddToTargetCallback "$projectId" "$task" requiresTask "$targetOrderList"
            if [ "$taskResolveFound" != "true" ]; then
                # Error
                1>&2 echo "Error: could not resolve dependency task \"$id\" for task \"$task\": task not recognized"
                exit 1
            fi
            eval 'dependsList=("${'"requiresTask_$setId"'[@]}")'
            eval 'loadOntoList=("${'"addTo_$setId"'[@]}")'
            eval 'loadAfterList=("${'"afterTask_$setId"'[@]}")'
            eval 'loadBeforeList=("${'"beforeTask_$setId"'[@]}")'
        done

        # Update lists
        eval "requiresTask_$setId"'=("${dependsList[@]}")'
        eval "addTo_$setId"'=("${loadOntoList[@]}")'
        eval "afterTask_$setId"'=("${loadAfterList[@]}")'
        eval "beforeTask_$setId"'=("${loadBeforeList[@]}")'
    fi
}

function onPrepareTaskFound_Scanner() {
    local task="$1"
    local taskFile="$2"
    local isProject="$3" # if false, its a runtime task
    local projectId="$4"
    local projectDir="$5"

    # Check
    local taskKey="$projectId-$task"
    if [ "$isProject" != true ]; then
        taskKey="RUNTIME@$LOCALPROJECTID@$task"
    fi
    if arrayContains "$taskKey" TASKMEMORYREFSCANNER_SCANNER; then
        return 0
    fi
    TASKMEMORYREFSCANNER_SCANNER+=("$taskKey")
    TASKMEMORYREFSCANNER_FILES+=(["$taskKey"]="$taskFile")
    
    # Get list
    # Here we set up the task order settings
    local setId="${TASKS_DEPENDENCY_LIST_IDS["$taskKey"]}"
    if [ "$setId" != "" ]; then        
        # Got sets!
        eval 'local dependsList=("${'"requiresTask_$setId"'[@]}")'
        eval 'local loadOntoList=("${'"addTo_$setId"'[@]}")'
        eval 'local loadAfterList=("${'"afterTask_$setId"'[@]}")'
        eval 'local loadBeforeList=("${'"beforeTask_$setId"'[@]}")'
        local requiredDependencies=()
        
        # First resolve dependencies
        for id in "${dependsList[@]}" ; do
            if ! arrayContains "$id" requiredDependencies; then
                requiredDependencies+=("$id")
            fi
        done

        # Check hard marked required dependencies
        # Finalize them if they lack a order defining entry
        for id in "${requiredDependencies[@]}" ; do
            # If not a load-before, add as load-after (so that the target loads first)
            if ! arrayContains "$id" loadBeforeList && ! arrayContains "$id" loadAfterList; then
                loadAfterList+=("$id")
            fi
        done

        # Update lists
        eval "requiresTask_$setId"'=("${dependsList[@]}")'
        eval "addTo_$setId"'=("${loadOntoList[@]}")'
        eval "afterTask_$setId"'=("${loadAfterList[@]}")'
        eval "beforeTask_$setId"'=("${loadBeforeList[@]}")'
    fi
}

function resolveTaskAddToTargetCallback() {
    local args=("$@")

    # Parse command
    local task="$1"
    local taskFile="$2"
    local sourceProject="$3"
    local taskToAdd="$4"
    local targetLists=()
    arrayCopyOfRange args targetLists 4 "${#args[@]}"

    # Add to tasks's own loadBefore, making the tarket load before the given tasks
    local targetTaskKey="${TASKMEMORYREFSCANNER_KEYS["$taskFile-$LOCALPROJECTID"]}"
    if [ "$targetTaskKey" != "" ]; then
        local targetSetId="${TASKS_DEPENDENCY_LIST_IDS["$targetTaskKey"]}"
        if [ "$targetSetId" != "" ]; then
            # Load
            for targetList in "${targetLists[@]}"; do
                local targetListInst=()
                eval 'local targetListInst=("${'"${targetList}_$targetSetId"'[@]}")'

                # Add
                targetListInst+=("$sourceProject:$taskToAdd")

                # Save
                eval "${targetList}_$targetSetId"'=("${targetListInst[@]}")'
            done
        fi
    fi
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
    if [ "$projectId" != "$baseProjectId" ]; then
        findAllTasksProject "$baseProjectId" "$baseProjectDir" "$callback" "$projectListToUse" "${callbackParams[@]}"
    fi 
    if [ "$projectId" != "$rootProjectId" ]; then
        findAllTasksProject "$rootProjectId" "$rootProjectDir" "$callback" "$projectListToUse" "${callbackParams[@]}"
    fi 
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

    # Check
    if arrayContains "$projectDir" "$projectListToUse"; then
        return 0
    fi
    eval "$projectListToUse+="'("$projectDir")'

    # Get list ID
    local setId="${projectsSetIds["$projectId"]}"

    # Go through dependencies recursively
    # We stay relative to the current project
    eval 'local dependenciesList=("${'"dependencies_$setId"'[@]}")'
    for depId in "${dependenciesList[@]}"; do
        local depDir="${projects["$depId"]}"

        # Run in dependency
        runLocalToProject "$depId" findAllTasksProject "$depId" "$depDir" "$callback" "$projectListToUse" "${callbackParams[@]}"
        local exit=$?
        if [ "$exit" != 0 ]; then
            return $exit
        fi
    done

    # Find task
    runLocalToProject "$projectId" execFindAllTasks "$projectDir/tasks" true "$projectId" "$projectDir" "$callback" "$projectListToUse" "${callbackParams[@]}"
    local exit=$?
    if [ "$exit" != 0 ]; then
        return $exit
    fi

    # Try finding it in the runtime
    local runtimeTaskDir="$RUNTIMEPATH/builtin/tasks"
    if [ -d "$runtimeTaskDir" ]; then
        # Find task
        runLocalToProject "$projectId" execFindAllTasks "$runtimeTaskDir" false "" "" "$callback" "$projectListToUse" "${callbackParams[@]}"
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
        runLocalToProject "$subProjectId" findAllTasksProject "$subProjectId" "$subProjectDir" "$callback" "$projectListToUse" "${callbackParams[@]}"
        local exit=$?
        if [ "$exit" != 0 ]; then
            # Revert list
            ANTIRECURSIONLIST=("${callTaskListLast[@]}")
            return $exit
        fi
    done
}

function execFindAllTasks() {
    local args=("$@")

    # Parse command
    local tasksDir="$1"
    local isProject="$2" # if false, its a runtime task
    local projectId="$3"
    local projectDir="$4"
    local callback="$5"
    local callbackParams=()
    arrayCopyOfRange args callbackParams 5 "${#args[@]}"

    # Find task
    if [ -d "$tasksDir" ]; then
        for task in "$tasksDir/"*.task; do
            if [ -f "$task" ]; then
                # Found task
                runFunctionSafe "$callback" "$(basename "${task%*.task}")" "$(readlink -f "$task")" "$isProject" "$projectId" "$projectDir" "${callbackParams[@]}"
            fi
        done
    fi
}
