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

declare setIds=()

declare requiredCommands=()

declare PROPERTIES=()
declare GLOBALPROPERTIES=()
declare LOCALPROPERTIES=()
