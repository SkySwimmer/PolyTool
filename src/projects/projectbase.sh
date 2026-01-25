#!/bin/bash

requiredCommands+=("uuidgen")

function loadProject() {
    # Setup
    local projectDir="$1"
    local projectRealDir="$2"
    local projectName="$3"
    local callback="$4"
    local forceReload="$5"
    local logPrefix="$6"

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
    LOCALPROPERTIES=()

    # Check base
    if [ "$BASEPROJECTID" != "undefined" ]; then
        # Inherit from base
        local baseSetId="${projectsSetIds["$BASEPROJECTID"]}"
        eval 'LOCALPROPERTIES=("${locals_'"$baseSetId"'[@]}")'
    fi

    # Load polyfile
    preparePolyFileEnvironment
    name="$(basename "$projectRealDir")"
    if [ -f "$projectRealDir/polyfile.pcb" ]; then
        source "$projectRealDir/polyfile.pcb"
    elif [ -f "$projectRealDir/Polyfile.pcb" ]; then
        source "$projectRealDir/Polyfile.pcb"
    fi

    # Overload local
    if [ -f "$projectRealDir/polylocal/polyfile.pcb" ]; then
        source "$projectRealDir/polylocal/polyfile.pcb"
    elif [ -f "$projectRealDir/polylocal/Polyfile.pcb" ]; then
        source "$projectRealDir/polylocal/Polyfile.pcb"
    fi

    # Load properties
    if [ "$name" != "$(basename "$projectRealDir")" ]; then
        projectName="$name"
    fi
    if [ "$ROOTPROJECTID" == "undefined" ]; then
        ROOTPROJECTID="$id"
    fi
    if [ "$BASEPROJECTID" == "undefined" ]; then
        BASEPROJECTID="$id"
    fi
    LOCALPROJECTID="$id"
    if [ "$ROOTPROJECTVERSION" == "undefined" ]; then
        ROOTPROJECTVERSION="$version"
    fi
    if [ "$BASEPROJECTVERSION" == "undefined" ]; then
        BASEPROJECTVERSION="$version"
    fi
    if [ "$ROOTPROJECTGROUP" == "undefined" ]; then
        ROOTPROJECTGROUP="$group"
    fi
    if [ "$BASEPROJECTGROUP" == "undefined" ]; then
        BASEPROJECTGROUP="$group"
    fi
    LOCALPROJECTVERSION="$version"
    LOCALPROJECTGROUP="$group"

    # Check if loaded
    # This is done post-sourcing so the project properties are still as expected
    if [ "${projectsByDir["$projectRealDir"]}" != "" ] && [ "$forceReload" != "true" ]; then
        # Same project loaded

        # Call callback
        if [ "$callback" != "" ]; then
            "$callback" "$id" "$projectName" "$projectDir" "$projectRealDir"
        fi
        return 0
    fi
    if [ "${projectsByGroupAndId["$group/$id"]}" != "" ] && [ "$forceReload" != "true" ]; then
        # Found project with same ID and group, safe to ignore

        # Call callback
        if [ "$callback" != "" ]; then
            "$callback" "$id" "$projectName" "$projectDir" "$projectRealDir"
        fi
        return 0
    fi

    # Handle settings
    echo "${logPrefix}Loading project $name ($id) from $projectDir..."
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
        if [ "${projectsByDir["$projectRealDir"]}" == "" ] || [ "${projectsByGroupAndId["$group/$id"]}" == "" ]; then
            # Found project with same ID but at different location
            1>&2 echo "Error: double project ID $id with different groups, loading project: $projectName ($projectDir), previously loaded project: ${projectsNames["$id"]} (${projectsDirFriendly["$id"]})"
            return 1
        fi
    fi

    # Create lists
    local setId="$(uuidgen | sed "s/-//g")"
    while arrayContains "$setId" setIds ; do
        setId="$(uuidgen | sed "s/-//g")"
    done
    eval 'declare -g '"dependencies_$setId"'=()'
    eval 'declare -g '"subprojects_$setId"'=()'
    eval 'declare -g '"locals_$setId"'=()'

    # Update locals
    eval "locals_$setId"'=("${LOCALPROPERTIES[@]}")'
    eval "dependencies_$setId"'=()'
    eval "subprojects_$setId"'=()'

    # Create project entry
    projects+=(
        ["$id"]="$projectRealDir"
    )
    projectsGroups+=(
        ["$id"]="$group"
    )
    projectsVersions+=(
        ["$id"]="$version"
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
    projectsBaseProjectIds+=(
        ["$id"]="$BASEPROJECTID"
    )
    projectsSetIds+=(
        ["$id"]="$setId"
    )

    # Load dependencies that are present
    for path in "$projectRealDir/dependencies/"*.dep; do
        # Load dependency project if polyfile is present
        if [ -f "$path" ]; then
            # Load dependency sheet
            setupDependencyEnvironment "$path"
            source "$path" || loadDependencyError "$(basename "$path")"

            # Load overload
            local localOverload="$projectRealDir/polylocal/dependencies/$(basename "$path")"
            if [ -f "$localOverload" ]; then 
                source "$localOverload" || loadDependencyError "<local>/polylocal/dependencies/$(basename "$path")"
            fi

            # Check required fields
            if [ "$type" == "undefined" ]; then
                1>&2 echo "Error: dependency sheet $projectDir/dependencies/$path did not assign an 'type' field!"
                return 1
            fi
            if [ "$id" == "undefined" ]; then
                1>&2 echo "Error: dependency sheet $projectDir/dependencies/$path did not assign an 'id' field!"
                return 1
            fi
            if [ "$output" == "undefined" ]; then
                1>&2 echo "Error: dependency sheet $projectDir/dependencies/$path did not assign an 'output' field!"
                return 1
            fi
            depOutput="$output"
            
            # Clean
            cleanDependencyEnvironment "$path"

            # Check output
            local path="$projectRealDir/$depOutput"
            if [ -d "$path" ] && ([ -f "$path/polyfile.pcb" ] || [ -f "$path/Polyfile.pcb" ]); then
                # Prepare paths
                local pathName="$(basename "$path")"
                local currentId=$id
                local pathpretty="$projectDir/dependencies/$pathName"
                local fullpath="$(readlink -f "$path")"

                # Get current base
                local baseProject="$BASEPROJECT"
                local baseProjectId="$BASEPROJECTID"
                local baseProjectVersion="$BASEPROJECTVERSION"
                local baseProjectGroup="$BASEPROJECTGROUP"
                local baseBuild="$BASEBUILDDIR"

                # Unset, dependencies each are treated as a base
                BASEPROJECT=undefined
                BASEPROJECTID=undefined
                BASEBUILDDIR=undefined
                BASEPROJECTVERSION=undefined
                BASEPROJECTGROUP=undefined
                
                # Try loading it
                name="dependency $pathName"
                if ! loadProject "$pathpretty" "$fullpath" "dependency $pathName" "" "$forceReload" "$logPrefix" ; then
                    1>&2 echo "Error: error loading project: $projectName ($id, $projectDir): dependency \"$pathName\" could not be loaded"
                    return 1
                fi
                BASEPROJECT="$baseProject"
                BASEPROJECTID="$baseProjectId"
                BASEBUILDDIR="$baseBuild"
                BASEPROJECTVERSION="$baseProjectVersion"
                BASEPROJECTGROUP="$baseProjectGroup"

                # Loaded successfully
                # Add project to list
                eval "dependencies_$setId"'+=("'"$id"'")'
            fi
        fi
    done

    # Restore properties
    LOCALPROPERTIES=()

    # Check base
    if [ "$BASEPROJECTID" != "undefined" ]; then
        # Inherit from base
        local baseSetId="${projectsSetIds["$BASEPROJECTID"]}"
        eval 'LOCALPROPERTIES=("${locals_'"$baseSetId"'[@]}")'
    fi

    # Restore env
    preparePolyFileEnvironment
    name="$(basename "$projectRealDir")"
    if [ -f "$projectRealDir/polyfile.pcb" ]; then
        source "$projectRealDir/polyfile.pcb"
    elif [ -f "$projectRealDir/Polyfile.pcb" ]; then
        source "$projectRealDir/Polyfile.pcb"
    fi
    if [ -f "$projectRealDir/polylocal/polyfile.pcb" ]; then
        source "$projectRealDir/polylocal/polyfile.pcb"
    elif [ -f "$projectRealDir/polylocal/Polyfile.pcb" ]; then
        source "$projectRealDir/polylocal/Polyfile.pcb"
    fi
    if [ "$name" != "$(basename "$projectRealDir")" ]; then
        projectName="$name"
    fi
    LOCALPROJECTID="$id"
    LOCALPROJECT="$projectRealDir"
    LOCALPROJECTVERSION="$version"
    LOCALPROJECTGROUP="$group"
    BUILDDIR="$projectRealDir/build"

    # Load sub projects
    for path in "${subProjectPaths[@]}"; do
        # Check existence
        local fullpath="$projectRealDir/$path"
        if [ -d "$fullpath" ]; then
            # Found sub-project folder
            local currentId=$id
            local pathpretty="$projectDir/$path"
            local fullpath="$(readlink -f "$fullpath")"
            
            # Try loading it
            name="subproject $path"
            if ! loadProject "$pathpretty" "$fullpath" "subproject $path" "" "$forceReload" "$logPrefix" ; then
                1>&2 echo "Error: error loading project: $projectName ($id, $projectDir): sub-project \"$path\" could not be loaded"
                return 1
            fi

            # Loaded successfully
            # Add project to list
            eval "subprojects_$setId"'+=("'"$id"'")'
        else
            # Cant find the project
            1>&2 echo "Error: error loading project: $projectName ($id, $projectDir): sub-project path \"$path\" could not be found"
            return 1
        fi
    done
    
    # Restore properties
    LOCALPROPERTIES=()

    # Check base
    if [ "$BASEPROJECTID" != "undefined" ]; then
        # Inherit from base
        local baseSetId="${projectsSetIds["$BASEPROJECTID"]}"
        eval 'LOCALPROPERTIES=("${locals_'"$baseSetId"'[@]}")'
    fi
    
    # Restore env
    preparePolyFileEnvironment
    name="$(basename "$projectRealDir")"
    if [ -f "$projectRealDir/polyfile.pcb" ]; then
        source "$projectRealDir/polyfile.pcb"
    elif [ -f "$projectRealDir/Polyfile.pcb" ]; then
        source "$projectRealDir/Polyfile.pcb"
    fi
    if [ -f "$projectRealDir/polylocal/polyfile.pcb" ]; then
        source "$projectRealDir/polylocal/polyfile.pcb"
    elif [ -f "$projectRealDir/polylocal/Polyfile.pcb" ]; then
        source "$projectRealDir/polylocal/Polyfile.pcb"
    fi
    if [ "$name" != "$(basename "$projectRealDir")" ]; then
        projectName="$name"
    fi
    LOCALPROJECTID="$id"
    LOCALPROJECT="$projectRealDir"
    LOCALPROJECTVERSION="$version"
    LOCALPROJECTGROUP="$group"
    BUILDDIR="$projectRealDir/build"

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

    # Get cwd
    local currentCwd="$PWD"

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

    # Go to target cwd
    cd "$projectPath"

    # Get project properties
    local baseForProject="${projectsBaseProject["$project"]}"
    local baseIdForProject="${projectsBaseProjectIds["$project"]}"
    local baseBuildForProject="${projectsBaseProject["$project"]}/build"
    local currentBaseProject="$BASEPROJECT"
    local currentBaseBuild="$BASEBUILDDIR"
    local currentBaseId="$BASEPROJECTID"
    local currentBaseVersion="$BASEPROJECTVERSION"
    local currentBaseGroup="$BASEPROJECTGROUP"
    local currentProjectId="$LOCALPROJECTID"
    local currentProjectBuild="$BUILDDIR"
    local currentProject="$LOCALPROJECT"
    local currentLocalProperties=("${LOCALPROPERTIES[@]}")
    local setId="${projectsSetIds["$project"]}"

    # Update
    BASEPROJECT="$baseForProject"
    BASEBUILDDIR="$baseBuildForProject"
    BASEPROJECTID="$baseIdForProject"
    BASEPROJECTVERSION="${projectsVersions["$BASEPROJECTID"]}"
    BASEPROJECTGROUP="${projectsGroups["$BASEPROJECTID"]}"
    LOCALPROJECTID="$project"
    LOCALPROJECTVERSION="${projectsVersions["$project"]}"
    LOCALPROJECTGROUP="${projectsGroups["$project"]}"
    BUILDDIR="$projectPath/build"
    LOCALPROJECT="$projectPath"
    eval 'LOCALPROPERTIES=("${locals_'"$setId"'[@]}")'

    # Call
    runFunctionSafe "$function" "${functionParams[@]}"
    local exit=$?
    
    # Restore
    BASEPROJECT="$currentBaseProject"
    BASEBUILDDIR="$currentBaseBuild"
    BASEPROJECTID="$currentBaseId"
    BASEPROJECTVERSION="$currentBaseVersion"
    BASEPROJECTGROUP="$currentBaseGroup"
    LOCALPROJECTID="$currentProjectId"
    LOCALPROJECTVERSION="$currentProjectVersion"
    LOCALPROJECTGROUP="$currentProjectGroup"
    BUILDDIR="$currentProjectBuild"
    LOCALPROJECT="$currentProject"
    LOCALPROPERTIES=("${currentLocalProperties[@]}")

    # Return cwd
    cd "$currentCwd"

    # Return
    return $exit
}
