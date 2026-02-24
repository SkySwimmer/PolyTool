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
    local callTaskListLast=("${ANTIRECURSIONLIST[@]}")
    ANTIRECURSIONLIST=()

    # Run task if needed
    local taskFoundLast="$taskFound"
    taskFound=false
    runTaskWithRunnerIfNeeded "$task" relativeExecuteRunner "${taskParams[@]}"
    local result=$?

    # Revert list
    ANTIRECURSIONLIST=("${callTaskListLast[@]}")

    # Handle
    if [ "$result" != 0 ]; then
        if [ "$taskFound" != true ]; then
            1>&2 echo "Error: task not recognized: $task"
            printStackTrace 1
            taskFound="$taskFoundLast"
            return 1
        else
            1>&2 echo "Error: task exited with non-zero exit code"
            printStackTrace 1
            taskFound="$taskFoundLast"
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
    local callTaskListLast=("${ANTIRECURSIONLIST[@]}")
    ANTIRECURSIONLIST=()

    # Run task if needed
    local taskFoundLast="$taskFound"
    taskFound=false
    runTaskWithRunner "$task" relativeExecuteRunner "${taskParams[@]}"
    local result=$?

    # Revert list
    ANTIRECURSIONLIST=("${callTaskListLast[@]}")

    # Handle
    if [ "$result" != 0 ]; then
        if [ "$taskFound" != true ]; then
            1>&2 echo "Error: task not recognized: $task"
            printStackTrace 1
            taskFound="$taskFoundLast"
            return 1
        else
            1>&2 echo "Error: task exited with non-zero exit code"
            printStackTrace 1
            taskFound="$taskFoundLast"
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
    local callTaskListLast=("${ANTIRECURSIONLIST[@]}")
    ANTIRECURSIONLIST=()

    # Run task if needed
    local taskFoundLast="$taskFound"
    taskFound=false
    runTaskWithRunnerIfNeeded "$task" singleExecuteRunner "${taskParams[@]}"
    local result=$?

    # Revert list
    ANTIRECURSIONLIST=("${callTaskListLast[@]}")

    # Handle
    if [ "$result" != 0 ]; then
        if [ "$taskFound" != true ]; then
            1>&2 echo "Error: task not recognized: $task"
            printStackTrace 1
            taskFound="$taskFoundLast"
            return 1
        else
            1>&2 echo "Error: task exited with non-zero exit code"
            printStackTrace 1
            taskFound="$taskFoundLast"
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
    local callTaskListLast=("${ANTIRECURSIONLIST[@]}")
    ANTIRECURSIONLIST=()

    # Run task if needed
    local taskFoundLast="$taskFound"
    taskFound=false
    runTaskWithRunner "$task" singleExecuteRunner "${taskParams[@]}"
    local result=$?

    # Revert list
    ANTIRECURSIONLIST=("${callTaskListLast[@]}")

    # Handle
    if [ "$result" != 0 ]; then
        if [ "$taskFound" != true ]; then
            1>&2 echo "Error: task not recognized: $task"
            printStackTrace 1
            taskFound="$taskFoundLast"
            return 1
        else
            1>&2 echo "Error: task exited with non-zero exit code"
            printStackTrace 1
            taskFound="$taskFoundLast"
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
    local taskFoundLast="$taskFound"
    taskFound=false
    runTaskWithRunnerIfNeeded "$task" relativeExecuteRunner "${taskParams[@]}"
    local result=$?

    # Handle
    if [ "$result" != 0 ]; then
        if [ "$taskFound" != true ]; then
            1>&2 echo "Error: task not recognized: $task"
            printStackTrace 1
            taskFound="$taskFoundLast"
            return 1
        else
            1>&2 echo "Error: task exited with non-zero exit code"
            printStackTrace 1
            taskFound="$taskFoundLast"
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
    local taskFoundLast="$taskFound"
    taskFound=false
    runTaskWithRunner "$task" relativeExecuteRunner "${taskParams[@]}"
    local result=$?
    
    # Handle
    if [ "$result" != 0 ]; then
        if [ "$taskFound" != true ]; then
            1>&2 echo "Error: task not recognized: $task"
            printStackTrace 1
            taskFound="$taskFoundLast"
            return 1
        else
            1>&2 echo "Error: task exited with non-zero exit code"
            printStackTrace 1
            taskFound="$taskFoundLast"
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
    local taskFoundLast="$taskFound"
    taskFound=false
    runTaskWithRunnerIfNeeded "$task" singleExecuteRunner "${taskParams[@]}"
    local result=$?
    
    # Handle
    if [ "$result" != 0 ]; then
        if [ "$taskFound" != true ]; then
            1>&2 echo "Error: task not recognized: $task"
            printStackTrace 1
            taskFound="$taskFoundLast"
            return 1
        else
            1>&2 echo "Error: task exited with non-zero exit code"
            printStackTrace 1
            taskFound="$taskFoundLast"
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
    local taskFoundLast="$taskFound"
    taskFound=false
    runTaskWithRunner "$task" singleExecuteRunner "${taskParams[@]}"
    local result=$?
    
    # Handle
    if [ "$result" != 0 ]; then
        if [ "$taskFound" != true ]; then
            1>&2 echo "Error: task not recognized: $task"
            printStackTrace 1
            taskFound="$taskFoundLast"
            return 1
        else
            1>&2 echo "Error: task exited with non-zero exit code"
            printStackTrace 1
            taskFound="$taskFoundLast"
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

    # Process parameters
    local skip=0
    local i=0
    local len="${#runnerArgs[@]}"
    for arg in "${runnerArgs[@]}"; do
        # Check argument skip
        if ((skip > 0)); then
            skip=$((skip-1))
            continue
        fi

        # Add argument if needed
        if [ "$arg" == "--" ]; then 
            # End, rest is plain
            break
        elif [[ "$arg" == "--"* ]]; then 
            # Substring it
            local key="${arg#*--}"
            local valuePresent=false
            local value="true"

            # Check syntax
            if [[ "$key" == *=* ]]; then
                value="${key#*=}"
                key="${key%=*}"
                valuePresent=true
            fi

            # Check required arguments
            local id="$taskFile-$projectId"
            local paramsSetId="${TASKS_PARAMETERLISTS["$id"]}"
            local paramsList=()
            eval 'paramsList=("${parameters_'"$paramsSetId"'[@]}")'
            local sheetsList=()
            eval 'sheetsList=("${helpsheets_'"$paramsSetId"'[@]}")'
            
            # Check parameters
            if [ "${PARAMETERS_REQUIRE_VALUE["$id-$key"]}" == "true" ]; then
                # Require value
                if [ "$valuePresent" != true ] && ((i + 1 < len)); then
                    i=$((i+1))
                    skip=$((skip+1))
                    value="${runnerArgs[$i]}"
                    valuePresent=true
                elif [ "$valuePresent" != true ]; then
                    1>&2 echo "Error: missing value for '$key' argument"
                    exit 1
                fi
            fi

            # Check value
            local i2=$((i+1))
            if [ "$valuePresent" != true ] && ((i2 < len)) && [[ "${runnerArgs[$i2]}" != "--"* ]]; then
                i=$((i+1))
                skip=$((skip+1))
                value="${runnerArgs[$i]}"
                valuePresent=true
            fi

            # Check key
            if [ "$key" != "" ]; then
                PARAMETERS+=(["$key"]="$value")
            fi
        fi

        i=$((i+1))
    done

    # Read arguments
    # Global property assignment
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
            if ([ "$key" == "assign-global" ] || [ "$key" == "global-property" ]); then
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
                    PROPERTIES+=(["$valueKey"]="$value")
                fi
            fi
        elif [[ "$arg" == "-X"* ]]; then 
            # Global is handled by the polytool main method, but lets still assign here
            # -X = assign global
            # -L = assign local
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

    # Read arguments
    # Local property assignment
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
            if ([ "$key" == "assign-local" ] || [ "$key" == "local-property" ]); then
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
                    PROPERTIES+=(["$valueKey"]="$value")
                    LOCALPROPERTIES+=(["$valueKey"]="$value")

                    # Update properties of project
                    local setId="${projectsSetIds["$LOCALPROJECTID"]}"
                    eval 'locals_'"$setId"'+=(["$valueKey"]="$value")'
                fi
            fi
        elif ([[ "$arg" == "-L"* ]]); then 
            # Assign locals
            # -L = assign local property
            local key="${arg#*-L}"
            if [[ "$key" == *=* ]]; then
                value="${arg#*=}"
                key="${key%=*}"
                
                # Update properties
                PROPERTIES+=(["$key"]="$value")
                LOCALPROPERTIES+=(["$key"]="$value")

                # Update properties of project
                local setId="${projectsSetIds["$LOCALPROJECTID"]}"
                eval 'locals_'"$setId"'+=(["$key"]="$value")'
            fi
        fi
        i=$((i+1))
    done

    # Read arguments
    # Task property assignment
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
            if ([ "$key" == "assign-property" ] || [ "$key" == "property" ]); then
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
        elif ([[ "$arg" == "-P"* ]]); then 
            # Assign locals
            # -P = assign task property
            local key="${arg#*-P}"
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

function requireTask() {
    local task="$1"
    if [ "$task" == "" ]; then
        1>&2 echo "Error: missing argument 'task' in requireTask"
        printStackTrace 1
        return 1
    fi
    dependsList+=("$task")
}

function addTaskTo() {
    local task="$1"
    if [ "$task" == "" ]; then
        1>&2 echo "Error: missing argument 'task' in requireTask"
        printStackTrace 1
        return 1
    fi
    loadOntoList+=("$task")
}

function afterTask() {
    local task="$1"
    if [ "$task" == "" ]; then
        1>&2 echo "Error: missing argument 'task' in afterTask"
        printStackTrace 1
        return 1
    fi
    loadAfterList+=("$task")
}

function beforeTask() {
    local task="$1"
    if [ "$task" == "" ]; then
        1>&2 echo "Error: missing argument 'task' in beforeTask"
        printStackTrace 1
        return 1
    fi
    loadBeforeList+=("$task")
}

function defineParameter() {
    local param="$1"
    local description="$2"
    if [ "$param" == "" ]; then
        1>&2 echo "Error: missing argument 'parameter name' in defineParameter"
        printStackTrace 1
        return 1
    fi
    if [ "$description" == "" ]; then
        1>&2 echo "Error: missing argument 'short description' in defineParameter"
        printStackTrace 1
        return 1
    fi

    # Define
    parametersList+=(["$param"]="$description")
}

function defineHelpArticle() {
    local keyword="$1"
    local path="$2"
    if [ "$keyword" == "" ]; then
        1>&2 echo "Error: missing argument 'keyword' in defineHelpArticle"
        printStackTrace 1
        return 1
    fi
    if [ "$path" == "" ]; then
        1>&2 echo "Error: missing argument 'file path' in defineHelpArticle"
        printStackTrace 1
        return 1
    fi

    # Define
    helpsheetsList+=(["$keyword"]="$path")
}

function defineParameterSyntax() {
    local param="$1"
    local value="$2"
    if [ "$param" == "" ]; then
        1>&2 echo "Error: missing argument 'parameter name' in defineParameterSyntax"
        printStackTrace 1
        return 1
    fi
    if [ "$value" == "" ]; then
        1>&2 echo "Error: missing argument 'syntax' in defineParameterSyntax"
        printStackTrace 1
        return 1
    fi

    # Define
    parametersSyntaxes+=(["$param"]="$value")
}

function defineParameterDescription() {
    local param="$1"
    local value="$2"
    if [ "$param" == "" ]; then
        1>&2 echo "Error: missing argument 'parameter name' in defineParameterDescription"
        printStackTrace 1
        return 1
    fi
    if [ "$value" == "" ]; then
        1>&2 echo "Error: missing argument 'full description' in defineParameterDescription"
        printStackTrace 1
        return 1
    fi

    # Define
    parametersFullDescs+=(["$param"]="$value")
}

function defineParameterSetRequired() {
    local param="$1"
    local value="$2"
    if [ "$param" == "" ]; then
        1>&2 echo "Error: missing argument 'parameter name' in defineParameterSetRequired"
        printStackTrace 1
        return 1
    fi
    if [ "$value" == "" ]; then
        1>&2 echo "Error: missing argument 'required' in defineParameterSetRequired"
        printStackTrace 1
        return 1
    fi
    if [ "$value" != "true" ] && [ "$value" != "false" ]; then
        1>&2 echo "Error: invalid argument 'required' in defineParameterSetRequired: expected true or false, got $value"
        printStackTrace 1
        return 1
    fi

    # Define
    parametersRequired+=(["$param"]="$value")
}

function defineParameterSetRequireValue() {
    local param="$1"
    local value="$2"
    if [ "$param" == "" ]; then
        1>&2 echo "Error: missing argument 'parameter name' in defineParameterSetRequireValue"
        printStackTrace 1
        return 1
    fi
    if [ "$value" == "" ]; then
        1>&2 echo "Error: missing argument 'required' in defineParameterSetRequireValue"
        printStackTrace 1
        return 1
    fi
    if [ "$value" != "true" ] && [ "$value" != "false" ]; then
        1>&2 echo "Error: invalid argument 'required' in defineParameterSetRequireValue: expected true or false, got $value"
        printStackTrace 1
        return 1
    fi

    # Define
    parametersRequireValue+=(["$param"]="$value")
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
    runRelativeToCallerProject=false

    # Syntax
    taskDescriptionShort=""
    taskDescriptionFull=""
    taskSyntaxHint=""
    taskReceiveAllArgs=false

    # Parameters
    declare -Ag parametersList=()
    declare -Ag parametersSyntaxes=()
    declare -Ag parametersFullDescs=()
    declare -Ag parametersRequired=()
    declare -Ag parametersRequireValue=()

    # Help sheets
    declare -Ag helpsheetsList=()
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
    if [ "$runRelativeToCallerProject" == "true" ]; then
        TASKS_RELATIVE_TO_CALLER+=("$projectId-$task")
    fi

    # Task key
    local taskKey="$projectId-$task"
    if [ "$isProject" != true ]; then
        taskKey="RUNTIME@$LOCALPROJECTID@$task"
    fi
    
    # Add task
    local targetProject="$projectId"
    if [ "$isProject" != true ]; then
        targetProject="$LOCALPROJECTID"
    fi
    AVAILABLE_TASKS+=(["$taskFile-$targetProject"]="$task")
    AVAILABLE_TASKS_LIST+=("$taskFile-$targetProject")

    # Set syntax fields
    TASKS_FILES+=(["$taskFile-$targetProject"]="$taskFile")
    TASKS_KEYS+=(["$taskFile-$targetProject"]="$taskKey")
    TASKS_DESCRIPTIONSHORT+=(["$taskFile-$targetProject"]="$taskDescriptionShort")
    TASKS_DESCRIPTIONFULL+=(["$taskFile-$targetProject"]="$taskDescriptionFull")
    TASKS_SYNTAX+=(["$taskFile-$targetProject"]="$taskSyntaxHint")

    # Task parameters
    if [ "${TASKS_PARAMETERLISTS["$taskFile-$targetProject"]}" == "" ]; then
        local setId="$(tr -dc A-Za-z0-9 </dev/urandom | head -c 24)"
        while arrayContains "$setId" setIds ; do
            setId="$(tr -dc A-Za-z0-9 </dev/urandom | head -c 24)"
        done
        setIds+=("$setId")
        TASKS_PARAMETERLISTS+=(["$taskFile-$targetProject"]="$setId")
    fi
    local setId="${TASKS_PARAMETERLISTS["$taskFile-$targetProject"]}"
    eval 'parameters_'"$setId"'=()'

    # Help sheets
    if [ "${TASKS_HELPSHEETLISTS["$taskFile-$targetProject"]}" == "" ]; then
        local setId="$(tr -dc A-Za-z0-9 </dev/urandom | head -c 24)"
        while arrayContains "$setId" setIds ; do
            setId="$(tr -dc A-Za-z0-9 </dev/urandom | head -c 24)"
        done
        setIds+=("$setId")
        TASKS_HELPSHEETLISTS+=(["$taskFile-$targetProject"]="$setId")
    fi
    local setId="${TASKS_HELPSHEETLISTS["$taskFile-$targetProject"]}"
    eval 'helpsheets_'"$setId"'=()'

    # Settings
    if [ "$taskReceiveAllArgs" == "true" ]; then
        TASKS_OWNPARSEREQUIRED+=("$taskFile-$targetProject")
    fi

    # Assign parameters
    for paramName in "${!parametersList[@]}"; do
        local shortDescription="${parametersList["$paramName"]}"
        local fullDescription="${parametersFullDescs["$paramName"]}"
        local syntax="${parametersSyntaxes["$paramName"]}"
        local required="${parametersRequired["$paramName"]}"
        local requireValue="${parametersRequireValue["$paramName"]}"

        local setId="${TASKS_PARAMETERLISTS["$taskFile-$targetProject"]}"
        eval "parameters_$setId"'+=("$paramName")'
        PARAMETERS_NAME+=(["$taskFile-$targetProject-$paramName"]="$paramName")
        PARAMETERS_REQUIRED+=(["$taskFile-$targetProject-$paramName"]="$required")
        PARAMETERS_SYNTAX+=(["$taskFile-$targetProject-$paramName"]="$syntax")
        PARAMETERS_DESCRIPTIONSHORT+=(["$taskFile-$targetProject-$paramName"]="$shortDescription")
        PARAMETERS_DESCRIPTIONFULL+=(["$taskFile-$targetProject-$paramName"]="$fullDescription")
        PARAMETERS_REQUIRE_VALUE+=(["$taskFile-$targetProject-$paramName"]="$requireValue")
    done

    # Assign help sheets
    for keyword in "${!helpsheetsList[@]}"; do
        local relativePath="${helpsheetsList["$keyword"]}"

        # Get local path
        local cPWD="$PWD"
        if [ "$isProject" == true ]; then
            cd "$projectDir"
        else
            cd "$RUNTIMEPATH/builtin"
        fi
        local fullPath="$(readlink -f "$relativePath")"
        cd "$cPWD"

        # Check
        if [ ! -f "$fullPath" ]; then
            1>&2 echo "Error: task load error: failed to define task '$task' of project $projectId: could not find help article file $relativePath"
            exit 1
        fi

        # Add
        local setId="${TASKS_HELPSHEETLISTS["$taskFile-$targetProject"]}"
        eval "helpsheets_$setId"'+=("$keyword")'
        TASKS_HELPSHEETS_KEYWORDS+=(["$taskFile-$targetProject-$keyword"]="$fullPath")
    done
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
    unset runRelativeToCallerProject
    unset taskDescriptionShort
    unset taskDescriptionFull
    unset taskSyntaxHint
    unset parametersList
    unset parametersSyntaxes
    unset parametersFullDescs
    unset parametersRequired
    unset parametersRequireValue
    unset helpsheetsList
    unset taskReceiveAllArgs
}
