#!/bin/bash

function loadDependencyError() {
    1>&2 echo "Error: could not load dependency \"$1\": an error occurred while evaluating the dependency sheet"
    exit 1
}

function depTypeLoadError() {
    1>&2 echo "Error: could not load dependency type \"$1\": an error occurred while evaluating the deptype file"
    exit 1
}
