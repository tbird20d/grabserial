#!/bin/sh
#
# For pylint-related info, see:
#    https://jeffknupp.com/blog/2016/12/09/how-python-linters-will-save-your-large-python-project/

if [ -n "$1" ] ; then
    if [ "$1" = "-h" ] ; then
        echo "Usage: test.sh [options]"
        echo " -h  Show this usage help"
        echo " -f  Do 'flake8' test of grabserial syntax"
        echo " -l  Do 'pylint' test of grabserial source"
        exit 0
    fi
    if [ "$1" = "-f" ] ; then
        echo "Running flake8 to analyze grabserial source"
        flake8 --count grabserial
        exit $?
    fi
    if [ "$1" = "-l" ] ; then
        echo "Running pylint to analyze grabserial source"
        # C0325 is unnecessary-parens (in python 2.0, parens for prints
        # is encouraged to make them forward-compatible with python 3.0
        pylint --disable=C0325 grabserial
        exit $?
    fi
fi

if [ -n "$1" ] ; then
    echo "Unrecognized option '$1'"
    echo "Use -h for help"
    exit 0
fi

echo "Running grabserial on target 'bbb'"
# Here's a runtime test:

# get the console device for target 'bbb'
console_dev="$(ttc info bbb -n console_dev)"


# grab data from from that console device (-d ${console_dev},
#    skipping the serial port sanity check (-S)
# end either in 30 seconds (-e 30) or when "login" is seen (-q "login")
# report the time when "done" was seen (-i "done")
# send data to graboutput.log (-o graboutput.log)
# reset the running timer when the string "Starting kernel" is seen (-m ...)
# show verbose messages (-v)

# Also, use ttc to reboot bbb

# use ttc to reboot my beaglebone black
echo "Testing with python 2"
./grabserial  -v -S -d ${console_dev} -e 30 -t -m "Starting kernel" -i "done," -q "login" -o graboutput.log & ttc reboot bbb

echo "Testing with ptyhon 3"
python3 ./grabserial  -v -S -d ${console_dev} -e 30 -t -m "Starting kernel" -i "done," -q "login" -o graboutput.log & ttc reboot bbb

echo "Sleeping in test.sh"
sleep 31

# Note: this calling sequence give an error:
#   Unhandled exception in thread started by <function read_input at 0x7fb745dc5e60>
#   Traceback (most recent call last):
#   File "./grabserial", line 143, in read_input
#      cmdinput = raw_input()
#   EOFError: EOF when reading a line
# It has something to do with stdin closing.  I don't get the error if
# I run grabserial from the command line.

