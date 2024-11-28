#!/bin/sh
# set -euo pipefail
cd Example
mkdir -p ./test_output/swiftlint
swiftlint lint --strict --reporter junit | tee ./test_output/swiftlint/junit.xml
