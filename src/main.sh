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

    # Done loading
    echo

    # Setup
    echo "Root project: $name ($id), version $version"

    # Read arguments
    local skip=0
    local i=0
    local len="${#args[@]}"
    for arg in "${args[@]}"; do
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
                    GLOBALPROPERTIES+=(["$key"]="$value")
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
        i=$((i+1))
    done

    # Process arguments like the project
    local skip=0
    local i=0
    local taskEnd=false
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
            fi
        fi

        i=$((i+1))
    done

    # Find tasks to run
    # Syntax: task [arguments] another-task [arguments] ...
    local taskParams=()
    local lastTask=""
    local taskEnd=false
    local hadTask=false
    local relativeToProject="$ROOTPROJECTID"
    local skip=0
    local i=0
    for arg in "${args[@]}"; do
        local argBak="$arg"

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
            # Run previous task if needed
            if [ "$lastTask" != "" ]; then 
                # Run task
                hadTask=true
                taskFound=false
                runLocalToProject "$relativeToProject" runTask "$lastTask" "${taskParams[@]}"
                arg="$argBak"
                local exit=$?
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
        # Run task
        hadTask=true
        taskFound=false
        runLocalToProject "$relativeToProject" runTask "$lastTask" "${taskParams[@]}"
        exit=$?
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
        echo
        1>&2 echo "Usage: polytool <tasks to run...>"
        exit 1
    fi

    # Done
    echo -------------------------
    echo PolyTool Tasks Completed!
}
