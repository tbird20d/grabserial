grabserial
==========

Grabserial - python-based serial dump and timing program - good for
embedded Linux development

See http://elinux.org/Grabserial for documentation and examples.

For help with command line options, use: grabserial -h

Installation
------------
If you have the python 'serial' module, you can just place grabserial
in a directory on your path, or add the directory containing grabserial
to your path, or just invoke grabserial directly.

This should work:

    $ sudo cp grabserial /usr/local/bin
    $ grabserial

You can also install this as a python module with: 'python setup.py install'
(Some users have reported problems with this - let me know if it doesn't
work for you.)

Examples
--------

    $ grabserial -d /dev/ttyUSB0 -e 30 -t -m "^Linux version.*"

Grab serial input for 30 seconds (-e 30), displaying the time for each
line (-t), and re-setting the base time when the line starting with
"Linux version" is seen.

    $ grabserial -d COM4 -T -b 115200 -e 3600 -Q -o "%" -a

Log serial data from COM4, with system timestamp (-T)
with settings 115200:8N1:xonxoff=0:rtscts=0 (-b 115200)
to the output file "2017-06-13T22:45:08" (-o "%"), for 1 hour (-e 3600)
and then restart (-a) to create new log.

    $ 'grabserial -d /dev/ttyUSB2 -C -q "nsh>" -c free

Send the 'free' command to the serial port (-c free), and show output
until a prompt of "nsh>" is seen (-q "nsh>"). Suppress the command echo
and shell prompt (-C).

Notice - New Default ‘-o’ Behavior
----------------------------------
Using the '-o' option, as in the second example above, with a generic '%'
or a specific pattern that includes a '%d' (date) reference will now close
the output file and open a new one if the system date changes while the
program is running.

If the command from the second example above is started at 11:30pm (system
time), the program will capture data for one hour but **will produce two
output files**; one with the date and time it was started and another with
the date and time that the program first outputs data after the system
time passes midnight.

