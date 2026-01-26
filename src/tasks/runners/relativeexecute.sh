#!/bin/bash

function relativeExecuteRunner() {
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
        runLocalToProject "$projectId" relativeExecuteRunner "$onlyWhenNeeded" "$task" "${runnerArgs[@]}"
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
    taskRunnerProjectRelativePrepare "$onlyWhenNeeded" "$task" "$localProjectId" "$localProjectDir" "${runnerArgs[@]}"
    local exit=$?
    if [ "$exit" != 0 ]; then
        return $exit
    fi

    # Check found
    if [ "$taskFound" != "true" ]; then
        # No tasks found
        return 1
    fi

    # Call run
    taskRunnerProjectRelativeRun "$onlyWhenNeeded" "$task" "$localProjectId" "$localProjectDir" "${runnerArgs[@]}"
    local exit=$?
    if [ "$exit" != 0 ]; then
        return $exit
    fi

    # Call run
    taskRunnerProjectRelativeFinish "$onlyWhenNeeded" "$task" "$localProjectId" "$localProjectDir" "${runnerArgs[@]}"
    local exit=$?
    if [ "$exit" != 0 ]; then
        return $exit
    fi

    # Success
    return 0
}

function taskRunnerProjectRelativePrepare() {
    local args=("$@")

    # Parse command
    local onlyWhenNeeded="$1"
    local task="$2"
    local projectId="$3"
    local projectDir="$4"
    local runnerArgs=()
    arrayCopyOfRange args runnerArgs 4 "${#args[@]}"

    # Check state
    if [ "$onlyWhenNeeded" == "true" ]; then
        # Check if called
        if arrayContains "$projectId-$task" TASKSBEINGRUN_PREPARE && ! arrayContains "$projectId-$task" TASKS_PERMITTING_MULTIRUN; then
            # Already run
            if arrayContains "$projectId-$task" TASKS_FOUND; then
                taskFound=true
            fi
            if arrayContains "RUNTIME@$projectId@$task" TASKS_FOUND || arrayContains "RUNTIME@$task" TASKS_FOUND; then
                taskFound=true
            fi
            return 0
        fi
    fi

    # Add to task history
    if ! arrayContains "$projectId-$task" TASKSBEINGRUN_PREPARE; then
        # Add
        TASKSBEINGRUN_PREPARE+=("$projectId-$task")
    fi

    # Initialize tasks, this will also deal with base projects and root projects
    runLocalToProject "$projectId" environmentPrepareProjectTasks "$task" "$projectId" "$projectDir" "${runnerArgs[@]}"

    # Box recursion list
    # We basically copy the list, making it stack-sensitive
    # After this method finishes, we reset to what it was last
    # That way, cyclic calls are ignored without breaking other task files calling callTask for the same task
    local callTaskListLast=("${CALLINGTASKSLIST[@]}")
    CALLINGTASKSLIST=()
    CALLINGTASKSLIST+=("${callTaskListLast[@]}")

    # Get list ID
    local setId="${projectsSetIds["$projectId"]}"

    # Go through dependencies recursively
    # We stay relative to the current project
    eval 'dependenciesList=("${'"dependencies_$setId"'[@]}")'
    for depId in "${dependenciesList[@]}"; do
        local depDir="${projects["$depId"]}"

        # Run in dependency
        taskRunnerProjectRelativePrepare "$onlyWhenNeeded" "$task" "$depId" "$depDir" "${runnerArgs[@]}"
        local exit=$?
        if [ "$exit" != 0 ]; then
            return $exit
        fi
    done

    # Find task
    taskSensitiveRunLocalToProject true "$projectId" "$task" "$projectId" execTasksRelativePrepare "$task" "$projectDir/tasks" true "$projectId" "$projectDir" "${runnerArgs[@]}"
    local exit=$?

    # Add to task list
    # Only needs to be done here, not elsewhere
    if [ "$taskFound" == "true" ] && ! arrayContains "$projectId-$task" TASKS_FOUND; then
        # Add
        TASKS_FOUND+=("$projectId-$task")
    fi
    
    # Handle exit
    if [ "$exit" != 0 ]; then
        # Revert list
        CALLINGTASKSLIST=("${callTaskListLast[@]}")
        return $exit
    fi

    # Try finding it in the runtime
    local runtimeTaskDir="$RUNTIMEPATH/builtin/tasks"
    if [ -d "$runtimeTaskDir" ]; then
        # Check state
        local doRun=true
        if [ "$onlyWhenNeeded" == "true" ]; then
            # Check if called
            if (arrayContains "RUNTIME@$projectId@$task" TASKSBEINGRUN_PREPARE && ! arrayContains "RUNTIME@$projectId@$task" TASKS_PERMITTING_MULTIRUN) || (arrayContains "RUNTIME@$task" TASKSBEINGRUN_PREPARE && ! arrayContains "RUNTIME@$task" TASKS_PERMITTING_MULTIRUN); then
                # Revert list
                CALLINGTASKSLIST=("${callTaskListLast[@]}")
                
                # Already run
                if arrayContains "RUNTIME@$projectId@$task" TASKS_FOUND || arrayContains "RUNTIME@$task" TASKS_FOUND; then
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
            
            # Box again
            local callTaskListLast2=("${CALLINGTASKSLIST[@]}")
            CALLINGTASKSLIST=()
            CALLINGTASKSLIST+=("${callTaskListLast2[@]}")

            # Find task
            taskSensitiveRunLocalToProject false "$projectId" "$task" "$projectId" execTasksRelativePrepare "$task" "$runtimeTaskDir" false "" "" "${runnerArgs[@]}"
            local exit=$?

            # Revert
            CALLINGTASKSLIST=("${callTaskListLast2[@]}")

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
                CALLINGTASKSLIST=("${callTaskListLast[@]}")
                return $exit
            fi
        fi
    fi

    # Go through sub projects recursively
    # We stay relative to the current project
    eval 'subprojectsList=("${'"subprojects_$setId"'[@]}")'
    for subProjectId in "${subprojectsList[@]}"; do
        local subProjectDir="${projects["$subProjectId"]}"

        # Run in subproject
        taskRunnerProjectRelativePrepare "$onlyWhenNeeded" "$task" "$subProjectId" "$subProjectDir" "${runnerArgs[@]}"
        local exit=$?
        if [ "$exit" != 0 ]; then
            # Revert list
            CALLINGTASKSLIST=("${callTaskListLast[@]}")
            return $exit
        fi
    done

    # Revert list
    CALLINGTASKSLIST=("${callTaskListLast[@]}")
}

function taskRunnerProjectRelativeRun() {
    local args=("$@")

    # Parse command
    local onlyWhenNeeded="$1"
    local task="$2"
    local projectId="$3"
    local projectDir="$4"
    local runnerArgs=()
    arrayCopyOfRange args runnerArgs 4 "${#args[@]}"

    # Check state
    if [ "$onlyWhenNeeded" == "true" ]; then
        # Check if called
        if arrayContains "$projectId-$task" TASKSBEINGRUN_RUN && ! arrayContains "$projectId-$task" TASKS_PERMITTING_MULTIRUN; then
            # Already run
            if arrayContains "$projectId-$task" TASKS_FOUND; then
                taskFound=true
            fi
            if arrayContains "RUNTIME@$projectId@$task" TASKS_FOUND || arrayContains "RUNTIME@$task" TASKS_FOUND; then
                taskFound=true
            fi
            return 0
        fi
    fi

    # Add to task history
    if ! arrayContains "$projectId-$task" TASKSBEINGRUN_RUN; then
        # Add
        TASKSBEINGRUN_RUN+=("$projectId-$task")
    fi
    
    # Box recursion list
    # We basically copy the list, making it stack-sensitive
    # After this method finishes, we reset to what it was last
    # That way, cyclic calls are ignored without breaking other task files calling callTask for the same task
    local callTaskListLast=("${CALLINGTASKSLIST[@]}")
    CALLINGTASKSLIST=()
    CALLINGTASKSLIST+=("${callTaskListLast[@]}")

    # Get list ID
    local setId="${projectsSetIds["$projectId"]}"

    # Go through dependencies recursively
    # We stay relative to the current project
    eval 'dependenciesList=("${'"dependencies_$setId"'[@]}")'
    for depId in "${dependenciesList[@]}"; do
        local depDir="${projects["$depId"]}"

        # Run in dependency
        taskRunnerProjectRelativeRun "$onlyWhenNeeded" "$task" "$depId" "$depDir" "${runnerArgs[@]}"
        local exit=$?
        if [ "$exit" != 0 ]; then
            # Revert list
            CALLINGTASKSLIST=("${callTaskListLast[@]}")
            return $exit
        fi
    done

    # Find task
    taskSensitiveRunLocalToProject true "$projectId" "$task" "$projectId" execTasksRelativeRun "$task" "$projectDir/tasks" true "$projectId" "$projectDir" "${runnerArgs[@]}"
    local exit=$?
    if [ "$exit" != 0 ]; then
        # Revert list
        CALLINGTASKSLIST=("${callTaskListLast[@]}")
        return $exit
    fi

    # Try finding it in the runtime
    local runtimeTaskDir="$RUNTIMEPATH/builtin/tasks"
    if [ -d "$runtimeTaskDir" ]; then
        # Check state
        local doRun=true
        if [ "$onlyWhenNeeded" == "true" ]; then
            # Check if called
            if (arrayContains "RUNTIME@$projectId@$task" TASKSBEINGRUN_RUN && ! arrayContains "RUNTIME@$projectId@$task" TASKS_PERMITTING_MULTIRUN) || (arrayContains "RUNTIME@$task" TASKSBEINGRUN_RUN && ! arrayContains "RUNTIME@$task" TASKS_PERMITTING_MULTIRUN); then
                # Revert list
                CALLINGTASKSLIST=("${callTaskListLast[@]}")
                
                # Already run
                if arrayContains "RUNTIME@$projectId@$task" TASKS_FOUND || arrayContains "RUNTIME@$task" TASKS_FOUND; then
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
                    TASKSBEINGRUN_RUN+=("RUNTIME@$projectId@$task")
                else
                    TASKSBEINGRUN_RUN+=("RUNTIME@$task")
                fi    
            fi

            # Box again
            local callTaskListLast2=("${CALLINGTASKSLIST[@]}")
            CALLINGTASKSLIST=()
            CALLINGTASKSLIST+=("${callTaskListLast2[@]}")

            # Find task
            taskSensitiveRunLocalToProject false "$projectId" "$task" "$projectId" execTasksRelativeRun "$task" "$runtimeTaskDir" false "" "" "${runnerArgs[@]}"
            local exit=$?

            # Revert
            CALLINGTASKSLIST=("${callTaskListLast2[@]}")

            # Handle exit
            if [ "$exit" != 0 ]; then
                # Revert list
                CALLINGTASKSLIST=("${callTaskListLast[@]}")
                return $exit
            fi
        fi
    fi

    # Go through sub projects recursively
    # We stay relative to the current project
    eval 'subprojectsList=("${'"subprojects_$setId"'[@]}")'
    for subProjectId in "${subprojectsList[@]}"; do
        local subProjectDir="${projects["$subProjectId"]}"

        # Run in subproject
        taskRunnerProjectRelativeRun "$onlyWhenNeeded" "$task" "$subProjectId" "$subProjectDir" "${runnerArgs[@]}"
        local exit=$?
        if [ "$exit" != 0 ]; then
            # Revert list
            CALLINGTASKSLIST=("${callTaskListLast[@]}")
            return $exit
        fi
    done

    # Revert list
    CALLINGTASKSLIST=("${callTaskListLast[@]}")
}

function taskRunnerProjectRelativeFinish() {
    local args=("$@")

    # Parse command
    local onlyWhenNeeded="$1"
    local task="$2"
    local projectId="$3"
    local projectDir="$4"
    local runnerArgs=()
    arrayCopyOfRange args runnerArgs 4 "${#args[@]}"

    # Check state
    if [ "$onlyWhenNeeded" == "true" ]; then
        # Check if called
        if arrayContains "$projectId-$task" TASKSBEINGRUN_FINISH && ! arrayContains "$projectId-$task" TASKS_PERMITTING_MULTIRUN; then
            # Already run
            if arrayContains "$projectId-$task" TASKS_FOUND; then
                taskFound=true
            fi
            if arrayContains "RUNTIME@$projectId@$task" TASKS_FOUND || arrayContains "RUNTIME@$task" TASKS_FOUND; then
                taskFound=true
            fi
            return 0
        fi
    fi

    # Add to task history
    if ! arrayContains "$projectId-$task" TASKSBEINGRUN_FINISH; then
        # Add
        TASKSBEINGRUN_FINISH+=("$projectId-$task")
    fi
    
    # Box recursion list
    # We basically copy the list, making it stack-sensitive
    # After this method finishes, we reset to what it was last
    # That way, cyclic calls are ignored without breaking other task files calling callTask for the same task
    local callTaskListLast=("${CALLINGTASKSLIST[@]}")
    CALLINGTASKSLIST=()
    CALLINGTASKSLIST+=("${callTaskListLast[@]}")

    # Get list ID
    local setId="${projectsSetIds["$projectId"]}"

    # Go through dependencies recursively
    # We stay relative to the current project
    eval 'dependenciesList=("${'"dependencies_$setId"'[@]}")'
    for depId in "${dependenciesList[@]}"; do
        local depDir="${projects["$depId"]}"

        # Run in dependency
        taskRunnerProjectRelativeFinish "$onlyWhenNeeded" "$task" "$depId" "$depDir" "${runnerArgs[@]}"
        local exit=$?
        if [ "$exit" != 0 ]; then
            # Revert list
            CALLINGTASKSLIST=("${callTaskListLast[@]}")
            
            return $exit
        fi
    done

    # Find task
    taskSensitiveRunLocalToProject true "$projectId" "$task" "$projectId" execTasksRelativeFinish "$task" "$projectDir/tasks" true "$projectId" "$projectDir" "${runnerArgs[@]}"
    local exit=$?
    if [ "$exit" != 0 ]; then
        # Revert list
        CALLINGTASKSLIST=("${callTaskListLast[@]}")
        
        return $exit
    fi

    # Try finding it in the runtime
    local runtimeTaskDir="$RUNTIMEPATH/builtin/tasks"
    if [ -d "$runtimeTaskDir" ]; then
        # Check state
        local doRun=true
        if [ "$onlyWhenNeeded" == "true" ]; then
            # Check if called
            if (arrayContains "RUNTIME@$projectId@$task" TASKSBEINGRUN_FINISH && ! arrayContains "RUNTIME@$projectId@$task" TASKS_PERMITTING_MULTIRUN) || (arrayContains "RUNTIME@$task" TASKSBEINGRUN_FINISH && ! arrayContains "RUNTIME@$task" TASKS_PERMITTING_MULTIRUN); then
                # Revert list
                CALLINGTASKSLIST=("${callTaskListLast[@]}")
                
                # Already run
                if arrayContains "RUNTIME@$projectId@$task" TASKS_FOUND || arrayContains "RUNTIME@$task" TASKS_FOUND; then
                    taskFound=true
                fi
                doRun=false
            fi
        fi

        # Check
        if [ "$doRun" == "true" ]; then
            # Add to task history
            if ! arrayContains "RUNTIME@$projectId@$task" TASKSBEINGRUN_FINISH && ! arrayContains "RUNTIME@$task" TASKSBEINGRUN_FINISH; then
                # Add
                if ! arrayContains "$task" TASKS_RUNTIME_SHARED; then
                    TASKSBEINGRUN_FINISH+=("RUNTIME@$projectId@$task")
                else
                    TASKSBEINGRUN_FINISH+=("RUNTIME@$task")
                fi    
            fi

            # Box again
            local callTaskListLast2=("${CALLINGTASKSLIST[@]}")
            CALLINGTASKSLIST=()
            CALLINGTASKSLIST+=("${callTaskListLast2[@]}")

            # Find task
            taskSensitiveRunLocalToProject false "$projectId" "$task" "$projectId" execTasksRelativeFinish "$task" "$runtimeTaskDir" false "" "" "${runnerArgs[@]}"
            local exit=$?

            # Revert
            CALLINGTASKSLIST=("${callTaskListLast2[@]}")

            # Handle exit
            if [ "$exit" != 0 ]; then
                # Revert list
                CALLINGTASKSLIST=("${callTaskListLast[@]}")
                return $exit
            fi
        fi
    fi

    # Go through sub projects recursively
    # We stay relative to the current project
    eval 'subprojectsList=("${'"subprojects_$setId"'[@]}")'
    for subProjectId in "${subprojectsList[@]}"; do
        local subProjectDir="${projects["$subProjectId"]}"

        # Run in subproject
        taskRunnerProjectRelativeFinish "$onlyWhenNeeded" "$task" "$subProjectId" "$subProjectDir" "${runnerArgs[@]}"
        local exit=$?
        if [ "$exit" != 0 ]; then
            # Revert list
            CALLINGTASKSLIST=("${callTaskListLast[@]}")
            
            return $exit
        fi
    done

    # Revert list
    CALLINGTASKSLIST=("${callTaskListLast[@]}")
}


function execTasksRelativePrepare() {
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

            # Check recursion
            if arrayContains "$tasksDir/$task.task" CALLINGTASKSLIST; then
                return 0
            fi
            CALLINGTASKSLIST+=("$tasksDir/$task.task")
        
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
            local localTaskFile="$LOCALPROJECT/polylocal/tasks/$task.task"
            if [ -f "$localTaskFile" ]; then
                # Local overload
                source "$localTaskFile" || taskLoadError "<local>/polylocal/tasks/$task.task"
            fi

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

            # Call prepare
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

            # Return
            return $exit
        fi
    fi
}

function execTasksRelativeRun() {
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

            # Check recursion
            if arrayContains "$tasksDir/$task.task" CALLINGTASKSLIST; then
                return 0
            fi
            CALLINGTASKSLIST+=("$tasksDir/$task.task")
        
            # Show log
            if [ "$isProject" == true ]; then
                echo "> $LOCALPROJECTID : $projectId:$task -> RUN"
            else
                echo "> $LOCALPROJECTID : $task -> RUN"
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
            local localTaskFile="$LOCALPROJECT/tasks/$task.task"
            if [ -f "$localTaskFile" ]; then
                # Local overload
                source "$localTaskFile" || taskLoadError "<local>/tasks/$task.task"
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

            # Return
            return $exit
        fi
    fi
}

function execTasksRelativeFinish() {
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

            # Check recursion
            if arrayContains "$tasksDir/$task.task" CALLINGTASKSLIST; then
                return 0
            fi
            CALLINGTASKSLIST+=("$tasksDir/$task.task")
        
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
            local localTaskFile="$LOCALPROJECT/polylocal/tasks/$task.task"
            if [ -f "$localTaskFile" ]; then
                # Local overload
                source "$localTaskFile" || taskLoadError "<local>/polylocal/tasks/$task.task"
            fi

            # Call finish
            if type "${task}_finish" &>/dev/null; then
                # Show log
                if [ "$isProject" == true ]; then
                    echo "> $LOCALPROJECTID : $projectId:$task -> FINISH"
                else
                    echo "> $LOCALPROJECTID : $task -> FINISH"
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
}