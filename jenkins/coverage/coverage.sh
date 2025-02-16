#!/bin/bash
set -x
set -e
./test/regression
mkdir -p coverage-output
lcov --capture --directory ./build --exclude '/usr/include/*' --exclude '/opt/*' --exclude '/usr/lib/*' --exclude '/usr/local/*' --exclude '*build*' --output-file ./coverage-output/main_coverage.info
genhtml ./coverage-output/main_coverage.info --output-directory ./coverage-output --ignore-errors source
