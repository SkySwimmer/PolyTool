#!/bin/bash
declare -Ag RESOLUTIONRESULTS
function taskDependenciesResolve() {
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
                if [ "${RESOLUTIONRESULTS["$LOCALPROJECTID-$projectId-$taskKey-$tsk"]}" != "" ]; then
                    if [ "${RESOLUTIONRESULTS["$LOCALPROJECTID-$projectId-$taskKey-$tsk"]}" != true ]; then
                        return 1
                    fi
                else
                    local taskResolveFoundLast="$taskResolveFound"
                    resolveTask "$tsk"
                    local resolveResult="$taskResolveFound"
                    RESOLUTIONRESULTS["$LOCALPROJECTID-$projectId-$taskKey-$tsk"]="$resolveResult"
                    taskResolveFound="$taskResolveFoundLast"
                    if [ "$resolveResult" != "true" ]; then
                        return 1
                    fi
                fi
            fi
        done
    fi
    return 0
}

function tasksDependenciesExecPrePrepare() {
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
                    runTaskWithRunnerIfNeeded "$tsk" relativeExecuteRunnerPrepare || return 1
                fi
            fi
        done
    fi
}

function tasksDependenciesExecPreRun() {
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
                    runTaskWithRunnerIfNeeded "$tsk" relativeExecuteRunnerRun || return 1
                fi
            fi
        done
    fi
}

function tasksDependenciesExecPreFinish() {
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
                    runTaskWithRunnerIfNeeded "$tsk" relativeExecuteRunnerFinish || return 1
                fi
            fi
        done
    fi
}

function tasksDependenciesExecPostPrepare() {
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
                    runTaskWithRunnerIfNeeded "$tsk" relativeExecuteRunnerPrepare || return 1
                fi
            fi
        done
    fi
}

function tasksDependenciesExecPostRun() {
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
                    runTaskWithRunnerIfNeeded "$tsk" relativeExecuteRunnerRun || return 1
                fi
            fi
        done
    fi
}

function tasksDependenciesExecPostFinish() {
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
                    runTaskWithRunnerIfNeeded "$tsk" relativeExecuteRunnerFinish || return 1
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
    findAllTasks "$projectId" "$projectDir" onPrepareTaskFound_Init PROJECTMEMORYREFSCANNER_INIT "$task"
    findAllTasks "$projectId" "$projectDir" onPrepareTaskFound_Populate PROJECTMEMORYREFSCANNER_POPULATE "$task"
    findAllTasks "$projectId" "$projectDir" onPrepareTaskFound_Scanner PROJECTMEMORYREFSCANNER_SCANNER "$task"
}

function onPrepareTaskFound_Init() {
    local task="$1"
    local taskFile="$2"
    local isProject="$3" # if false, its a runtime task
    local projectId="$4"
    local projectDir="$5"
    local baseTask="$6"

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

    # Check relative
    if ! arrayContains "$LOCALPROJECTID-$task" TASKS_RELATIVE_TO_CALLER; then
        # Resolve dependencies
        for depend in "${dependsList[@]}"; do
            local taskResolveFoundLast="$taskResolveFound"
            resolveTask "$depend"
            local resolveResult="$taskResolveFound"
            taskResolveFound="$taskResolveFoundLast"
            if [ "$resolveResult" != true ]; then
                PROPERTIES=()
                copyAssociativeArray taskEnvLast PROPERTIES
                1>&2 echo "Error: failed to define task '$task' of project $projectId: dependency task not recognized: $depend"
                exit $exit
            fi
        done

        # Resolve targets
        if [ "$baseTask" != "restore" ]; then
            for depend in "${loadOntoList[@]}"; do
                local taskResolveFoundLast="$taskResolveFound"
                resolveTask "$depend"
                local resolveResult="$taskResolveFound"
                taskResolveFound="$taskResolveFoundLast"
                if [ "$resolveResult" != true ]; then
                    PROPERTIES=()
                    copyAssociativeArray taskEnvLast PROPERTIES
                    1>&2 echo "Error: failed to define task '$task' of project $projectId: dependency task not recognized: $depend"
                    exit $exit
                fi
            done
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
            if [ "$projectId" != "$LOCALPROJECTID" ]; then
                resolveTask "$id" resolveTaskAddToTargetCallback "$LOCALPROJECTID" "$task" requiresTask "$targetOrderList"
                runLocalToProject "$projectId" resolveTask "$id" resolveTaskAddToTargetCallback "$projectId" "$task" requiresTask "$targetOrderList"
            else
                resolveTask "$id" resolveTaskAddToTargetCallback "$projectId" "$task" requiresTask "$targetOrderList"
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
    local isProject="$3" # if false, its a runtime task
    local projectId="$4"
    local projectDir="$5"
    local sourceProject="$6"
    local taskToAdd="$7"
    local targetLists=()
    arrayCopyOfRange args targetLists 7 "${#args[@]}"

    # Add to tasks's own loadBefore, making the tarket load before the given tasks
    local targetTaskKey="${TASKMEMORYREFSCANNER_KEYS["$taskFile-$LOCALPROJECTID"]}"
    if [ "$targetTaskKey" != "" ]; then
        local targetSetId="${TASKS_DEPENDENCY_LIST_IDS["$targetTaskKey"]}"
        if [ "$targetSetId" != "" ]; then
            # Load
            for targetList in "${targetLists[@]}"; do
                local targetListInst=()
                eval 'local targetListInst=("${'"${targetList}_$targetSetId"'[@]}")'

                # Get entity
                local taskEntity="$sourceProject:$taskToAdd"
                
                # Add
                targetListInst+=("$taskEntity")

                # Save
                eval "${targetList}_$targetSetId"'=("${targetListInst[@]}")'
            done
        fi
    fi
}

