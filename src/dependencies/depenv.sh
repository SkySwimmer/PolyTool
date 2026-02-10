#!/bin/bash

function setupDependencyEnvironment() {
    # Parse command
    local depFile="$1"

    # Defaults
    id=undefined
    group=undefined
    version=undefined
    name=undefined
    output=undefined
    type=undefined
    baseproject=dependency
}

function cleanDependencyEnvironment() {
    # Parse command
    local depFile="$1"

    # Defaults
    id=undefined
    group=undefined
    version=undefined
    name=undefined
    output=undefined
    type=undefined
    baseproject=undefined
}

