#!/bin/bash

function main() {    
    local args=("$@")

    # Check dependencies
    local missingdep=false
    for cmd in "${requiredCommands[@]}"; do
        if ! checkInstalled "$cmd" ; then
            1>&2 echo "Error: missing required command $cmd, please make sure to install this dependency via your system package manager."
            missingdep=true
        fi
    done
    if [ "$missingdep" == "true" ]; then
        1>&2 echo "Error: cannot proceed, missing requirements"
        exit 1
    fi

    # Load project
    echo Loading projects...
    if ! loadProject "<root>" "$PWD" "<root project>" ; then
        if [ ! -f "$PWD/polyfile.pcb" ] && [ ! -f "$PWD/Polyfile.pcb" ]; then
            1>&2 echo "Error: cannot proceed, please make sure the polyfile exists prior to running polytool"
        else
            1>&2 echo "Error: cannot proceed, root project could not be loaded"
        fi
        exit 1
    fi
    ROOTPROJECTID="$id"
    ROOTPROJECTNAME="$name"
    ROOTPROJECTVERSION="$version"
    if ! runLocalToProject "$ROOTPROJECTID" loadProjectDependencies ; then
        if [ ! -f "$PWD/polyfile.pcb" ] && [ ! -f "$PWD/Polyfile.pcb" ]; then
            1>&2 echo "Error: cannot proceed, please make sure the polyfile exists prior to running polytool"
        else
            1>&2 echo "Error: cannot proceed, root project could not be loaded"
        fi
        exit 1
    fi
    if ! runLocalToProject "$ROOTPROJECTID" loadProjectDependencies true ; then
        if [ ! -f "$PWD/polyfile.pcb" ] && [ ! -f "$PWD/Polyfile.pcb" ]; then
            1>&2 echo "Error: cannot proceed, please make sure the polyfile exists prior to running polytool"
        else
            1>&2 echo "Error: cannot proceed, root project could not be loaded"
        fi
        exit 1
    fi

    # Done loading
    echo

    # Setup
    echo "Root project: $ROOTPROJECTNAME ($ROOTPROJECTID), version $ROOTPROJECTVERSION"
    echo "Preparing task runner..."

    # Process arguments like the project
    local skip=0
    local i=0
    local taskEnd=false
    local len="${#args[@]}"
    for arg in "${args[@]}"; do
        # Check argument skip
        if ((skip > 0)); then
            skip=$((skip-1))
            continue
        fi

        # Add argument if needed
        if [ "$arg" == "--" ]; then 
            # No more tasks, remainer args are to be passed to the next task
            taskEnd=true
            i=$((i+1))
            continue
        elif [[ "$arg" == "--"* ]]; then 
            # Substring it
            local key="${arg#*--}"
            local valuePresent=false
            local value=""

            # Check syntax
            if [[ "$key" == *=* ]]; then
                value="${key#*=}"
                key="${key%=*}"
                valuePresent=true
            fi

            # Check key
            if [ "$key" == "project" ]; then
                if [ "$valuePresent" != true ] && ((i + 1 < len)); then
                    i=$((i+1))
                    skip=$((skip+1))
                    value="${args[$i]}"
                    valuePresent=true
                elif [ "$valuePresent" != true ]; then
                    1>&2 echo "Error: missing value for 'project' argument"
                    exit 1
                fi

                # Check project
                if [ "${projects["$value"]}" == "" ]; then
                    # Error
                    1>&2 echo "Error: project not recognized: $value"
                    exit 1
                fi
            fi
        fi

        i=$((i+1))
    done

    # Find tasks to run
    # Syntax: [arguments for runtime] task [arguments] another-task [arguments] ...
    local taskParams=()
    local lastTask=""
    local helpSubject=""
    local displayHelp=false
    local taskEnd=false
    local hadTask=false
    local relativeToProject="$ROOTPROJECTID"
    local skip=0
    local i=0
    local currentTaskFile=""
    local currentTaskProject=""
    for arg in "${args[@]}"; do
        local argBak="$arg"

        # Check argument skip
        if ((skip > 0)); then
            skip=$((skip-1))
            continue
        fi

        # Handle globals
        # Done ruring argument handling so that global assignment arguments are relative to each task
        # Locals cannot be done here due to how they are stored per project, loading those is handled by tasks
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
                    valueKey="${args[$i]}"
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
                    value="${args[$i]}"
                    valuePresent=true
                fi
                if [ "$valuePresent" == true ] && [ "$valueKeyPresent" == true ]; then
                    # Update properties
                    GLOBALPROPERTIES+=(["$valueKey"]="$value")
                    
                    # Add statement
                    taskParams+=("--$key")
                    taskParams+=("$valueKey")
                    taskParams+=("$value")
                    i=$((i+1))
                    continue
                fi
            elif ([ "$key" == "assign-local" ] || [ "$key" == "local-property" ]); then
                if [ "$valueKeyPresent" != true ] && ((i + 1 < len)); then
                    i=$((i+1))
                    skip=$((skip+1))
                    valueKey="${args[$i]}"
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
                    value="${args[$i]}"
                    valuePresent=true
                fi
                if [ "$valuePresent" == true ] && [ "$valueKeyPresent" == true ]; then
                    # Add statement
                    taskParams+=("--$key")
                    taskParams+=("$valueKey")
                    taskParams+=("$value")
                    i=$((i+1))
                    continue
                fi
            elif ([ "$key" == "assign-property" ] || [ "$key" == "property" ]); then
                if [ "$valueKeyPresent" != true ] && ((i + 1 < len)); then
                    i=$((i+1))
                    skip=$((skip+1))
                    valueKey="${args[$i]}"
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
                    value="${args[$i]}"
                    valuePresent=true
                fi
                if [ "$valuePresent" == true ] && [ "$valueKeyPresent" == true ]; then
                    # Add statement
                    taskParams+=("--$key")
                    taskParams+=("$valueKey")
                    taskParams+=("$value")
                    i=$((i+1))
                    continue
                fi
            fi
        elif [[ "$arg" == "-X"* ]]; then 
            # Assign global
            local key="${arg#*-X}"
            if [[ "$key" == *=* ]]; then
                value="${arg#*=}"
                key="${key%=*}"
                
                # Update properties
                GLOBALPROPERTIES+=(["$key"]="$value")
            fi
        fi
        
        # Add argument if needed
        if [ "$arg" == "--" ]; then 
            # No more tasks, remainer args are to be passed to the next task
            taskEnd=true
            i=$((i+1))
            continue
        elif [[ "$arg" == "--"* ]]; then 
            # Substring it
            local key="${arg#*--}"
            local valuePresent=false
            local value=""

            # Check syntax
            if [[ "$key" == *=* ]]; then
                value="${key#*=}"
                key="${key%=*}"
                valuePresent=true
            fi

            # Check key
            if [ "$key" == "project" ]; then
                if [ "$valuePresent" != true ] && ((i + 1 < len)); then
                    i=$((i+1))
                    skip=$((skip+1))
                    value="${args[$i]}"
                    valuePresent=true
                fi

                # Check project
                if [ "${projects["$value"]}" == "" ]; then
                    # Error
                    1>&2 echo "Error: project not recognized: $value"
                    exit 1
                fi
                relativeToProject="$value"
            elif [ "$key" == "help" ]; then
                if [ "$valuePresent" != true ] && ((i + 1 < len)) && [ "$lastTask" != "" ]; then
                    i=$((i+1))
                    skip=$((skip+1))
                    value="${args[$i]}"
                    valuePresent=true
                fi
                helpSubject="$value"
                helpTask=true
            else
                # Check required arguments
                if [ "$currentTaskFile" != "" ]; then
                    # Task resolved
                    local id="$currentTaskFile-$currentTaskProject"
                    local paramsSetId="${TASKS_PARAMETERLISTS["$id"]}"
                    local helpSheetSetId="${TASKS_HELPSHEETLISTS["$id"]}"
                    local paramsList=()
                    eval 'paramsList=("${parameters_'"$paramsSetId"'[@]}")'
                    local sheetsList=()
                    eval 'sheetsList=("${helpsheets_'"$helpSheetSetId"'[@]}")'
                    
                    # Check parameters
                    if [ "${PARAMETERS_REQUIRE_VALUE["$id-$key"]}" == "true" ]; then
                        # Require value
                        if [ "$valuePresent" != true ] && ((i + 1 < len)); then
                            i=$((i+1))
                            skip=$((skip+1))
                            value="${args[$i]}"
                            valuePresent=true
                        elif [ "$valuePresent" != true ]; then
                            1>&2 echo "Error: missing value for '$key' argument"
                            exit 1
                        fi

                        # Add argument
                        taskParams+=("--$key")
                        taskParams+=("$value")
                        i=$((i+1))
                        continue
                    fi
                fi
            fi

            # Add argument
            taskParams+=("$arg")
            i=$((i+1))
            continue
        elif [[ "$arg" == "-"* ]]; then 
            taskParams+=("$arg")
            i=$((i+1))
            continue
        fi

        if [ "$taskEnd" != "true" ]; then
            # Resolve task
            currentTaskFile=""
            currentTaskProject=""
            local taskFileLast="$taskFile"
            local taskResolveFoundLast="$taskResolveFound"
            local resolvedProjectLast="$resolvedProject"
            resolvedProject=""
            taskFile=""
            taskResolveFound=false
            resolveTask "$arg" resolveCallbackList
            arg="$argBak"
            runLocalToProject "$relativeToProject" loadIndividualTask "$arg"
            arg="$argBak"
            local resolveResult="$taskResolveFound"
            local resolveResultFile="$taskFile"
            local resolveResultProject="$resolvedProject"
            taskFile="$taskFileLast"
            resolvedProject="$resolvedProjectLast"
            taskResolveFound="$taskResolveFoundLast"
            
            # Check result
            if [ "$resolveResult" == true ]; then
                # Task recognized
                currentTaskFile="$resolveResultFile"
                currentTaskProject="$resolveResultProject"

                # Check argument parser
                if arrayContains "$currentTaskFile-$currentTaskProject" TASKS_OWNPARSEREQUIRED; then
                    # End of arguments
                    taskEnd=true
                fi
            fi

            # Run previous task if needed
            if [ "$lastTask" != "" ]; then 
                # Check help
                if [ "$helpTask" == "true" ]; then
                    # Got help argument

                    # Load tasks
                    local taskResolveFoundLast="$taskResolveFound"
                    runLocalToProject "$relativeToProject" loadIndividualTask "$lastTask"
                    arg="$argBak"
                    local resolveResult="$taskResolveFound"
                    taskResolveFound="$taskResolveFoundLast"
                    if [ "$resolveResult" == "true" ]; then
                        # Blank line
                        echo
                        echo

                        # Check
                        if [ "$helpSubject" == "" ]; then
                            # Reassign subject
                            local foundTask=false
                            for arg in "${args[@]}"; do
                                if [ "$foundTask" == "false" ]; then
                                    if [ "$arg" == "$lastTask" ]; then
                                        foundTask=true
                                    fi
                                else
                                    helpSubject="$arg"
                                    break
                                fi
                            done
                        fi

                        # Print help
                        runLocalToProject "$relativeToProject" printHelpPage "$lastTask" "$helpSubject"
                        
                        return
                    fi
                fi
                
                # Check required arguments
                local runOkay=true
                if [ "$currentTaskFile" != "" ]; then
                    # Task resolved
                    local id="$currentTaskFile-$currentTaskProject"
                    local paramsSetId="${TASKS_PARAMETERLISTS["$id"]}"
                    local helpSheetSetId="${TASKS_HELPSHEETLISTS["$id"]}"
                    local paramsList=()
                    eval 'paramsList=("${parameters_'"$paramsSetId"'[@]}")'
                    local sheetsList=()
                    eval 'sheetsList=("${helpsheets_'"$helpSheetSetId"'[@]}")'
                            
                    # Check parameters
                    for paramName in "${paramsList[@]}"; do
                        # Check required
                        if [ "${PARAMETERS_REQUIRED["$id-$paramName"]}" == true ]; then
                            # Check present
                            if ! arrayContains "--$paramName" taskParams; then
                                echo
                                1>&2 echo "Error: missing required parameter '$paramName' for task '$lastTask'"
                                1>&2 echo "See \`polytool $lastTask --help $paramName\` for more info"
                                runOkay=false
                            fi
                        fi
                    done
                fi

                # Run task
                hadTask=true
                taskFound=false
                local exit=0
                if [ "$runOkay" == true ]; then
                    runLocalToProject "$relativeToProject" runTask "$lastTask" "${taskParams[@]}"
                    exit=$?
                else
                    exit=1
                fi
                arg="$argBak"
                if [ "$exit" != 0 ]; then
                    # Handle error exit
                    echo -------------------------

                    # Check exit status
                    if [ "$taskFound" != true ]; then
                        # Task not recognized
                        1>&2 echo "Error: could not recognize task \"$lastTask\" as a runnable task"
                    else
                        1>&2 echo "Error: task \"$lastTask\" exited with non-zero exit status!"
                    fi

                    # Error
                    1>&2 echo "Warning: not all tasks could be completed!"
                    exit "$exit"
                fi
                lastTask=""
                taskParams=()
                relativeToProject="$ROOTPROJECTID"
            fi

            # Mark last task, so when argument
            lastTask="$arg"
        else
            # Add arguments for next task
            taskParams+=("$arg")
        fi

        i=$((i+1))
    done
    if [ "$lastTask" != "" ]; then 
        # Check help
        if [ "$helpTask" == "true" ]; then
            # Got help argument

            # Load tasks
            local taskResolveFoundLast="$taskResolveFound"
            runLocalToProject "$relativeToProject" loadIndividualTask "$lastTask"
            local resolveResult="$taskResolveFound"
            taskResolveFound="$taskResolveFoundLast"
            if [ "$resolveResult" == "true" ]; then
                # Blank line
                echo
                echo

                # Check
                if [ "$helpSubject" == "" ]; then
                    # Reassign subject
                    local foundTask=false
                    for arg in "${args[@]}"; do
                        if [ "$foundTask" == "false" ]; then
                            if [ "$arg" == "$lastTask" ]; then
                                foundTask=true
                            fi
                        else
                            if [ "$arg" != "--help" ]; then
                                helpSubject="$arg"
                            fi
                            break
                        fi
                    done
                fi

                # Print help
                runLocalToProject "$relativeToProject" printHelpPage "$lastTask" "$helpSubject"
                
                return
            fi
        fi

        # Check required arguments
        local runOkay=true
        if [ "$currentTaskFile" != "" ]; then
            # Task resolved
            local id="$currentTaskFile-$currentTaskProject"
            local paramsSetId="${TASKS_PARAMETERLISTS["$id"]}"
            local helpSheetSetId="${TASKS_HELPSHEETLISTS["$id"]}"
            local paramsList=()
            eval 'paramsList=("${parameters_'"$paramsSetId"'[@]}")'
            local sheetsList=()
            eval 'sheetsList=("${helpsheets_'"$helpSheetSetId"'[@]}")'
                    
            # Check parameters
            for paramName in "${paramsList[@]}"; do
                # Check required
                if [ "${PARAMETERS_REQUIRED["$id-$paramName"]}" == true ]; then
                    # Check present
                    if ! arrayContains "--$paramName" taskParams; then
                        echo
                        1>&2 echo "Error: missing required parameter '$paramName' for task '$lastTask'"
                        1>&2 echo "See \`polytool $lastTask --help $paramName\` for more info"
                        runOkay=false
                    fi
                fi
            done
        fi

        # Run task
        hadTask=true
        taskFound=false
        local exit=0
        if [ "$runOkay" == true ]; then
            runLocalToProject "$relativeToProject" runTask "$lastTask" "${taskParams[@]}"
            exit=$?
        else
            exit=1
        fi
        if [ "$exit" != 0 ]; then
            # Handle error exit
            echo -------------------------

            # Check exit status
            if [ "$taskFound" != true ]; then
                # Task not recognized
                1>&2 echo "Error: could not recognize task \"$lastTask\" as a runnable task"
            else
                1>&2 echo "Error: task \"$lastTask\" exited with non-zero exit status!"
            fi

            # Error
            1>&2 echo "Warning: not all tasks could be completed!"
            exit "$exit"
        fi
        lastTask=""
        taskParams=()
    fi

    # Check result
    if [ "$hadTask" != true ]; then
        # Check help statement
        for arg in "${args[@]}"; do
            if [ "$arg" == "--help" ]; then
                # Got help argument

                # Blank line
                echo
                echo

                # Print help
                printHelpPage "" ""
                
                return
            fi
            if [ "$arg" == "--list-tasks" ]; then
                # Got help argument

                # Load tasks
                runLocalToProject "$relativeToProject" loadTasksBase "internal@listtasks"

                # Blank line
                echo
                echo

                # Print tasks list
                runLocalToProject "$relativeToProject" printTasksList
                
                return
            fi
        done

        # Echo
        echo
        1>&2 echo "Usage: polytool <tasks to run...>"
        exit 1
    fi

    # Done
    echo -------------------------
    echo PolyTool Tasks Completed!
}

function loadTasksBase() {
    environmentPrepareProjectTasks "$1" "$LOCALPROJECTID" "$LOCALPROJECT"
}

function printHelpPage() {
    local helpTask="$1"
    local helpSubject="$2"

    if [ "$helpTask" == "" ]; then
        # Print
        echo "PolyTool Help Page and Documentation:"
        echo "-------------------------------------"
        echo
        echo "PolyTool is a task runner and basic project manager, primarily intended for creating bash-based tasks that can be called on projects."
        echo "Usage: polytool [<polytool parameters>] <task 1> [<task parameters...>] <task 2> [<task parameters...>]"
        echo
        echo
        echo "The tool expects named tasks to be used as arguments, eg. \`polytool restore\`, where restore is the task"
        echo "Arguments refer to any argument passed to the command line, whereas parameters refer to arguments that are preceeded with \`--\` or \`-\`"
        echo
        echo "Any unprefixed (no preceeding \`-\` or \`--\`) argument is treated as a Task name to run, prefixed arguments are used as parameters"
        echo "Prefixed arguments are used as task parameters for the given task."
        echo
        echo "Using \`polytool test --abc=def --hello restore --test\` will pass \`--abc=def --hello\` to the task \`test\`, and passes \`--test\` to \`restore\`"
        echo
        echo "PolyTool Documentation Parameters: (only work without tasks specified)"
        echo " --help - When used without specifying a task, this help page is displayed"
        echo " --help \"<task>\" - When used with a task in the argument, a help page for a specific task is displayed"
        echo " --help \"<task>\" \"<keyword>\" - Displays the help article for a specific subject available for the task"
        echo " --help \"<task>\" \"<parameter>\" - Displays the help article for a specific parameter of the task"
        echo " --list-tasks - Shows a list of available tasks"
        echo
        echo "PolyTool Runtime Parameters: (across all tasks)"
        echo " --project \"<project id>\" - Selects the project to use for task execution"
        echo " --assign-global \"<property>\" \"<value>\" - Assigns global properties accessible to all projects and tasks"
        echo " --assign-global \"<property>\"=\"<value>\" - Assigns global properties accessible to all projects and tasks"
        echo " --assign-global:<property>=\"<value>\" - Assigns global properties accessible to all projects and tasks"
        echo " --global-property \"<property>\" \"<value>\" - Assigns global properties accessible to all projects and tasks"
        echo " --global-property \"<property>\"=\"<value>\" - Assigns global properties accessible to all projects and tasks"
        echo " --global-property:<property>=\"<value>\" - Assigns global properties accessible to all projects and tasks"
        echo " --assign-local \"<property>\" \"<value>\" - Assigns local properties accessible to the current project and tasks"
        echo " --assign-local \"<property>\"=\"<value>\" - Assigns local properties accessible to the current project and tasks"
        echo " --assign-local:<property>=\"<value>\" - Assigns local properties accessible to the current project and tasks"
        echo " --local-property \"<property>\" \"<value>\" - Assigns local properties accessible to the current project and tasks"
        echo " --local-property \"<property>\"=\"<value>\" - Assigns local properties accessible to the current project and tasks"
        echo " --local-property:<property>=\"<value>\" - Assigns local properties accessible to the current project and tasks"
        echo " -X<property>=\"<value>\" - Assigns global properties accessible to all projects and tasks"
        echo " -L<property>=\"<value>\" - Assigns local properties accessible to the current project and task"
        echo
        echo "PolyTool Task Parameters:"
        echo " --help - When used from a task, the help page for a specific task is displayed"
        echo " --help \"<keyword>\" - Displays the help article for a specific subject available for the task"
        echo " --help \"<parameter>\" - Displays the help article for a specific parameter of the task"
        echo " --assign-property \"<property>\" \"<value>\" - Assigns task properties to the current task"
        echo " --assign-property \"<property>\"=\"<value>\" - Assigns task properties to the current task"
        echo " --assign-property:<property>=\"<value>\" - Assigns task properties to the current task"
        echo " --property \"<property>\" \"<value>\" - Assigns task properties to the current task"
        echo " --property \"<property>\"=\"<value>\" - Assigns task properties to the current task"
        echo " --property:<property>=\"<value>\" - Assigns task properties to the current task"
        echo " -P<property>=\"<value>\" - Assigns task properties to the current task"
        echo
        echo "Note: parameters are only assigned when the task runs, and only those attached to the task will be assigned."
        echo "Note: for example: properties can be assigned multiple times with different values for different tasks."
        echo
        echo "Use \`polytool --list-tasks\` for a list of tasks that are available."
        echo
        echo "-------------------------------------"
    else
        # Print splash
        echo "PolyTool Help Page and Documentation:"
        echo "-------------------------------------"
        echo
        
        # Check subject
        # Get task path
        local taskFileLast="$taskFile"
        local taskResolveFoundLast="$taskResolveFound"
        local resolvedProjectLast="$resolvedProject"
        resolvedProject=""
        taskFile=""
        taskResolveFound=false
        resolveTask "$helpTask" resolveCallbackList
        local resolveResult="$taskResolveFound"
        local resolveResultFile="$taskFile"
        local resolveResultProject="$resolvedProject"
        taskFile="$taskFileLast"
        resolvedProject="$resolvedProjectLast"
        taskResolveFound="$taskResolveFoundLast"
        if [ "$resolveResult" == "true" ]; then
            # Get task properties
            local id="$resolveResultFile-$resolveResultProject"
            local name="${AVAILABLE_TASKS["$id"]}"
            local syntax="${TASKS_SYNTAX["$id"]}"
            local shortDescription="${TASKS_DESCRIPTIONSHORT["$id"]}"
            local fullDescription="${TASKS_DESCRIPTIONFULL["$id"]}"
            local paramsSetId="${TASKS_PARAMETERLISTS["$id"]}"
            local helpSheetSetId="${TASKS_HELPSHEETLISTS["$id"]}"
            local paramsList=()
            eval 'paramsList=("${parameters_'"$paramsSetId"'[@]}")'
            local sheetsList=()
            eval 'sheetsList=("${helpsheets_'"$helpSheetSetId"'[@]}")'

            # Check subject
            if [ "$helpSubject" == "" ]; then
                # Get description
                local description="$shortDescription"
                if [ "$fullDescription" != "" ]; then
                    description="$fullDescription"
                fi
                if [ "$shortDescription" == "" ]; then
                    shortDescription="No description provided"
                fi

                # Show
                echo "Task: $name"
                if [ "$syntax" != "" ]; then
                    echo "Task syntax: $syntax"
                fi
                echo "Description: $shortDescription"
                if [ "$description" != "" ]; then
                    echo
                    echo
                    echo "$description"
                    if [ "${#paramsList[@]}" != 0 ] || [ "${#sheetsList[@]}" != 0 ]; then
                        echo
                    fi
                fi

                # Check parameters
                if [ "${#paramsList[@]}" != 0 ]; then
                    echo
                    echo "Task parameters:"
                    local anyRequired=false
                    for param in "${paramsList[@]}"; do
                        # Load
                        local paramName="$param"
                        local required="${PARAMETERS_REQUIRED["$id-$param"]}"
                        local requireValue="${PARAMETERS_REQUIRE_VALUE["$id-$param"]}"
                        local syntax="${PARAMETERS_SYNTAX["$id-$param"]}"
                        local descriptionShort="${PARAMETERS_DESCRIPTIONSHORT["$id-$param"]}"
                        local descriptionFull="${PARAMETERS_DESCRIPTIONFULL["$id-$param"]}"
                        if [ "$required" ]; then
                            anyRequired=true
                        fi
                        
                        # Create string
                        local listStr=" --$paramName"
                        if [ "$syntax" != "" ]; then
                            listStr="$listStr=$syntax"
                        fi
                        if [ "$shortDescription" != "" ]; then
                            listStr="$listStr - $descriptionShort"
                        fi

                        # List
                        echo "$listStr"
                        if [ "$requireValue" == "true" ]; then
                           local listStr=" --$paramName"
                            if [ "$syntax" != "" ]; then
                                listStr="$listStr $syntax"
                            fi
                            if [ "$shortDescription" != "" ]; then
                                listStr="$listStr - $descriptionShort"
                            fi

                            # List
                            echo "$listStr"
                        fi
                    done
                    if [ "$anyRequired" == "true" ]; then
                        echo
                        echo Required parameters:
                        for param in "${paramsList[@]}"; do
                            # Load
                            local paramName="$param"
                            local syntax="${PARAMETERS_SYNTAX["$id-$param"]}"
                            local requireValue="${PARAMETERS_REQUIRE_VALUE["$id-$param"]}"

                            # Create string
                            local listStr=" --$paramName"
                            if [ "$syntax" != "" ]; then
                                listStr="$listStr=$syntax"
                            fi

                            # List
                            echo "$listStr"
                            if [ "$requireValue" == "true" ]; then
                                local listStr=" --$paramName"
                                if [ "$syntax" != "" ]; then
                                    listStr="$listStr $syntax"
                                fi

                                # List
                                echo "$listStr"
                            fi
                        done
                    fi
                fi

                # Articles
                if [ "${#sheetsList[@]}" != 0 ]; then
                    echo
                    echo "Help articles:"
                    for keyword in "${sheetsList[@]}"; do
                        local file="${TASKS_HELPSHEETS_KEYWORDS["$id-$keyword"]}"

                        local name=""
                        local title=""
                        local shortDescription=""
                        local i=0
                        while read -r line ; do
                            if [ "$i" == 0 ]; then
                                name="$line"
                            elif [ "$i" == 1 ]; then
                                title="$line"
                            elif [ "$i" == 2 ]; then
                                shortDescription="$line"
                                break # We dont need the rest of the file
                            fi
                            i=$((i+1))
                        done < "$file"

                        # List
                        echo " - Subject '$keyword' - $name - $shortDescription"
                    done
                fi

                # Trailer
                if [ "${#paramsList[@]}" != 0 ] && [ "${#sheetsList[@]}" == 0 ]; then
                    echo
                    echo "For more information on a parameter, use \`polytool $helpTask --help \"<parameter>\"\`"
                    echo "For additional parameters that could be assigned (eg. polytool's own parameters), see \`polytool --help\`"
                elif [ "${#paramsList[@]}" != 0 ] && [ "${#sheetsList[@]}" != 0 ]; then
                    echo
                    echo "For more information on a parameter or subject, use \`polytool $helpTask --help \"<subject>\"\`"
                    echo "For additional parameters that could be assigned (eg. polytool's own parameters), see \`polytool --help\`"
                elif [ "${#paramsList[@]}" == 0 ] && [ "${#sheetsList[@]}" != 0 ]; then
                    echo
                    echo "For more information on a help article subject, use \`polytool $helpTask --help \"<subject>\"\`"
                    echo "For additional information on using polytool, see \`polytool --help\`"
                fi
            else
                # Check subject
                local helpSubjectCurrent="$helpSubject"
                if [[ "$helpSubjectCurrent" == "--"* ]]; then
                    helpSubjectCurrent="${helpSubjectCurrent#*--}"
                fi
                if [ "${TASKS_HELPSHEETS_KEYWORDS["$id-$helpSubjectCurrent"]}" != "" ]; then
                    # Subject
                    local keyword="$helpSubjectCurrent"
                    
                    # Load subject
                    local file="${TASKS_HELPSHEETS_KEYWORDS["$id-$keyword"]}"

                    # Load data
                    local name=""
                    local title=""
                    local shortDescription=""
                    local fullDescription=""
                    local i=0
                    while read -r line ; do
                        if [ "$i" == 0 ]; then
                            name="$line"
                        elif [ "$i" == 1 ]; then
                            title="$line"
                        elif [ "$i" == 2 ]; then
                            shortDescription="$line"
                        else
                            fullDescription="$fullDescription$line"$'\n'
                        fi
                        i=$((i+1))
                    done < "$file"
                    fullDescription="$(echo "$fullDescription")"

                    # Show
                    echo "Help Article: $name"
                    echo "Article Title: $title"
                    echo
                    echo "$fullDescription"
                elif [ "${PARAMETERS_REQUIRED["$id-$helpSubjectCurrent"]}" != "" ]; then
                    # Parameter
                    local param="$helpSubjectCurrent"
                    local required="${PARAMETERS_REQUIRED["$id-$param"]}"
                    local requireValue="${PARAMETERS_REQUIRE_VALUE["$id-$param"]}"
                    local syntax="${PARAMETERS_SYNTAX["$id-$param"]}"
                    local descriptionShort="${PARAMETERS_DESCRIPTIONSHORT["$id-$param"]}"
                    local descriptionFull="${PARAMETERS_DESCRIPTIONFULL["$id-$param"]}"
                    
                    # Get description
                    local description="$descriptionShort"
                    if [ "$descriptionFull" != "" ]; then
                        description="$descriptionFull"
                    fi
                    if [ "$descriptionShort" == "" ]; then
                        descriptionShort="No description provided"
                    fi

                    # Show
                    echo "Parameter name: $param"
                    local requireHR="No"
                    if [ "$required" == true ]; then
                        requireHR="Yes"
                    fi
                    echo "Required parameter: $requireHR"
                    if [ "$syntax" != "" ]; then
                        echo "Parameter syntax: $syntax"
                        echo "Usage with task: polytool $helpTask --$param=$syntax"
                    else
                        echo "Usage with task: polytool $helpTask --$param"
                    fi
                    echo "Description: $descriptionShort"
                    if [ "$description" != "" ]; then
                        echo
                        echo
                        echo "$description"
                    fi
                else
                    echo "Unable to find article with subject '$helpSubject'"
                fi 
            fi
        fi

        # Print finish
        echo
        echo "-------------------------------------"
    fi
}

function printTasksList() {
    # Print
    echo "PolyTool Help Page and Documentation:"
    echo "-------------------------------------"
    echo
    echo "PolyTool is a task runner and basic project manager, primarily intended for creating bash-based tasks that can be called on projects."
    echo "Usage: polytool [<polytool parameters>] <task 1> [<task parameters...>] <task 2> [<task parameters...>]"
    echo
    echo "List of available tasks:"
    local listedTasks=()

    # List tasks
    antiRecursion=()
    for id in "${AVAILABLE_TASKS_LIST[@]}"; do
        local file="${TASKS_FILES["$id"]}"
        if ! arrayContains "$file" listedTasks ; then
            listTaskCollections "$file" "$id"
        fi
    done
    antiRecursion=()
    for id in "${AVAILABLE_TASKS_LIST[@]}"; do
        local file="${TASKS_FILES["$id"]}"
        if ! arrayContains "$file" listedTasks ; then
            listTaskDependencies "$file" "$id"
        fi
    done
    antiRecursion=()
    for id in "${AVAILABLE_TASKS_LIST[@]}"; do
        local file="${TASKS_FILES["$id"]}"
        if ! arrayContains "$file" listedTasks ; then
            listTask "$file" "$id"
        fi
    done

    echo
    echo "-------------------------------------"
}

function resolveCallbackList() {
    resolvedProject="$LOCALPROJECTID"
}

function listTaskDependencies() {
    local file="$1"
    local id="$2"
    if arrayContains "$file" antiRecursion ; then
        return
    fi
    antiRecursion+=("$file")

    # Go through dependencies
    local taskKey="${TASKS_KEYS["$id"]}"
    local setId="${TASKS_DEPENDENCY_LIST_IDS["$taskKey"]}"
    local name="${AVAILABLE_TASKS["$id"]}"
    if [ "$setId" != "" ]; then
        # Got sets!
        eval 'local dependsList=("${'"requiresTask_$setId"'[@]}")'
        eval 'local loadOntoList=("${'"addTo_$setId"'[@]}")'
        eval 'local loadAfterList=("${'"afterTask_$setId"'[@]}")'
        eval 'local loadBeforeList=("${'"beforeTask_$setId"'[@]}")'

        # Go through require
        for depName in "${loadAfterList[@]}"; do
            local taskFileLast="$taskFile"
            local taskResolveFoundLast="$taskResolveFound"
            local resolvedProjectLast="$resolvedProject"
            resolvedProject=""
            taskFile=""
            taskResolveFound=false
            resolveTask "$depName" resolveCallbackList
            local resolveResult="$taskResolveFound"
            local resolveResultFile="$taskFile"
            local resolveResultProject="$resolvedProject"
            taskFile="$taskFileLast"
            resolvedProject="$resolvedProjectLast"
            taskResolveFound="$taskResolveFoundLast"
            if [ "$resolveResult" == "true" ]; then
                local localId="$resolveResultFile-$resolveResultProject"
                if ! arrayContains "$resolveResultFile" listedTasks ; then
                    local antiRecursionLast=("${antiRecursion[@]}")
                    listTask "$resolveResultFile" "$localId"
                    antiRecursion=("${antiRecursionLast[@]}")
                    listTaskDependencies "$resolveResultFile" "$localId"
                fi
            fi
        done
    fi
}

function listTaskCollections() {
    local file="$1"
    local id="$2"
    if arrayContains "$file" antiRecursion ; then
        return
    fi
    antiRecursion+=("$file")

    # Go through dependencies
    local taskKey="${TASKS_KEYS["$id"]}"
    local setId="${TASKS_DEPENDENCY_LIST_IDS["$taskKey"]}"
    local name="${AVAILABLE_TASKS["$id"]}"
    if [ "$setId" != "" ]; then
        # Got sets!
        eval 'local dependsList=("${'"requiresTask_$setId"'[@]}")'
        eval 'local loadOntoList=("${'"addTo_$setId"'[@]}")'
        eval 'local loadAfterList=("${'"afterTask_$setId"'[@]}")'
        eval 'local loadBeforeList=("${'"beforeTask_$setId"'[@]}")'

        # Go through load onto
        for depName in "${loadOntoList[@]}"; do
            local taskFileLast="$taskFile"
            local taskResolveFoundLast="$taskResolveFound"
            local resolvedProjectLast="$resolvedProject"
            resolvedProject=""
            taskFile=""
            taskResolveFound=false
            resolveTask "$depName" resolveCallbackList
            local resolveResult="$taskResolveFound"
            local resolveResultFile="$taskFile"
            local resolveResultProject="$resolvedProject"
            taskFile="$taskFileLast"
            resolvedProject="$resolvedProjectLast"
            taskResolveFound="$taskResolveFoundLast"
            if [ "$resolveResult" == "true" ]; then
                local localId="$resolveResultFile-$resolveResultProject"
                if ! arrayContains "$resolveResultFile" listedTasks ; then
                    local antiRecursionLast=("${antiRecursion[@]}")
                    listTaskCollections "$resolveResultFile" "$localId"
                    antiRecursion=("${antiRecursionLast[@]}")
                    local antiRecursionLast=("${antiRecursion[@]}")
                    listTaskDependencies "$resolveResultFile" "$localId"
                    antiRecursion=("${antiRecursionLast[@]}")
                    listTask "$resolveResultFile" "$localId"
                fi
            fi
        done
    fi
}

function listTask() {
    local file="$1"
    local id="$2"
    if arrayContains "$file" antiRecursion ; then
        return
    fi
    antiRecursion+=("$file")

    # List
    listedTasks+=("$file")
    local name="${AVAILABLE_TASKS["$id"]}"
    local syntax="${TASKS_SYNTAX["$id"]}"
    local shortDescription="${TASKS_DESCRIPTIONSHORT["$id"]}"

    # Create string
    local listStr=" - $name"
    if [ "$syntax" != "" ]; then
        listStr="$listStr $syntax"
    fi
    if [ "$shortDescription" != "" ]; then
        listStr="$listStr - $shortDescription"
    fi

    # List
    echo "$listStr"
}
