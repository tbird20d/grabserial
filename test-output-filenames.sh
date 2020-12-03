#!/bin/sh
#
# test-output-filenames.sh
#

if [ -n "$1" ] ; then
    if [ "$1" = "-h" ] ; then
        echo "Usage: test-output-filenames.sh [options]"
        echo " -h  Show this usage help"
        echo ""
        echo "Test different output filenames"
        echo ""
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

ls -ltr | grep -v total | grep -v dir_list >dir_list_before.txt

# Also, use ttc to reboot bbb

# use ttc to reboot my beaglebone black
echo "==================================="
echo "Testing with python 2"
echo "  60 second grab, stopping when 'Starting kernel' is seen"
echo "  using filename '%'"
echo "==================================="

# do the reboot after grabserial is started
(sleep 1 ; ttc reboot bbb) &

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

(sleep 1 ; ttc reboot bbb) &
./grabserial  -v -S -d ${console_dev} -e 60 -t -q "Starting kernel" \
    -o %s.log

echo "==== Done with grabserial capture ===="
echo

echo "==================================="
echo "Testing with python 2"
echo "  60 second grab, stopping when 'Starting kernel' is seen"
echo "  using filename 'mylog-%F_%T.log'"
echo "==================================="

(sleep 1 ; ttc reboot bbb) &
./grabserial  -v -S -d ${console_dev} -e 60 -t -q "Starting kernel" \
    -o mylog-%F_%T.log

echo "==== Done with grabserial capture ===="
echo

echo "Checking for output filename"
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
echo "Done in test-output-filenames.sh"
