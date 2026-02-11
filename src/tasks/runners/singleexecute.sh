#!/bin/bash

function singleExecuteRunner() {
    local args=("$@")

    # Parse command
    local onlyWhenNeeded="$1"
    local task="$2"
    local runnerArgs=()
    arrayCopyOfRange args runnerArgs 2 "${#args[@]}"

    # Check if the task is to run local to another project
    if [[ "$task" == *:* ]]; then
        # It is
        local projectId="${task%:*}"
        local task="${task#*:}"
        runLocalToProject "$projectId" singleExecuteRunner "$onlyWhenNeeded" "$task" "${runnerArgs[@]}"
        return $?
    fi

    # Get project properties
    local localProjectDir="$LOCALPROJECT"
    local baseProjectDir="$BASEPROJECT"
    local rootProjectDir="$ROOTPROJECT"
    local localProjectId="$LOCALPROJECTID"
    local baseProjectId="$BASEPROJECTID"
    local rootProjectId="$ROOTPROJECTID"

    # First use the local project
    taskFound=false
    taskRunnerProjectSingle "$onlyWhenNeeded" "$task" "$localProjectId" "$localProjectDir" "${runnerArgs[@]}"
    local exit=$?
    if [ "$exit" != 0 ]; then
        return $exit
    fi
    if [ "$taskFound" == "true" ]; then
        return $exit
    fi
    if [ "$baseProjectId" != "$localProjectId" ]; then
        taskRunnerProjectSingle "$onlyWhenNeeded" "$task" "$baseProjectId" "$baseProjectDir" "${runnerArgs[@]}"
        local exit=$?
        if [ "$exit" != 0 ]; then
            return $exit
        fi
        if [ "$taskFound" == "true" ]; then
            return $exit
        fi
    fi
    if [ "$rootProjectId" != "$localProjectId" ]; then
        taskRunnerProjectSingle "$onlyWhenNeeded" "$task" "$rootProjectId" "$rootProjectDir" "${runnerArgs[@]}"
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
    local onlyWhenNeeded="$1"
    local task="$2"
    local projectId="$3"
    local projectDir="$4"
    local runnerArgs=()
    arrayCopyOfRange args runnerArgs 4 "${#args[@]}"

    # Check found
    if [ "$taskFound" == "true" ]; then
        return 0
    fi

    # Check state
    local taskProjectId="$projectId"
    if arrayContains "$projectId-$task" TASKS_RELATIVE_TO_CALLER; then
        taskProjectId="$LOCALPROJECTID"
    fi
    if [ "$onlyWhenNeeded" == "true" ]; then
        # Check if called
        if arrayContains "$taskProjectId-$task" TASKSBEINGRUN_PREPARE && ! arrayContains "$taskProjectId-$task" TASKS_PERMITTING_MULTIRUN; then
            # Already run
            if arrayContains "$taskProjectId-$task" TASKS_FOUND; then
                taskFound=true
            fi
            if arrayContains "RUNTIME@$projectId@$task" TASKS_FOUND || arrayContains "RUNTIME@$task" TASKS_FOUND; then
                taskFound=true
            fi
            return 0
        fi
    fi

    # Initialize tasks, this will also deal with base projects and root projects
    runLocalToProject "$projectId" environmentPrepareProjectTasks "$task" "$projectId" "$projectDir" "${runnerArgs[@]}"

    # Box recursion list
    # We basically copy the list, making it stack-sensitive
    # After this method finishes, we reset to what it was last
    # That way, cyclic calls are ignored without breaking other task files calling callTask for the same task
    local callTaskListLast=("${ANTIRECURSIONLIST[@]}")
    ANTIRECURSIONLIST=()
    ANTIRECURSIONLIST+=("${callTaskListLast[@]}")

    # Check task
    if [ "$task" != "restore" ]; then 
        # Find task
        taskSensitiveRunLocalToProject true "$projectId" "$task" "$projectId" execTasksSingle "$task" "${projectsTasksFolders["$projectId"]}" true "$projectId" "$projectDir" "${runnerArgs[@]}"
        local exit=$?

        # Add to task list
        if [ "$taskFound" == "true" ] && ! arrayContains "$projectId-$task" TASKS_FOUND; then
            # Add
            TASKS_FOUND+=("$projectId-$task")
        fi
        
        # Handle exit
        if [ "$exit" != 0 ] && [ "$taskFound" == "true" ]; then
            # Revert list
            ANTIRECURSIONLIST=("${callTaskListLast[@]}")
            return $exit
        fi
        if [ "$taskFound" == "true" ]; then
            # Revert list
            ANTIRECURSIONLIST=("${callTaskListLast[@]}")
            return $exit
        fi

        # Get list ID
        local setId="${projectsSetIds["$projectId"]}"

        # Go through sub projects recursively
        # We stay relative to the current project
        eval 'subprojectsList=("${'"subprojects_$setId"'[@]}")'
        for subProjectId in "${subprojectsList[@]}"; do
            local subProjectDir="${projects["$subProjectId"]}"

            # Run in subproject
            taskRunnerProjectSingle "$onlyWhenNeeded" "$task" "$subProjectId" "$subProjectDir" "${runnerArgs[@]}"
            local exit=$?
            if [ "$exit" != 0 ]; then
                # Revert list
                ANTIRECURSIONLIST=("${callTaskListLast[@]}")
                return $exit
            fi
            if [ "$taskFound" == "true" ]; then
                # Revert list
                ANTIRECURSIONLIST=("${callTaskListLast[@]}")
                return $exit
            fi

            # Run in subproject
            if [ "$LOCALPROJECTID" != "$projectId" ]; then
                runLocalToProject "$projectId" taskRunnerProjectSingle "$onlyWhenNeeded" "$task" "$subProjectId" "$subProjectDir" "${runnerArgs[@]}"
                local exit=$?
                if [ "$exit" != 0 ]; then
                    # Revert list
                    ANTIRECURSIONLIST=("${callTaskListLast[@]}")
                    return $exit
                fi
                if [ "$taskFound" == "true" ]; then
                    # Revert list
                    ANTIRECURSIONLIST=("${callTaskListLast[@]}")
                    return $exit
                fi
            fi
        done

        # Go through dependencies recursively
        # We stay relative to the current project
        eval 'dependenciesList=("${'"dependencies_$setId"'[@]}")'
        for depId in "${dependenciesList[@]}"; do
            local depDir="${projects["$depId"]}"

            # Run in dependency
            taskRunnerProjectSingle "$onlyWhenNeeded" "$task" "$depId" "$depDir" "${runnerArgs[@]}"
            local exit=$?
            if [ "$exit" != 0 ]; then
                # Revert list
                ANTIRECURSIONLIST=("${callTaskListLast[@]}")
                return $exit
            fi
            if [ "$taskFound" == "true" ]; then
                # Revert list
                ANTIRECURSIONLIST=("${callTaskListLast[@]}")
                return $exit
            fi

            # Run in dependency
            if [ "$LOCALPROJECTID" != "$projectId" ]; then
                runLocalToProject "$projectId" taskRunnerProjectSingle "$onlyWhenNeeded" "$task" "$depId" "$depDir" "${runnerArgs[@]}"
                local exit=$?
                if [ "$exit" != 0 ]; then
                    # Revert list
                    ANTIRECURSIONLIST=("${callTaskListLast[@]}")
                    return $exit
                fi
                if [ "$taskFound" == "true" ]; then
                    # Revert list
                    ANTIRECURSIONLIST=("${callTaskListLast[@]}")
                    return $exit
                fi
            fi
        done
    fi

    # Try finding it in the runtime
    local runtimeTaskDir="$RUNTIMEPATH/builtin/tasks"
    if [ -d "$runtimeTaskDir" ]; then
        # Check state
        local doRun=true
        if [ "$onlyWhenNeeded" == "true" ]; then
            # Check if called
            if (arrayContains "RUNTIME@$projectId@$task" TASKSBEINGRUN_PREPARE && ! arrayContains "RUNTIME@$projectId@$task" TASKS_PERMITTING_MULTIRUN) || (arrayContains "RUNTIME@$task" TASKSBEINGRUN_PREPARE && ! arrayContains "RUNTIME@$task" TASKS_PERMITTING_MULTIRUN); then
                # Already run
                if arrayContains "RUNTIME@$projectId@$task" TASKS_FOUND; then
                    taskFound=true
                fi
                doRun=false
            fi
        fi

        # Check
        if [ "$doRun" == "true" ]; then
            # Add to task history
            if ! arrayContains "RUNTIME@$projectId@$task" TASKSBEINGRUN_RUN && ! arrayContains "RUNTIME@$task" TASKSBEINGRUN_RUN; then
                # Add
                if ! arrayContains "$task" TASKS_RUNTIME_SHARED; then
                    TASKSBEINGRUN_PREPARE+=("RUNTIME@$projectId@$task")
                else
                    TASKSBEINGRUN_PREPARE+=("RUNTIME@$task")
                fi
            fi
            if ! arrayContains "RUNTIME@$projectId@$task" TASKSBEINGRUN_RUN && ! arrayContains "RUNTIME@$task" TASKSBEINGRUN_RUN; then
                # Add
                if ! arrayContains "$task" TASKS_RUNTIME_SHARED; then
                    TASKSBEINGRUN_RUN+=("RUNTIME@$projectId@$task")
                else
                    TASKSBEINGRUN_RUN+=("RUNTIME@$task")
                fi    
            fi
            if ! arrayContains "RUNTIME@$projectId@$task" TASKSBEINGRUN_FINISH && ! arrayContains "RUNTIME@$task" TASKSBEINGRUN_FINISH; then
                # Add
                if ! arrayContains "$task" TASKS_RUNTIME_SHARED; then
                    TASKSBEINGRUN_FINISH+=("RUNTIME@$projectId@$task")
                else
                    TASKSBEINGRUN_FINISH+=("RUNTIME@$task")
                fi    
            fi
            
            # Box again
            local callTaskListLast2=("${ANTIRECURSIONLIST[@]}")
            ANTIRECURSIONLIST=()
            ANTIRECURSIONLIST+=("${callTaskListLast2[@]}")

            # Find task
            taskSensitiveRunLocalToProject false "$projectId" "$task" "$projectId" execTasksSingle "$task" "$runtimeTaskDir" false "" "" "${runnerArgs[@]}"
            local exit=$?

            # Revert
            ANTIRECURSIONLIST=("${callTaskListLast2[@]}")

            # Add to task list
            if [ "$taskFound" == "true" ]; then
                if arrayContains "$task" TASKS_RUNTIME_SHARED && ! arrayContains "RUNTIME@$task" TASKS_FOUND; then
                    # Add
                    TASKS_FOUND+=("RUNTIME@$task")
                elif ! arrayContains "$task" TASKS_RUNTIME_SHARED && ! arrayContains "RUNTIME@$projectId@$task" TASKS_FOUND; then
                    # Add
                    TASKS_FOUND+=("RUNTIME@$projectId@$task")
                fi
            fi
            
            # Handle exit
            if [ "$exit" != 0 ]; then
                # Revert list
                ANTIRECURSIONLIST=("${callTaskListLast[@]}")
                return $exit
            fi
            if [ "$taskFound" == "true" ]; then
                # Revert list
                ANTIRECURSIONLIST=("${callTaskListLast[@]}")
                return $exit
            fi
        fi
    fi

    # Revert list
    ANTIRECURSIONLIST=("${callTaskListLast[@]}")
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

    # Verify dependency
    taskDependenciesResolve "$task" "$isProject" "$projectId" "$projectDir" || return 0

    # Add to task history
    if ! arrayContains "$LOCALPROJECTID-$task" TASKSBEINGRUN_PREPARE; then
        # Add
        TASKSBEINGRUN_PREPARE+=("$LOCALPROJECTID-$task")
    fi
    if ! arrayContains "$LOCALPROJECTID-$task" TASKSBEINGRUN_RUN; then
        # Add
        TASKSBEINGRUN_RUN+=("$LOCALPROJECTID-$task")
    fi
    if ! arrayContains "$LOCALPROJECTID-$task" TASKSBEINGRUN_FINISH; then
        # Add
        TASKSBEINGRUN_FINISH+=("$LOCALPROJECTID-$task")
    fi
    
    # Find task
    if [ -d "$tasksDir" ]; then
        # Try to find task
        if [ -f "$tasksDir/$task.task" ]; then            
            # Found task
            taskFound=true

            # Check recursion
            if arrayContains "$tasksDir/$task.task" ANTIRECURSIONLIST; then
                return 0
            fi
            ANTIRECURSIONLIST+=("$tasksDir/$task.task")
        
            # Found task
            # Run pre-tasks
            tasksDependenciesExecPre "$task" "$isProject" "$projectId" "$projectDir" || return 1
            
            # Show log
            if [ "$isProject" == true ]; then
                echo "> $LOCALPROJECTID : $projectId:$task -> PREPARE"
            else
                echo "> $LOCALPROJECTID : $task -> PREPARE"
            fi

            # Get last env
            declare -A taskEnvLast=()
            copyAssociativeArray PROPERTIES taskEnvLast
            declare -A parametersEnvLast=()
            copyAssociativeArray PARAMETERS parametersEnvLast
            PROPERTIES=()
            PARAMETERS=()

            # Load task
            setupTaskEnvironment "$task" "$tasksDir/$task.task" "$isProject" "$projectId" "$projectDir" "${runnerArgs[@]}"
            source "$tasksDir/$task.task" || taskLoadError "$task.task"

            # Check local
            local localTaskFile="${projectsPolyLocalFolders["$LOCALPROJECTID"]}/tasks/$task.task"
            if [ -f "$localTaskFile" ]; then
                # Local overload
                source "$localTaskFile" || taskLoadError "<local>/polylocal/tasks/$task.task"
            fi

            # Call prepare
            if type "${task}_define" &>/dev/null; then
                setupTaskDefineEnvironment "$task" "$tasksDir/$task.task" "$isProject" "$projectId" "$projectDir" "${runnerArgs[@]}"
                runFunctionSafe "${task}_define" "${runnerArgs[@]}"
                local exit=$?
                applyTaskDefineEnvironment "$task" "$tasksDir/$task.task" "$isProject" "$projectId" "$projectDir" "${runnerArgs[@]}"
                cleanTaskDefineEnvironment "$task" "$tasksDir/$task.task" "$isProject" "$projectId" "$projectDir" "${runnerArgs[@]}"
                if [ "$exit" != 0 ]; then
                    PROPERTIES=()
                    copyAssociativeArray taskEnvLast PROPERTIES
                    PARAMETERS=()
                    copyAssociativeArray parametersEnvLast PARAMETERS
                    cleanTaskEnvironment "$task" "$tasksDir/$task.task" "$isProject" "$projectId" "$projectDir" "${runnerArgs[@]}"
                    return $exit
                fi
            fi
            if type "${task}_prepare" &>/dev/null; then
                runFunctionSafe "${task}_prepare" "${runnerArgs[@]}"
                local exit=$?
                if [ "$exit" != 0 ]; then
                    PROPERTIES=()
                    copyAssociativeArray taskEnvLast PROPERTIES
                    PARAMETERS=()
                    copyAssociativeArray parametersEnvLast PARAMETERS
                    cleanTaskEnvironment "$task" "$tasksDir/$task.task" "$isProject" "$projectId" "$projectDir" "${runnerArgs[@]}"
                    return $exit
                fi
            fi

            # Show log
            if [ "$isProject" == true ]; then
                echo "> $projectId:$task : $LOCALPROJECTID : RUN"
            else
                echo "> $task : $LOCALPROJECTID : RUN"
            fi

            # Call run
            runFunctionSafe "${task}_run" "${runnerArgs[@]}"
            local exit=$?
            if [ "$exit" != 0 ]; then
                PROPERTIES=()
                copyAssociativeArray taskEnvLast PROPERTIES
                PARAMETERS=()
                copyAssociativeArray parametersEnvLast PARAMETERS
                cleanTaskEnvironment "$task" "$tasksDir/$task.task" "$isProject" "$projectId" "$projectDir" "${runnerArgs[@]}"
                return $exit
            fi

            # Call finish
            if type "${task}_finish" &>/dev/null; then
                # Show log
                if [ "$isProject" == true ]; then
                    echo "> $projectId:$task : $LOCALPROJECTID : FINISH"
                else
                    echo "> $task : $LOCALPROJECTID : FINISH"
                fi

                runFunctionSafe "${task}_finish" "${runnerArgs[@]}"
                local exit=$?
                if [ "$exit" != 0 ]; then
                    PROPERTIES=()
                    copyAssociativeArray taskEnvLast PROPERTIES
                    PARAMETERS=()
                    copyAssociativeArray parametersEnvLast PARAMETERS
                    cleanTaskEnvironment "$task" "$tasksDir/$task.task" "$isProject" "$projectId" "$projectDir" "${runnerArgs[@]}"
                    return $exit
                fi
            fi

            # Clean environment
            PROPERTIES=()
            copyAssociativeArray taskEnvLast PROPERTIES
            PARAMETERS=()
            copyAssociativeArray parametersEnvLast PARAMETERS
            unset -f "${task}_prepare"
            unset -f "${task}_run"
            unset -f "${task}_finish"
            unset -f "${task}_define"
            cleanTaskEnvironment "$task" "$tasksDir/$task.task" "$isProject" "$projectId" "$projectDir" "${runnerArgs[@]}"

            # Found task
            # Run post-tasks
            tasksDependenciesExecPost "$task" "$isProject" "$projectId" "$projectDir" || return 1
            
            # Return
            return $exit
        fi
    fi
    return 1
}
