#!/bin/sh
#
# test-output-filenames.sh
#

BOARD=bbb
DIR_ONLY=

if [ -n "$1" ] ; then
    if [ "$1" = "-h" ] ; then
        echo "Usage: test-output-filenames.sh [options]"
        echo " -h          Show this usage help"
        echo " -b <board>  Perform test using specified board."
        echo "             (Defaults to 'bbb')"
        echo " -d          Run just the directory name test"
        echo ""
        echo "Test different output filenames"
        echo ""
        exit 0
    fi
    if [ "$1" = "-b" ] ; then
        shift
        BOARD=$1
        shift
    fi
    if [ "$1" = "-d" ] ; then
        shift
        DIR_ONLY=1
    fi
fi

if [ -n "$1" ] ; then
    echo "Unrecognized option '$1'"
    echo "Use -h for help"
    exit 0
fi

echo "Running grabserial on target '$BOARD'"

# get the console device for target board
console_dev="$(ttc info $BOARD -n console_dev)"

ls -ltr | grep -v total | grep -v dir_list >dir_list_before.txt

# Also, use ttc to reboot board

# use ttc to reboot my beaglebone black
if [ -z "$DIR_ONLY" ] ; then
echo "==================================="
echo "Testing with python 2"
echo "  60 second grab, stopping when 'Starting kernel' is seen"
echo "  using filename '%'"
echo "==================================="

# do the reboot after grabserial is started
(sleep 1 ; ttc reboot $BOARD) &

# grab data from from that console device (-d ${console_dev},
#    skipping the serial port sanity check (-S)
# end either in 60 seconds (-e 60) or when "Starting kernel" is seen
# (-q "Starting kernel")
# send data to graboutput.log (-o {filename})  (filename=%)
# show verbose messages (-v)
./grabserial  -v -S -d ${console_dev} -e 60 -t -q "Starting kernel" \
    -o %

echo "==== Done with grabserial capture ===="
echo

echo "==================================="
echo "Testing with python 2"
echo "  60 second grab, stopping when 'Starting kernel' is seen"
echo "  using filename '%s.log'"
echo "==================================="

(sleep 1 ; ttc reboot $BOARD) &
./grabserial  -v -S -d ${console_dev} -e 60 -t -q "Starting kernel" \
    -o %s.log

echo "==== Done with grabserial capture ===="
echo

echo "==================================="
echo "Testing with python 2"
echo "  60 second grab, stopping when 'Starting kernel' is seen"
echo "  using filename 'mylog-%F_%T.log'"
echo "==================================="

(sleep 1 ; ttc reboot $BOARD) &
./grabserial  -v -S -d ${console_dev} -e 60 -t -q "Starting kernel" \
    -o mylog-%F_%T.log

echo "==== Done with grabserial capture ===="
echo

echo "==================================="
echo "Testing with python 2"
echo "  120 second grab"
echo "  using filename '/tmp/%'", with 20-second log rotations
echo "==================================="

(sleep 1 ; ttc reboot $BOARD) &
./grabserial  -v -S -d ${console_dev} -e 120 -t  -R 20s \
    -o "/tmp/%"

echo "==== Done with grabserial capture ===="
echo

fi
# end of "if [ -z $DIR_ONLY...

echo "==================================="
echo "Testing with python 2"
echo "  60 second grab, stopping when 'Starting kernel' is seen"
echo "  using filepath '/tmp/%YYYY/%mm/%dd/mylog-%T.log'"
echo "==================================="

(sleep 1 ; ttc reboot $BOARD) &
./grabserial  -v -S -d ${console_dev} -e 60 -t -q "Starting kernel" \
    -o "/tmp/%Y/%m/%d/mylog-%T.log"

echo "==== Done with grabserial capture ===="
echo

echo "Checking for output filenames"
echo
ls -ltr | grep -v total | grep -v dir_list >dir_list_after.txt

echo "New files:"
diff -u -B0 dir_list_before.txt dir_list_after.txt | \
    grep -v dir_list | grep -v @@

rm dir_list_before.txt dir_list_after.txt

echo
echo "Should have 3 new files, with names like:"
echo "2020-12-02_22:10:06"
echo "1606971316.log"
echo "mylog-2020-12-02_22:10:25.log"
echo

ls -ltr /tmp | tail -n 2 | grep -v total

#ls -ltr /tmp/2023/07/26

echo

echo "Should have 1 new file in /tmp, with a name like:"
echo "2020-12-02_22:12:07"

echo "Should have 1 new file in /tmp/{YYYY}/{mm}/{dd}, like:"
echo "2023/12/02/mylog_22:12:07.log"

echo "Done in test-output-filenames.sh"
