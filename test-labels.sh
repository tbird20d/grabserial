#!/bin/sh
#
# test-labels.sh - grab bootup messages for 'bbb' with grabserial
#  apply the target name as a label to each message line
#
# Do the scafolding for executing a single boot test on the 'bbb' board
# with grabserial.
# Uncomment the 'args' option below for the thing you want to test
#
TARGET=bbb

if [ -n "$1" ] ; then
    if [ "$1" = "-h" ] ; then
        echo "Usage: test-one-testcase.sh [options]"
        echo " -h  Show this usage help"
        echo ""
        echo "By default (with no arguments), test.sh will run 1 tests on"
        echo "the board 'bbb' (using the ttc command) using the default"
        echo "python interpreter"
        echo ""
        echo "Specify the 'args' you want for the test you want to perform,"
        echo "by editing this file (uncommenting the desired options)."
        exit 0
    fi
fi

if [ -n "$1" ] ; then
    echo "Unrecognized option '$1'"
    echo "Use -h for help"
    exit 0
fi

echo "Running grabserial on target '$TARGET'"

# get the console device for target
console_dev="$(ttc info $TARGET -n console_dev)"

# Also, use ttc to reboot target

# use ttc to reboot the target
echo "==================================="
echo "Testing with python 2"
echo "  120 second grab, with hex output"
echo "==================================="

# do the reboot after grabserial is started
(sleep 1 ; ttc reboot $TARGET) &

args="-e 60 -T --nodelta --label=bbb -o graboutput.log"

./grabserial  -v -S -d ${console_dev} ${args}

echo "Done in test-labels.sh"
