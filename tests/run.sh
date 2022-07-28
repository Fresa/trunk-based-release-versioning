#!/bin/bash
scriptPath=$(realpath "$(dirname "$0")")
exitCode=0
failed=0
succeeded=0

for testFile in $(find "$scriptPath" -name "*_tests.sh"); do
    echo
    echo "Testing $testFile"
    bash "$testFile"
    if [ "$?" -gt 0 ]; then
        echo
        echo -e "\033[1;31mFAILED\033[0m"
        exitCode=1
        ((failed=failed+1))
        failed_tests="$failed_tests$testFile\n"
    else
        ((succeeded=succeeded+1))
    fi
done

echo
if [ $exitCode -gt 0 ]; then
    echo -e "\033[1;31m$failed FAILED\033[0m"
    printf "$failed_tests"
fi
echo -e "\033[1;32m$succeeded OK\033[0m"
exit $exitCode
