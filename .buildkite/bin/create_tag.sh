#!/bin/bash

set -eu

# $1 version

git config user.email "buildkite@rokt.com"
git config user.name "Buildkite"

git commit -m "v$1"
git tag -a "v$1" -m "Automated release v$1"
git push origin "v$1"
