#!/bin/sh

./grabserial  -v -d /dev/ttyACM1 -e 30 -t -m "Starting kernel" -i "done," -q "done" -o graboutput.log & ttc reboot bbb

sleep 31

