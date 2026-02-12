#!/bin/bash

function preparePolyFileEnvironment() {
    id="undefined"
    version="undefined"
    group="undefined"
    name="undefined"
    tasksdir="tasks"
    dependenciesdir="dependencies"
    localoverloadsdir="polylocal"
    builddir="build"
    dependencyProjectPaths=()
    subProjectPaths=()
}

function runLocalToProject() {
    local args=("$@")

    # Get cwd
    local currentId="$id"
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
    local baseBuildForProject="${projectsBaseProjectBuildDirs["$project"]}"
    local buildForProject="${projectsBuildDirs["$project"]}"
    local currentBaseProject="$BASEPROJECT"
    local currentBaseBuild="$BASEBUILDDIR"
    local currentBaseId="$BASEPROJECTID"
    local currentBaseVersion="$BASEPROJECTVERSION"
    local currentBaseGroup="$BASEPROJECTGROUP"
    local currentProjectId="$LOCALPROJECTID"
    local currentProjectBuild="$BUILDDIR"
    local currentProject="$LOCALPROJECT"
    local currentDependencyProjectPaths=("${dependencyProjectPaths[@]}")
    local currentSubProjectPaths=("${subProjectPaths[@]}")
    declare -A currentLocalProperties=()
    copyAssociativeArray LOCALPROPERTIES currentLocalProperties
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
    BUILDDIR="$buildForProject"
    LOCALPROJECT="$projectPath"
    eval 'dependencyProjectPaths=("${'defineddependencies_"$setId"'[@]}")'
    eval 'subProjectPaths=("${'definedsubprojects"$setId"'[@]}")'
    LOCALPROPERTIES=()
    copyAssociativeArray "locals_$setId" LOCALPROPERTIES

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
    dependencyProjectPaths=("${currentDependencyProjectPaths[@]}")
    subProjectPaths=("${currentSubProjectPaths[@]}")
    LOCALPROPERTIES=()
    copyAssociativeArray currentLocalProperties LOCALPROPERTIES
    id="$currentId"

    # Return cwd
    cd "$currentCwd"

    # Return
    return $exit
}
