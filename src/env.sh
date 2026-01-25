#!/bin/bash

# Setup environment
RUNTIMEPATH="$runtimebasedir"
ROOTPROJECT=undefined
BASEPROJECT=undefined
LOCALPROJECT=undefined
ROOTPROJECTID=undefined
BASEPROJECTID=undefined
LOCALPROJECTID=undefined
ROOTBUILDDIR=undefined
BASEBUILDDIR=undefined
BUILDDIR=undefined

declare -A projects=()
declare -A projectsBaseProject=()
declare -A projectsNames=()
declare -A projectsDirFriendly=()
declare -A projectsByDir=()
declare -A projectsByGroupAndId=()
declare -A projectsSetIds=()
declare -A projectsBaseProjectIds=()

declare setIds=()

declare requiredCommands=()

declare PROPERTIES=()
declare GLOBALPROPERTIES=()
declare LOCALPROPERTIES=()
