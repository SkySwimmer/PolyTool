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
declare -A projectsBaseProjectBuildDirs=()
declare -A projectsBuildDirs=()
declare -A projectsTasksFolders=()
declare -A projectsDependenciesFolders=()
declare -A projectsPolyLocalFolders=()
declare setIds=()

# Properties
declare -A GLOBALPROPERTIES=() # Across projects
declare -A LOCALPROPERTIES=() # Specific to projects
declare -A PROPERTIES=() # Specific to tasks (inherits LOCALPROPERTIES and inherited by child tasks, but do not exist across other tasks)
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

# Task data
declare -Ag PROJECTS_TASKS_LISTS=()
declare -A PROJECTS_TASKS_NAMES=()
declare -A PROJECTS_TASKS_PROJECTID=()
declare -A PROJECTS_TASKS_PROJECTDIR=()
declare -A PROJECTS_TASKS_ISPROJECT=()
declare -A PROJECTS_TASKS_PROJECTINSTS=()

# Task syntax
declare -A AVAILABLE_TASKS=()
declare AVAILABLE_TASKS_LIST=()
declare -A TASKS_FILES=()
declare -A TASKS_KEYS=()
declare -A TASKS_SYNTAX=()
declare -A TASKS_DESCRIPTIONSHORT=()
declare -A TASKS_DESCRIPTIONFULL=()
declare -A TASKS_PARAMETERLISTS=()
declare -A TASKS_HELPSHEETLISTS=()

# Parameter syntax
declare -A PARAMETERS_NAME=()
declare -A PARAMETERS_REQUIRED=()
declare -A PARAMETERS_SYNTAX=()
declare -A PARAMETERS_DESCRIPTIONSHORT=()
declare -A PARAMETERS_DESCRIPTIONFULL=()

# Task parser control
declare TASKS_OWNPARSEREQUIRED=()
declare -A PARAMETERS_REQUIRE_VALUE=()

# Help sheets
declare -A TASKS_HELPSHEETS_KEYWORDS=()
