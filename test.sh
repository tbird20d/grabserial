#!/bin/sh

# Here's a test:
# grab data from /dev/ttyACM1 (-d /dev/ttyACM1)
# end either in 30 seconds (-e 30) or when "done" is seen (-q "done")
# report the time when "done" was seen (-i "done")
# send data to graboutput.log (-o graboutput.log)
# reset the running timer when the string "Starting kernel" is seen (-m ...)
# show verbose messages (-v)

# use ttc to reboot my beaglebone black

./grabserial  -v -d /dev/ttyACM1 -e 30 -t -m "Starting kernel" -i "done," -q "done" -o graboutput.log & ttc reboot bbb

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

