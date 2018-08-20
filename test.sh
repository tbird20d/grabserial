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

# get the console device for target 'bbb'
console_dev="$(ttc info bbb -n console_dev)"


# Also, use ttc to reboot bbb

# use ttc to reboot my beaglebone black
echo "Testing with python 2"
echo "  60 second grab, stopping when 'login' is seen"

# do the reboot after grabserial is started
(sleep 1 ; ttc reboot bbb) &

# grab data from from that console device (-d ${console_dev},
#    skipping the serial port sanity check (-S)
# end either in 60 seconds (-e 60) or when "login" is seen (-q "login")
# report the time when "FAQ" was seen (-i "FAQ")
# send data to graboutput.log (-o graboutput.log)
# reset the running timer when the string "Starting kernel" is seen (-m ...)
# show verbose messages (-v)
./grabserial  -v -S -d ${console_dev} -e 60 -t -m "Starting kernel" -i "FAQ" -q "login" -o graboutput.log

echo

echo "  120 second grab, try logging in (test user input to serial port)"
(sleep 1 ; ttc reboot bbb) &

# run for two minutes, allowing user to login (using threaded input)
./grabserial  -v -S -d ${console_dev} -e 120 -t -o graboutput2.log

echo 

echo "Testing with python 3"
echo "  60 second grab, stopping when 'login' is seen"
(sleep 1 ; ttc reboot bbb) &

python3 ./grabserial  -v -S -d ${console_dev} -e 60 -t -m "Starting kernel" -i "FAQ" -q "login" -o graboutput3.log

echo

echo "  120 second grab, try logging in (test user input to serial port)"
(sleep 1 ; ttc reboot bbb) &
python3 ./grabserial  -v -S -d ${console_dev} -e 120 -t -o graboutput4.log

echo 

echo "Done in test.sh"
