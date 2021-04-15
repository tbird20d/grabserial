# Use Case Study
---
## Continuous Serial Data Logging

### Logging sensor data continuously (running grabserial as a service)

Having built a small sensor based on an Arduino Nano, a DS18B20 temperature sensor and a relay to control, I wanted a way to capture the data that I was logging to the serial interface to analyze and graph it.  I used a Raspberry Pi Zero W running Rasbian (Stretch) for this purpose.  The examples below however were done on a laptop running Ubuntu 18.04 LTS to ensure that the process could be duplicated with this guide.

Both of these systems use [systemd](https://en.wikipedia.org/wiki/Systemd) for process initialization.

We're going to need to set up a couple of things before we can configure grabserial to run as a service.

 * Create a system user id (and group) for the service to run as
 * Create a folder to write the log files into
 * Determine the systemd unit for the serial device we will be listening to

### Create System User

We are going to create a system account and group named grabserial with no home directory and no login capability.

```
sudo adduser --system --no-create-home --disabled-login --group grabserial
```
Since the system user will be opening the serial port, we need to add it to the group that the device belongs to.  On my system that was the 'dialout' group.  You can confirm on your system by checking the group associated with your device.

```
$ ls -l /dev/ttyUSB0
crw-rw---- 1 root dialout 188, 0 Sep  4 23:30 /dev/ttyUSB0
```
Here we add the system user to the dialout group.

```
sudo usermod --append --groups dialout grabserial
```

#### Side Note - pyserial module should be installed globally
Since we are using a system user to run grabserial, we need to ensure that the pyserial module is installed globally and is accessible to the script.  Run either or both of the command lines below if you're unsure.

```
sudo -H pip install pyserial
# or
sudo -H pip3 install pyserial
```


### Create Folder for Log Files

I decided to put all of the log files in a folder on /var called grabserial.

```
sudo mkdir /var/grabserial
sudo chown grabserial:grabserial /var/grabserial
```

This will create the folder and then change the ownership of the folder to be the system user (and group) that we created earlier.

```
$ ls -ld /var/grabserial
drwxr-xr-x 2 grabserial grabserial 4096 Sep  9 00:03 /var/grabserial
```

The last thing we need to do is determine the systemd unit for the serial device we will be listening to.  For a USB device, you'll want to do this step with the device attached so that it is loaded and active.  Simply take the output from systemctl and grep for your device.

```
$ sudo systemctl | grep ttyUSB0 |  awk '{print $1}'
sys-devices-pci0000:00-0000:00:1c.3-0000:07:00.0-usb3-3\x2d1-3\x2d1:1.0-ttyUSB0-tty-ttyUSB0.device
```
You'll need this to customize your systemd unit file, which we're now ready to create.  Start off redirecting the output of the above command to a file.

```
sudo systemctl | grep ttyUSB0 |  awk '{print $1}' > serialdatalogger.service
```

Then open that file in your favourite text editor and add the rest of the systemd configuration.  Here's mine.

```
[Unit]
Description=Serial Data Logging Service
After=sys-devices-pci0000:00-0000:00:1c.3-0000:07:00.0-usb3-3\x2d1-3\x2d1:1.0-ttyUSB0-tty-ttyUSB0.device
BindsTo=sys-devices-pci0000:00-0000:00:1c.3-0000:07:00.0-usb3-3\x2d1-3\x2d1:1.0-ttyUSB0-tty-ttyUSB0.device

[Service]
Type=simple
GuessMainPID=no
KillMode=process
Environment=PYTHONIOENCODING=utf-8
ExecStart=/usr/local/bin/grabserial -v -Q -T -d /dev/ttyUSB0 -b 115200 -o "/var/grabserial/SensorData-%%Y%%m%%d.log" -A
TimeoutSec=2
Restart=on-failure
RestartPreventExitStatus=2 3
StandardInput=null
StandardOutput=syslog
StandardError=syslog+console
SyslogIdentifier=GrabSerial
User=grabserial
Group=grabserial
SupplementaryGroups=dialout
PermissionsStartOnly=true

[Install]
WantedBy=sys-devices-pci0000:00-0000:00:1c.3-0000:07:00.0-usb3-3\x2d1-3\x2d1:1.0-ttyUSB0-tty-ttyUSB0.device
WantedBy=multi-user.target
```

You can see that I referenced the serial device in three places:
 * After=
 * BindsTo=
 * WantedBy=

You can also see that you need to specify the full path in ExecStart to the grabserial script and where we will be writing the log files out to.

Now that the file is created, we need to place it in the correct folder and enable the service.

```
sudo cp serialdatalogger.service /etc/systemd/system/
```

Then we enable the service so that it starts when the system reboots as soon as the serial device becomes available.

```
$ sudo systemctl enable serialdatalogger.service
Created symlink /etc/systemd/system/sys-devices-pci0000:00-0000:00:1c.3-0000:07:00.0-usb3-3\x2d1-3\x2d1:1.0-ttyUSB0-tty-ttyUSB0.device.wants/serialdatalogger.service → /etc/systemd/system/serialdatalogger.service.
Created symlink /etc/systemd/system/multi-user.target.wants/serialdatalogger.service → /etc/systemd/system/serialdatalogger.service.
```
Finally, we start the service.

```
sudo systemctl start serialdatalogger.service
```

Confirm that it is running.

```
$ sudo systemctl status serialdatalogger.service
● serialdatalogger.service - Serial Data Logging Service
   Loaded: loaded (/etc/systemd/system/serialdatalogger.service; enabled; vendor preset: enabled)
   Active: active (running) since Mon 2019-09-09 08:51:08 EDT; 4min 2s ago
 Main PID: 11475 (grabserial)
    Tasks: 2 (limit: 4915)
   CGroup: /system.slice/serialdatalogger.service
           └─11475 /usr/bin/python /usr/local/bin/grabserial -v -Q -T -d /dev/ttyUSB0 -b 115200 -o /var/grabserial/SensorData-%Y%m%d.log -A

Sep 09 08:51:08 myhostname systemd[1]: Started Serial Data Logging Service.
Sep 09 08:51:12 myhostname GrabSerial[11475]: Opening serial port /dev/ttyUSB0
Sep 09 08:51:12 myhostname GrabSerial[11475]: 115200:8N1:xonxoff=0:rtscts=0
Sep 09 08:51:12 myhostname GrabSerial[11475]: Printing absolute timing information for each line
Sep 09 08:51:12 myhostname GrabSerial[11475]: Appending data to '/var/grabserial/SensorData-20190909.log'
Sep 09 08:51:12 myhostname GrabSerial[11475]: Keeping quiet on stdout
Sep 09 08:51:12 myhostname GrabSerial[11475]: Use Control-C to stop...
```
### Summary

We now have grabserial running as a service.  It will start on system boot-up if and when the device is present.  It will stop the service if the device is removed.

---

### Addendum: Support for multiple identical serial devices

In the above example, systemd automatically creates device units for each serial device plugged in. These names contain the device path in addition to the allocated tty device name. Plugging the serial adapter into a different USB port or plugging in multiple serial adapters in different sequences will generate different unit names. A custom udev rule can be used to provide a custom systemd unit alias to work around this problem, making it possible to watch for any device plugged into a specific port or a specific device plugged into any port. This addendum focusses on the former use case, but shouldn't be difficult to adapt to the latter.

Use this command to view the udev device attributes for one of your serial adapters. These attributes can be used in the udev rule to target the correct devices.

```
udevadm info -a -n /dev/ttyUSB0
```

Create a new udev rules file:

```
sudo vi /etc/udev/rules.d/99-usb-serial.rules
```

and add something like this:

```
ACTION=="add", SUBSYSTEM=="tty", SUBSYSTEMS=="usb", DRIVERS=="usb", SYMLINK+="tty.usb-$attr{devpath}", TAG+="systemd", ENV{SYSTEMD_ALIAS}="/sys/subsystem/usb/devices/usb-serial-$attr{devpath}"
```

 * `ACTION=="add"`: When a device is added.
 * `SUBSYSTEM=="tty"`: And the device is in the TTY subsystem.
 * `SUBSYSTEMS=="usb"`: And one of the device's parents is in the USB subsystem.
 * `DRIVERS=="usb"`: And one of the device's parents is using the USB driver.
 * `SYMLINK+="..."`: Create a new device symlink that includes the USB device path in the name (e.g. `/dev/tty.usb-1.2`).
 * `TAG+="systemd"`: Make sure systemd is aware of this device.
 * `ENV{SYSTEMD_ALIAS}="..."`: Create a new systemd unit name alias. It's not clear what constitutes a valid path, but `/dev/...` didn't work for me and there were several other SYSTEMD_ALIASes roughly matching this pattern.

Tell udev to reload its rules:

```
sudo udevadm trigger
```

This udev rule will create a USB port-specific device symlink for each serial adapter. For example, with three serial adapters plugged into my Raspberry Pi, I get three port-specific device symlinks:

```
$ ls -l /dev/*usb*
lrwxrwxrwx 1 root root 7 Apr 14 04:52 /dev/tty.usb-1.2 -> ttyUSB1
lrwxrwxrwx 1 root root 7 Apr 14 04:51 /dev/tty.usb-1.3 -> ttyUSB0
lrwxrwxrwx 1 root root 7 Apr 14 04:53 /dev/tty.usb-1.4 -> ttyUSB2
```

If they're plugged into the Pi in a different sequence, they'll get different `/dev/ttyUSBx` paths, but `/dev/tty.usb-1.2` will always point to whichever one is plugged into port number 2, etc.

In addition to the default systemd device unit which includes the full device path, it now also generates a custom systemd device unit alias which can be used in the systemd service as described above.

```
$ sudo systemctl | grep -i '1.2' | awk '{print $1}'
sys-devices-platform-soc-3f980000.usb-usb1-1\x2d1-1\x2d1.2-1\x2d1.2:1.0-ttyUSB1-tty-ttyUSB1.device
sys-subsystem-usb-devices-usb\x2dserial\x2d1.2.device
```

I created a service template. A service template contains an `@` symbol at the end of the filename and any `%i` tokens will be replaced by whatever follows the `@` symbol when the service is instantiated. Here, the `%i` is used as a variable for the USB port identifier.

```
$ cat /etc/systemd/system/seriallog@.service
[Unit]
Description=Serial Log Service %I
After=sys-subsystem-usb-devices-usb\x2dserial\x2d%i.device
BindsTo=sys-subsystem-usb-devices-usb\x2dserial\x2d%i.device

[Service]
Type=simple
GuessMainPID=no
KillMode=process
Environment=PYTHONIOENCODING=utf-8
ExecStart=/usr/local/bin/grabserial --verbose --quiet -d /dev/tty.usb-%i --output="/var/grabserial/serial%i-%%Y-%%m-%%d_%%H-%%M-%%S.log"
TimeoutSec=2
Restart=on-failure
RestartPreventExitStatus=2 3
StandardInput=null
StandardOutput=syslog
StandardError=syslog+console
SyslogIdentifier=GrabSerial
User=grabserial
Group=grabserial
SupplementaryGroups=dialout
PermissionsStartOnly=true

[Install]
WantedBy=sys-subsystem-usb-devices-usb\x2dserial\x2d%i.device
WantedBy=multi-user.target
```

The service template can then be used to create a service instance for each port:

```
sudo systemctl enable seriallog@1.2.service
sudo systemctl enable seriallog@1.3.service
```

With this configuration, each serial adapter will log to its own deterministic log file.

---
