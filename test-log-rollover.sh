#!/bin/sh
#
# For pylint-related info, see:
#    https://jeffknupp.com/blog/2016/12/09/how-python-linters-will-save-your-large-python-project/

if [ -n "$1" ] ; then
    if [ "$1" = "-h" ] ; then
        echo "Usage: test.sh [options]"
        echo " -h  Show this usage help"
        echo ""
        echo "test-log-rollover.sh will run grabserial on a boot of"
        echo "the board 'bbb' (using the ttc command), rolling over the log"
        echo "at 10-second intervals"
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
echo "  10 second grab, doing a restart into a new log every time"
echo "   ending when "login" is seen"
echo "==================================="

# do the reboot after grabserial is started
(sleep 1 ; ttc reboot bbb) &

# grab data from from that console device (-d ${console_dev},
#    skipping the serial port sanity check (-S)
# show verbose messages (-v)
# rotate ever 10 seconds (-R 10)
# use timestamps per line (-t)
# quit when "login" is seen (-q "login")
# send data to <timestamp>.log (-o "...")
./grabserial  -v -S -d ${console_dev} -R 10 -t -q "login" -o "%Y-%m-%dT%H:%M:%S.log"

echo "Done in test-log-rollover.sh"
