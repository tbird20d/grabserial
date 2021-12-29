#!/bin/sh
#
# test-one-testcase.sh - grab bootup messages for 'bbb' with grabserial
#
# Do the scafolding for executing a single boot test on the 'bbb' board
# with grabserial.
# Uncomment the 'args' option below for the thing you want to test
#
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

echo "Running grabserial on target 'bbb'"

# get the console device for target 'bbb'
console_dev="$(ttc info bbb -n console_dev)"

# Also, use ttc to reboot bbb

# use ttc to reboot my beaglebone black
echo "==================================="
echo "Testing with python 2"
echo "  120 second grab, with hex output"
echo "==================================="

# do the reboot after grabserial is started
(sleep 1 ; ttc reboot bbb) &

# test hex-output
#args="-e 120 -t --hex-output -o graboutput.log"

# try different time encodings (with deltas)
#args="-e 120 -t -o graboutput.log"
#args="-e 120 -T -o graboutput.log"

# try different time encodings (without deltas)
#args="-e 120 -t --nodelta -o graboutput.log"
args="-e 120 -T --nodelta -o graboutput.log"

./grabserial  -v -S -d ${console_dev} ${args}

echo "Done in test-one-testcase.sh"
