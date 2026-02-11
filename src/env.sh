#!/bin/bash

# Setup environment
RUNTIMEPATH="$runtimebasedir"
ROOTPROJECT=undefined
ROOTPROJECTVERSION=undefined
ROOTPROJECTGROUP=undefined
BASEPROJECT=undefined
BASEPROJECTVERSION=undefined
BASEPROJECTGROUP=undefined
LOCALPROJECT=undefined
LOCALPROJECTVERSION=undefined
LOCALPROJECTGROUP=undefined
ROOTPROJECTID=undefined
BASEPROJECTID=undefined
LOCALPROJECTID=undefined
ROOTBUILDDIR=undefined
BASEBUILDDIR=undefined
BUILDDIR=undefined

# Projects
declare -A projects=()
declare -A projectsNames=()
declare -A projectsGroups=()
declare -A projectsVersions=()
declare -A projectsBaseProject=()
declare -A projectsDirFriendly=()
declare -A projectsByDir=()
declare -A projectsByGroupAndId=()
declare -A projectsSetIds=()
declare -A projectsBaseProjectIds=()
declare -A projectsTasksFolders=()
declare -A projectsDependenciesFolders=()
declare -A projectsPolyLocalFolders=()
declare setIds=()

# Properties
declare -A GLOBALPROPERTIES=() # Across projects
declare -A LOCALPROPERTIES=() # Specific to projects
declare -A PROPERTIES=() # Specific to tasks (inherits LOCALPROPERTIES)
declare -A PARAMETERS=() # Specific to tasks, parameters are arguments passed to tasks

# Functionality
declare -A TASKS_DEPENDENCY_LIST_IDS=()
declare -A TASKMEMORYREFSCANNER_KEYS=()
declare -A TASKMEMORYREFSCANNER_FILES=()
declare ANTIRECURSIONLIST=()
declare requiredCommands=()

# Task dependencies
declare PROJECTMEMORYREFSCANNER_INIT=()
declare TASKMEMORYREFSCANNER_INIT=()
declare PROJECTMEMORYREFSCANNER_POPULATE=()
declare TASKMEMORYREFSCANNER_POPULATE=()
declare PROJECTMEMORYREFSCANNER_SCANNER=()
declare TASKMEMORYREFSCANNER_SCANNER=()
