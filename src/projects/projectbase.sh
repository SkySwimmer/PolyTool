#!/bin/bash

requiredCommands+=("uuidgen")

function loadProject() {
    # Setup
    local projectDir="$1"
    local projectRealDir="$2"
    local projectName="$3"
    local callback="$4"

    # Check polyfile
    if [ ! -f "$projectRealDir/polyfile.pcb" ] && [ ! -f "$projectRealDir/Polyfile.pcb" ]; then
        1>&2 echo "Error: no Polyfile.pcb in project $projectName ($projectDir)"
        return 1
    fi

    # Get real path
    local projectRealDir="$(readlink -f "$projectRealDir")"

    # Apply environment variables
    if [ "$ROOTPROJECT" == "undefined" ]; then
        ROOTPROJECT="$projectRealDir"
    fi
    if [ "$BASEPROJECT" == "undefined" ]; then
        BASEPROJECT="$projectRealDir"
    fi
    LOCALPROJECT="$projectRealDir"
    if [ "$ROOTBUILDDIR" == "undefined" ]; then
        ROOTBUILDDIR="$projectRealDir/build"
    fi
    if [ "$BASEBUILDDIR" == "undefined" ]; then
        BASEBUILDDIR="$projectRealDir/build"
    fi
    BUILDDIR="$projectRealDir/build"

    # Load polyfile
    preparePolyFileEnvironment
    name="$(basename "$projectRealDir")"
    if [ -f "$projectRealDir/polyfile.pcb" ]; then
        source "$projectRealDir/polyfile.pcb"
    elif [ -f "$projectRealDir/Polyfile.pcb" ]; then
        source "$projectRealDir/Polyfile.pcb"
    fi
    if [ "$name" != "$(basename "$projectRealDir")" ]; then
        projectName="$name"
    fi
    if [ "$ROOTPROJECT" == "undefined" ]; then
        ROOTPROJECTID="$id"
    fi
    if [ "$BASEPROJECTID" == "undefined" ]; then
        BASEPROJECTID="$id"
    fi
    LOCALPROJECTID="$id"

    # Check if loaded
    # This is done post-sourcing so the project properties are still as expected
    if [ "${projectsByDir["$projectRealDir"]}" != "" ]; then
        # Same project loaded

        # Call callback
        if [ "$callback" != "" ]; then
            "$callback" "$id" "$projectName" "$projectDir" "$projectRealDir"
        fi
        return 0
    fi
    if [ "${projectsByGroupAndId["$group/$id"]}" != "" ]; then
        # Found project with same ID and group, safe to ignore

        # Call callback
        if [ "$callback" != "" ]; then
            "$callback" "$id" "$projectName" "$projectDir" "$projectRealDir"
        fi
        return 0
    fi

    # Handle settings
    echo "Loading project $name ($id) from $projectDir..."
    if [ "$id" == "undefined" ]; then
        1>&2 echo "Error: polyfile of project $projectName ($projectDir) did not assign an 'id' field!"
        return 1
    fi
    if [ "$version" == "undefined" ]; then
        1>&2 echo "Error: polyfile of project $projectName ($projectDir) did not assign a 'version' field!"
        return 1
    fi
    if [ "$group" == "undefined" ]; then
        1>&2 echo "Error: polyfile of project $projectName ($projectDir) did not assign a 'group' field!"
        return 1
    fi

    # Check conflict
    if [ "${projects["$id"]}" != "" ]; then
        # Found project with same ID but at different location
        1>&2 echo "Error: double project ID $id with different groups, loading project: $projectName ($projectDir), previously loaded project: ${projectsNames["$id"]} (${projectsDirFriendly["$id"]})"
        return 1
    fi

    # Create lists
    local subprojectListId="$(uuidgen | sed "s/-//g")"
    local dependencyListId="$subprojectListId"
    eval 'declare '"dependencies_$subprojectListId"'=()'
    eval 'declare '"subprojects_$subprojectListId"'=()'

    # Create project entry
    projects+=(
        ["$id"]="$projectRealDir"
    )
    projectsByDir+=(
        ["$projectRealDir"]="$id"
    )
    projectsByGroupAndId+=(
        ["$group/$id"]="$projectRealDir"
    )
    projectsNames+=(
        ["$id"]="$projectName"
    )
    projectsDirFriendly+=(
        ["$id"]="$projectDir"
    )
    projectsBaseProject+=(
        ["$id"]="$BASEPROJECT"
    )
    projectsSubProjectSetIds+=(
        ["$id"]="$subprojectListId"
    )

    # Load dependencies that are present
    # FIXME: load dependency sheets for this instead of raw
    for path in "$projectRealDir/dependencies/"*/; do
        # Load dependency project if polyfile is present
        if [ -d "$path" ] && ([ -f "$path/polyfile.pcb" ] || [ -f "$path/Polyfile.pcb" ]); then
            # Load dependency

            # Prepare paths
            local pathName="$(basename "$path")"
            local currentId=id
            local pathpretty="$projectDir/dependencies/$pathName"
            local fullpath="$(readlink -f "$path")"

            # Get current base
            local baseProject="$BASEPROJECT"
            local baseBuild="$BASEBUILDDIR"

            # Unset, dependencies each are treated as a base
            BASEPROJECT=undefined
            BASEBUILDDIR=undefined
            
            # Try loading it
            name="dependency $pathName"
            if ! loadProject "$pathpretty" "$fullpath" "dependency $pathName" ; then
                1>&2 echo "Error: error loading project: $projectName ($id, $projectDir): dependency \"$pathName\" could not be loaded"
                return 1
            fi
            BASEPROJECT="$baseProject"
            BASEBUILDDIR="$baseBuild"

            # Loaded successfully
            # Add project to list
            eval "dependencies_$subprojectListId"'+=("'"$id"'")'
        fi
    done
    
    # Restore env
    preparePolyFileEnvironment
    name="$(basename "$projectRealDir")"
    if [ -f "$projectRealDir/polyfile.pcb" ]; then
        source "$projectRealDir/polyfile.pcb"
    elif [ -f "$projectRealDir/Polyfile.pcb" ]; then
        source "$projectRealDir/Polyfile.pcb"
    fi
    if [ "$name" != "$(basename "$projectRealDir")" ]; then
        projectName="$name"
    fi

    # Load sub projects
    for path in "${subProjectPaths[@]}"; do
        # Check existence
        local fullpath="$projectRealDir/$path"
        if [ -d "$fullpath" ]; then
            # Found sub-project folder
            local currentId=id
            local pathpretty="$projectDir/$path"
            local fullpath="$(readlink -f "$fullpath")"
            
            # Try loading it
            name="subproject $path"
            if ! loadProject "$pathpretty" "$fullpath" "subproject $path" ; then
                1>&2 echo "Error: error loading project: $projectName ($id, $projectDir): sub-project \"$path\" could not be loaded"
                return 1
            fi

            # Loaded successfully
            # Add project to list
            eval "subprojects_$subprojectListId"'+=("'"$id"'")'
        else
            # Cant find the project
            1>&2 echo "Error: error loading project: $projectName ($id, $projectDir): sub-project path \"$path\" could not be found"
            return 1
        fi
    done
    
    # Restore env
    preparePolyFileEnvironment
    name="$(basename "$projectRealDir")"
    if [ -f "$projectRealDir/polyfile.pcb" ]; then
        source "$projectRealDir/polyfile.pcb"
    elif [ -f "$projectRealDir/Polyfile.pcb" ]; then
        source "$projectRealDir/Polyfile.pcb"
    fi
    if [ "$name" != "$(basename "$projectRealDir")" ]; then
        projectName="$name"
    fi

    # Call load callback
    if [ "$callback" != "" ]; then
        "$callback" "$id" "$projectName" "$projectDir" "$projectRealDir"
    fi

    # Success
    return 0
}


function preparePolyFileEnvironment() {
    id="undefined"
    version="undefined"
    group="undefined"
    name="undefined"
    subProjectPaths=()
}

function runLocalToProject() {
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
