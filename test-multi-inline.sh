#!/bin/sh
#

if [ -n "$1" ] ; then
    if [ "$1" = "-h" ] ; then
        echo "Usage: test-multi-inline.sh [options]"
        echo " -h  Show this usage help"
        echo ""
        echo "By default (with no arguments), test.sh will run 1 tests on"
        echo "the board 'bbb' (using the ttc command) using the default"
        echo "python interpreter"
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
SECONDS=200

# use ttc to reboot my beaglebone black
echo "==================================="
echo "Testing with python 2"
echo "  $SECONDS second grab, with multiple inline patterns"
echo "==================================="

# do the reboot after grabserial is started
(sleep 1 ; ttc reboot bbb) &

./grabserial  -v -S -d ${console_dev} -e $SECONDS -t -o graboutput.log \
    -i "autoboot" \
    -i "Mounted /data" \
    -i "BeagleBoard.org" \
    -i "Starting kernel" \
    -i "missing-string"

echo "Done in test-one-testcase.sh"
