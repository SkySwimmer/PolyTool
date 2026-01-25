#!/bin/bash
TASKS_FOUND=()
TASKS_PERMITTING_MULTIRUN=()
TASKSBEINGRUN_PREPARE=()
TASKSBEINGRUN_RUN=()
TASKSBEINGRUN_FINISH=()

CALLINGTASKSLIST=()
TASKS_RUNTIME_SHARED=()

function taskLoadError() {
    1>&2 echo "Error: could not load task \"$1\": an error occurred while evaluating the task"
    exit 1
}