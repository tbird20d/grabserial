#!/usr/bin/python
# vim: set ts=4 sw=4 et :
#
# grabserial - program to read a serial port and send the data to stdout
#
# Copyright 2006,2016 Sony Corporation
#
# This program is provided under the Gnu General Public License (GPL)
# version 2 ONLY. This program is distributed WITHOUT ANY WARRANTY.
# See the LICENSE file, which should have accompanied this program,
# for the text of the license.
#
# 2018-01-03 by Tim Bird <tim.bird@sony.com>
# 2006-09-07 by Tim Bird
#
# To do:
#  * support interrupting capture with Ctrl-C
#    * somewhere along the line, this feature got lost
#    * (maybe check the exception handler and threading in the main loop?)
#  * buffer output chars??
#  * add optional value to -a to limit number of restarts?
#  * restart based on received bytes?
#
# CHANGELOG:
#  2018.01.03 - Version 1.9.6
#   - add patches from Ilya Kuzmich to fix python3 issues,
#   - update test.sh with python linters and other improvements
#   - fix code to remove flake8 and pylint issues
#  2017.06.13 - Version 1.9.5 - add -a to restart after time expired or
#                               pattern matched.
#                             - add strftime arguments to -o.
#                             - add -Q to silence stdout when -o is active.
#  2016.09.29 - Version 1.9.4 - add thread for sending user input to target
#    by zqb-all on github
#  2016.09.06 - clean up tabs, and add vim modeline for 4-column tabs
#               grabserial should always run with python -tt grabserial
#  2016.08.31 - add microsecond precision when using system Time (-T) option
#  2016.08.30 - Version 1.9.3 - allow forcing the baudrate with -B
#  2016.07.01 - Version 1.9.2 - change how version is stored
#  2016.05.10 - Version 1.9.1 - allow skipping the tty check with -S
#  2016.05.10 - Version 1.9.0 - support use as a python module
#    Note that the main module routine will be grabserial.grab(args,[outputfd])
#      where args is a list of command-line-style args
#      as they would be passed using the standalone program.  e.g.
#      grabserial.grab(None, ["-d", "/dev/ttyUSB0", "-v"])
#      output from the serial port (with timing data) is sent to outputfd
#  2015.04.23 - Version 1.8.1 - remove instructions for applying LICENSE text
#    to new files, and add no-warranty language to grabserial.
#  2015.03.10 - Version 1.8.0 - add -o option for saving output to a file
#    add -T option for absolute times. Both contributed by ramaxlo
#  2015.03.10 - Version 1.7.1 - add line feed to instantpat result line
#  2014.09.28 - Version 1.7.0 - add option for force reset for USB serial
#    contributed by John Mehaffey <mehaf@gedanken.com>
#  2014.01.07 - Version 1.6.0 - add option for exiting based on a
#    mid-line pattern (quitpat). Simeon Miteff <simeon.miteff@gmail.com>
#  2013.12.19 - Version 1.5.2 - verify Windows ports w/ serial.tools.list_ports
#   (thanks to Yegor Yefromov for the idea and code)
#  2013.12.16 - Version 1.5.1 - Change my e-mail address
#  2011.12.19 - Version 1.5.0 - add options for mid-line time capture
#    (instantpat) and base time from launch of program instead of
#    first char seen (launchtime) - contributed by Kent Borg
#  2011-09-24 - better time output and time delta
#    Constantine Shulyupin <const@makelinux.com>
#  2008-06-02 - Version 1.1.0 add support for sending a command to
#    the serial port before grabbing output

import os
import sys
import getopt
import serial
import time
import datetime
import re

VERSION = (1, 9, 6)

try:
    import thread
except ImportError:
    import _thread as thread

if sys.version_info > (3, 0):
    # raw input is gone in python3
    # https://www.python.org/dev/peps/pep-3111/
    raw_input = input

verbose = 0
cmdinput = ""


def vprint(message):
    if verbose:
        print(message)


def usage(rcode):
    cmd = "grabserial"

    print("""%s : Serial line reader
    Usage: %s [options]
options:
    -h, --help             Print this message
    -d, --device=<devpath> Set the device to read (default '/dev/ttyS0')
    -b, --baudrate=<val>   Set the baudrate (default 115200)
    -B <val>               Force the baudrate to the indicated value
                             (grabserial won't check if the baudrate is legal)
    -w, --width=<val>      Set the data bit width (default 8)
    -p, --parity=<val>     Set the parity (default N)
    -s, --stopbits=<val>   Set the stopbits (default 1)
    -x, --xonxoff          Enable software flow control (default off)
    -r, --rtscts           Enable RTS/CTS flow control (default off)
    -f, --force-reset      Force pyserial to reset device parameters
    -e, --endtime=<secs>   End the program after the specified seconds have
                           elapsed.
    -c, --command=<cmd>    Send a command to the port before reading
    -t, --time             Print time for each line received.  The time is
                           when the first character of each line is
                           received by %s
    -a, --again            Restart application after -e expires or -q is
                           triggered.
    -T, --systime          Print system time for each line received. The time
                           is the absolute local time when the first character
                           of each line is received by %s
    -m, --match=<pat>      Specify a regular expression pattern to match to
                           set a base time.  Time values for lines after the
                           line matching the pattern will be relative to
                           this base time.
    -i, --instantpat=<pat> Specify a regular expression pattern to have its
                           time reported at end of run.  It works mid-line.
    -q, --quitpat=<pat>    Specify a regular expression pattern to end the
                           program.  It works mid-line.
    -l, --launchtime       Set base time from launch of program.
    -o, --output=<name>    Output data to the named file.
                           Uses: %%Y-%%m-%%dT%%H:%%M:%%S on "%%".
    -Q, --quiet            Silent on stdout, serial port data is only written
                           to file, if specified.
    -v, --verbose          Show verbose runtime messages
    -V, --version          Show version number and exit
    -S, --skip             Skip sanity checking of the serial device.
                           May be needed for some devices.
        --crtonewline      Promote a carriage return to be treated as a
                           newline

Ex: %s -e 30 -t -m "^Linux version.*"
This will grab serial input for 30 seconds, displaying the time for
each line, and re-setting the base time when the line starting with
"Linux version" is seen.
""" % (cmd, cmd, cmd, cmd, cmd))
    sys.exit(rcode)


def device_exists(device):
    try:
        from serial.tools import list_ports

        for port in list_ports.comports():
            if port[0] == device:
                return True

        return False
    except serial.SerialException:
        return os.path.exists(device)


def read_input():
    global cmdinput
    while 1:
        cmdinput = raw_input()


# grab - main routine to grab a serial port and time the output of each line
# takes a list of arguments, as they would have been passed in sys.argv
# that is, a list of strings.
# also can take an optional file descriptor for where to send the data
# by default, data read from the serial port is sent to sys.stdout, but
# you can specify your own (already open) file descriptor, or None.  This
# would only make sense if you specified another outputfile with
#    "-o","myoutputfile"
def grab(arglist, outputfd=sys.stdout):
    global verbose
    global cmdinput

    # parse the command line options
    try:
        opts, args = getopt.getopt(
                        arglist,
                        "hli:d:b:B:w:p:s:xrfc:taTm:e:o:QvVq:S", [
                            "help",
                            "launchtime",
                            "instantpat=",
                            "device=",
                            "baudrate=",
                            "width=",
                            "parity=",
                            "stopbits=",
                            "xonxoff",
                            "rtscts",
                            "force-reset",
                            "command=",
                            "time",
                            "again",
                            "systime",
                            "match=",
                            "endtime=",
                            "output=",
                            "quiet",
                            "verbose",
                            "version",
                            "quitpat=",
                            "skip",
                            "crtonewline",
                        ])
    except getopt.GetoptError:
        # print help info and exit
        print("Error parsing command line options")
        usage(2)

    sd = serial.Serial()
    sd.port = ""
    sd.baudrate = 115200
    sd.bytesize = serial.EIGHTBITS
    sd.parity = serial.PARITY_NONE
    sd.stopbits = serial.STOPBITS_ONE
    sd.xonxoff = False
    sd.rtscts = False
    sd.dsrdtr = False
    # specify a read timeout of 1 second
    sd.timeout = 1
    force = False
    show_time = 0
    show_systime = 0
    basepat = ""
    instantpat = ''
    quitpat = ''
    basetime = 0
    instanttime = None
    endtime = 0
    outputfile = None
    command = ""
    skip_device_check = 0
    cr_to_nl = 0
    restart = False
    quiet = False

    for opt, arg in opts:
        if opt in ["-h", "--help"]:
            usage(0)
        if opt in ["-d", "--device"]:
            device = arg
            if not skip_device_check and not device_exists(device):
                print("""Error: serial device '%s' does not exist, aborting.
    If you think this port really exists, then try using the -S option
    to skip the serial device check. (put it before the -d argument)"""
                      % device)
                sd.close()
                usage(2)
            sd.port = device
        if opt in ["-b", "--baudrate"]:
            baud = int(arg)
            if baud not in sd.BAUDRATES:
                print("Error: invalid baud rate '%d' specified" % baud)
                print("Valid baud rates are: %s" % str(sd.BAUDRATES))
                print("You can force the baud rate using the -B option")
                sd.close()
                sys.exit(3)
            sd.baudrate = baud
        if opt == "-B":
            sd.baudrate = int(arg)
        if opt in ["-p", "--parity"]:
            par = arg.upper()
            if par not in sd.PARITIES:
                print("Error: invalid parity '%s' specified" % par)
                print("Valid parities are: %s" % str(sd.PARITIES))
                sd.close()
                sys.exit(3)
            sd.parity = par
        if opt in ["-w", "--width"]:
            width = int(arg)
            if width not in sd.BYTESIZES:
                print("Error: invalid data bit width '%d' specified" % width)
                print("Valid data bit widths are: %s" % str(sd.BYTESIZES))
                sd.close()
                sys.exit(3)
            sd.bytesize = width
        if opt in ["-s", "--stopbits"]:
            stop = int(arg)
            if stop not in sd.STOPBITS:
                print("Error: invalid stopbits '%d' specified" % stop)
                print("Valid stopbits are: %s" % str(sd.STOPBITS))
                sd.close()
                sys.exit(3)
            sd.stopbits = stop
        if opt in ["-c", "--command"]:
            command = arg
        if opt in ["-x", "--xonxoff"]:
            sd.xonxoff = True
        if opt in ["-r", "--rtscts"]:
            sd.rtscts = True
        if opt in ["-f", "--force-set"]:
            force = True
        if opt in ["-t", "--time"]:
            show_time = 1
            show_systime = 0
        if opt in ["-a", "--again"]:
            restart = True
        if opt in ["-T", "--systime"]:
            show_time = 0
            show_systime = 1
        if opt in ["-m", "--match"]:
            basepat = arg
        if opt in ["-i", "--instantpat"]:
            instantpat = arg
        if opt in ["-q", "--quitpat"]:
            quitpat = arg
        if opt in ["-l", "--launchtime"]:
            print('setting basetime to time of program launch')
            basetime = time.time()
        if opt in ["-e", "--endtime"]:
            endstr = arg
            try:
                endtime = time.time()+float(endstr)
            except ValueError:
                print("Error: invalid endtime %s specified" % arg)
                sd.close()
                sys.exit(3)
        if opt in ["-o", "--output"]:
            outputfile = arg
            if outputfile == "%":
                outputfile = "%Y-%m-%dT%H:%M:%S"
            if "%" in outputfile:
                outputfile = datetime.datetime.now().strftime(outputfile)
        if opt in ["-Q", "--quiet"]:
            quiet = True
        if opt in ["-v", "--verbose"]:
            verbose = 1
        if opt in ["-V", "--version"]:
            print("grabserial version %d.%d.%d" % VERSION)
            sd.close()
            sys.exit(0)
        if opt in ["-S"]:
            skip_device_check = 1
        if opt in ["--crtonewline"]:
            cr_to_nl = 1

    # if verbose, show what our settings are
    if sd.port:
        vprint("Opening serial port %s" % sd.port)
        vprint(
            "%d:%d%s%s:xonxoff=%d:rtscts=%d" %
            (sd.baudrate, sd.bytesize, sd.parity, sd.stopbits,
                sd.xonxoff, sd.rtscts))
    else:
        print("Error: Missing serial port to read from")
        usage(2)
    if endtime and not restart:
        vprint("Program will end in %s seconds" % endstr)
    if endtime and restart:
        vprint("Program will restart after %s seconds." % endstr)
    if show_time:
        vprint("Printing timing information for each line")
    if show_systime:
        vprint("Printing absolute timing information for each line")
    if basepat:
        vprint("Matching pattern '%s' to set base time" % basepat)
    if instantpat:
        vprint("Instant pattern '%s' to set base time" % instantpat)
    if quitpat:
        vprint("Instant pattern '%s' to exit program" % quitpat)
    if skip_device_check:
        vprint("Skipping check of serial device")
    if outputfile:
        try:
            out = open(outputfile, "w")
        except IOError:
            print("Can't open output file '%s'" % outputfile)
            sys.exit(1)
        vprint("Saving data to '%s'" % outputfile)
    if quiet:
        vprint("Keeping quiet on stdout")

    prev1 = 0
    linetime = 0
    newline = 1
    curline = ""
    vprint("Use Control-C to stop...")

    # pyserial does not reconfigure the device if the settings
    # don't change from the previous ones.  This causes issues
    # with (at least) some USB serial converters
    # Allow user to force device reconfiguration
    if force:
        toggle = sd.xonxoff
        sd.xonxoff = not toggle
        sd.open()
        sd.close()
        sd.xonxoff = toggle
    sd.open()
    sd.flushInput()
    sd.flushOutput()

    if command:
        sd.write(command + "\n")
        sd.flush()

    # capture stdin to send to serial port
    try:
        thread.start_new_thread(read_input, ())
    except thread.error:
        print("Error starting thread for read input\n")

    # read from the serial port until something stops the program
    while 1:
        try:
            if cmdinput:
                sd.write(cmdinput + "\n")
                cmdinput = ""

            # read for up to 1 second
            x = sd.read(1).decode(sys.stdout.encoding)

            # see if we're supposed to stop yet
            if endtime and time.time() > endtime:
                if restart:
                    vprint(
                        "Restarting %s\n" %
                        datetime.datetime.now().strftime("%H:%M:%S.%f"))
                    if outputfile:
                        out.close()
                    sd.close()
                    os.execv(sys.executable, ['python'] + sys.argv)
                break

            # if we didn't read anything, loop
            if len(x) == 0:
                continue

            # convert carriage returns to newlines.
            if x == "\r":
                if cr_to_nl:
                    x = "\n"
                else:
                    continue

            # set basetime to when first char is received
            if not basetime:
                basetime = time.time()

            if show_time and newline:
                linetime = time.time()
                elapsed = linetime-basetime
                delta = elapsed-prev1
                msg = "[%4.6f %2.6f] " % (elapsed, delta)
                if not quiet:
                    if outputfd:
                        outputfd.write(msg)
                if outputfile:
                    out.write(msg)
                prev1 = elapsed
                newline = 0

            if show_systime and newline:
                linetime = time.time()
                linetimestr = datetime.datetime.now().strftime("%H:%M:%S.%f")
                elapsed = linetime-basetime
                delta = elapsed-prev1
                msg = "[%s %2.6f] " % (linetimestr, delta)
                if not quiet:
                    sys.stdout.write(msg)
                if outputfile:
                    out.write(msg)
                prev1 = elapsed
                newline = 0

            # FIXTHIS - should I buffer the output here??
            if not quiet:
                sys.stdout.write(x)
            if outputfile:
                out.write(x)
            curline += x

            # watch for patterns
            if instantpat and not instanttime and \
                    re.search(instantpat, curline):
                # instantpat is in curline:
                instanttime = time.time()

            # Exit the loop if quitpat matches
            if quitpat and re.search(quitpat, curline):
                if restart:
                    vprint(
                        "Restarting %s\n" %
                        datetime.datetime.now().strftime("%H:%M:%S.%f"))
                    if outputfile:
                        out.close()
                    sd.close()
                    os.execv(sys.executable, ['python'] + sys.argv)
                break

            if x == "\n":
                newline = 1
                if basepat and re.match(basepat, curline):
                    basetime = linetime
                    elapsed = 0
                    prev1 = 0
                curline = ""
            sys.stdout.flush()
            if outputfile:
                out.flush()
        # FIXTHIS - maybe add 'except KeyboardInterrupt' here
        except EnvironmentError:
            break

    sd.close()
    if instanttime:
        instanttime_str = '%4.6f' % (instanttime-basetime)
        msg = '\nThe instantpat: "%s" was matched at %s\n' % \
            (instantpat, instanttime_str)
        if not quiet:
            sys.stdout.write(msg)
            sys.stdout.flush()
        if outputfile:
            out.write(msg)
            out.flush()

    if outputfile:
        out.close()


if __name__ == "__main__":
    grab(sys.argv[1:])

# emacs custom variables for using tabs
# indent-tabs-mode: nil
# tab-width: 4
