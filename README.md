# rwhite-iot-project-complete

Created to be used in conjunction with the Mako Server. The server can be installed at
https://makoserver.net/download/windows/
for windows machines.



After downloading the server, insert the **ProjectApplication** folder into the saved MakoServer folder just downloaded, 
or whatever name you decided to give it.

If you use the command prompt to access the MakoServer document after saving it, you can use the command

mako -l::ProjectApplication

to access the project's website.

On start, a database will be created with a root user in place, log in using 'root' and 'COM810' as the password.

**If you are using windows 10, be sure to add the https:// prefix and allow access to the website to prevent
   issues with websocket connection**
**If the devices and add devices pages provide a disconnected error message, also add the https:// prefix **

# Installing and using the Raspberry Pi "Raspian" Linux as a hardware simulator.

Download and install Oracle VirtualBox from https://www.virtualbox.org/wiki/Downloads
Download and unpack Raspian VM (Virtual Disk Image) from https://www.osboxes.org/raspbian

Run VirtualBox.

    Select "New"
        Name = Raspian
        Type = Linux
        Version = Other Linux (32bit)
        Set Memory size to at least 1024MB
        Hard Disk = Use existing hard disk. Select the unzipped Raspian vdi (virtual disk image file)
                    Raspian 2017-11 (32bit).vdi


Before starting the VM, change the network configuration to have 2 interfaces (not completely necessary):

1 - NAT
2 - Bridged (this allows the VM to be reachable and have an IP address on the local network)
  - If not bridged, the VM will share the IP address of the host machine (will still work)





Once the VM boots, log in with the default "pi" user and password of osboxes.org (as given on the osboxes.org web site).


Open a terminal window and create a new directory called IOT and make it your current directory.

**mkdir IOT**
**cd IOT**

Now clone the github repsoitory for the project:

**git clone git://github.com/rtwhite222/rwhite-iot-project-complete**

The latest branch is master (no branches).

Set up the device to connect to the server through editing the /etc/hosts file, for example (vi):

**sudo vi /etc/hosts**

Create a manual map between the server's IP address and the server name (proj-srv)
through appending the following (server's network IP in place of serverIPaddress) 

**serverIPaddress		proj-srv**

To ascertain the local IP address of the server use ipconfig on the server (for windows machines).

Change directory to the SMQ example designed for the device.

**cd rwhite/iot-project-complete/SimpleMQ**

Make the executable.

**make**

Run the executable

**./machine-smq**

The device should now show up in the webserver's device discovery page!

The device-side code in its unedited form can be found at https://embedded-app-server.info/IoT.lsp
