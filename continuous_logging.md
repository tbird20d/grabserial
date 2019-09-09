# Use Case Study
---
## Continuous Serial Data Logging

### Logging sensor data continuously (running grabserial as a service)

Having built a small sensor based on an Arduino Nano, a DS18B20 temperature sensor and a relay to control, I wanted a way to capture the data that I was logging to the serial interface in order to analyze and graph it.  I used a Raspberry Pi Zero W running Rasbian (Stretch) for this purpose.  The examples below however were done on a laptop running Ubuntu 18.04 LTS to ensure that the process could be duplicated with this guide.

Both of these systems use [systemd](https://en.wikipedia.org/wiki/Systemd) for process initialization.

We're going to need to setup a couple of things before we can setup grabserial to run as a service.

 * Create a system user id (and group) for the service to run as
 * Create a folder to write the log files into
 * Determine the systemd unit for the serial device we will be listening to

### Create System User

We are going to create a system account with no home directory and no login capability.

```
sudo adduser --system --no-create-home --disabled-login --group grabserial
```
Since the system user will be opening the serial port, we need to add it to the group that the device belongs to.  On my system that was the dialout group.  You can confirm on your system by checking the group associated with your device.

```
$ ls -l /dev/ttyUSB0
crw-rw---- 1 root dialout 188, 0 Sep  4 23:30 /dev/ttyUSB0
```
Here we add the system user to the dialout group.

```
sudo usermod --append --groups dialout grabserial
```

### Create Folder for Log Files

I decided to put all of the log files in a folder on /var called grabserial.

```
sudo mkdir /var/grabserial
sudo chown grabserial:grabserial /var/grabserial
```

This will create the folder and then change the ownership of the folder to be the system user (and group) that we created earlier.

The last thing we need to do is to determine the systemd unit for the serial device we will be listening to.  For a USB device, you'll want to do this step with the device attached so that it is loaded and active.  Simply take the output from systemctl and grep for your device.

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
---
