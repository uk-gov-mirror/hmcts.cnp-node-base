#!/usr/bin/env bash
#
# Run a test build for a given image.
# 
# Sample usage:
# 
# $ ./test-build.sh <image tag> <image version>
#

set -euo pipefail

info() {
  printf "%s\\n" "$@"
}

fatal() {
  printf "/!\ Fatal Error: %s\\n" "$@"
  exit 1
}

removeTrailingspaces () {
    sed -e 's/[[:space:]]*$//' "$@"
}

tag=${1}
version=${2-latest}

info "Testing ${tag}:${version}"

testUser() {
    local hmctsUser
    local whoami

    hmctsUser="hmcts"
    expectedId="uid=1000(hmcts) gid=1000(hmcts) groups=1000(hmcts)"
    whoami=$(echo `docker run --rm ${tag}:${version} id` | removeTrailingspaces)

    if [[ "$whoami" == *"$expectedId"* ]]; then
        info "OK User $hmctsUser as expected"
    else
        fatal "User $hmctsUser not as expected: $whoami | should be $expectedId"
    fi
}

testWorkdir() {
    local defaultWorkdir
    local workDir

    defaultWorkdir="/opt"
    workDir=$(echo `docker run --rm ${tag}:${version} pwd` | removeTrailingspaces)

    if [[ "$workDir" != "$defaultWorkdir" ]]; then
        fatal "Workdir is not $defaultWorkdir. Workdir found: $workDir"
    else
        info "OK Workdir is $defaultWorkdir"
    fi
}

testDefaultCmd() {
    local defaultCmd
    local cmd

    defaultCmd="[\"yarn\",\"start\"]"
    cmd=$(echo `docker inspect --format='{{json .Config.Cmd}}' ${tag}:${version}`)
    
    if [[ "$cmd" != "$defaultCmd" ]]; then
        fatal "Default CMD is not $defaultCmd. Default CMD found: $cmd"
    else
        info "OK Default CMD is $defaultCmd"
    fi
}

testUser
testWorkdir
testDefaultCmd
