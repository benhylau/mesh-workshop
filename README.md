Mesh Workshop
=============

[![Generic badge](https://img.shields.io/badge/Workshop_time-1_hour-1f73e0.svg)](https://github.com/benhylau/mesh-workshop)
[![Generic badge](https://img.shields.io/badge/Martix_chat-%23tomesh:tomesh.net-666666.svg)](https://chat.tomesh.net/#/room/#tomesh:tomesh.net)
[![Generic badge](https://img.shields.io/badge/IRC-freenode%2F%23tomesh-666666.svg)](https://webchat.freenode.net/?channels=tomesh)

This repository describes nodes used to facilitate workshops and demos for mesh networking. The nodes boot with multiple zero-configuration technologies such as mDNS and self-addressing auto-peering mesh protocols to eliminate initial set up time. An autonomous network is formed upon power-on and nodes can address each other over `<hostname>.local` addresses.

The scripts to generate unique configurations for each node is contained in this repository. Creation of the nodes is fast and trivial, and only needs to be done once, since the nodes do not persist any runtime state. User sessions are run off a ramdisk (and a swap memory-backed filesystem) such that all runtime states are lost across power cycles.

Once the nodes are prepared, no Internet connection is necessary to run this workshop (unless you want to run docker containers). All the software is pre-installed and the peer-to-peer network operates without the need for a central server or Internet connectivity.


Hardware
--------

Each node consists of one:

* Raspberry Pi 3
* [USB WiFi adapter](https://github.com/phillymesh/802.11s-adapters/blob/master/README.md) with `ath9k_htc`, `rt2800usb`, or `rtl8192cu` driver
* SD card with 8 GB or more space

Other accessories:

* Power supply for Raspberry Pi 3
* Ethernet cables
* A network switch may come in handy


Software
--------

You need a recent release of [mesh-orange](https://github.com/tomeshnet/mesh-orange) built using [mesh-router-builder](https://github.com/benhylau/mesh-router-builder), where the [cjdns](https://github.com/cjdelisle/cjdns) and [yggdrasil](https://github.com/Arceliar/yggdrasil-go/) mesh routers are pre-installed along with other tools required for this workshop. You can [download from here](https://github.com/benhylau/mesh-router-builder/releases) a recent `raspberrypi3-<version>.img`.

Now you can clone this repository and run `./build` to generate 40 unique host configurations under `output/`. Simply flash the downloaded image onto an SD card, mount its FAT partition to your computer, then copy from `output/conf.d/<hostname>/*` to the `conf.d/` on the SD card root. For example, on Mac OS:

	$ cp output/conf.d/bloor/* /Volumes/BOOT/conf.d/

Now you have configured the node with hostname `bloor`.


What does it do?
----------------

### Connect to Access Point

The Raspberry Pi's 3 on-board WiFi radio is configured as an Access Point with:

	SSID:       <hostname>
	Password:   password
	IP address: 10.0.0.1

In the example, you can connect to the SSID `bloor` with password `password`.


### Log in to Raspberry Pi over SSH

Once connected to the Access Point from your computer, you can connect to it with SSH password `root`:

	$ ssh root@<hostname>.local

In the example, this would be `ssh root@bloor.local`. You can also connect to the IP address directly without using mDNS `ssh root@10.0.0.1`.


### Investigate network interfaces with `networkctl`

You can list all the network interfaces with `networkctl`:

	root@bloor:~# networkctl
	IDX LINK             TYPE               OPERATIONAL SETUP
	  1 lo               loopback           carrier     unmanaged
	  2 eth0             ether              no-carrier  configuring
	  3 wlan0            wlan               routable    configured
	  4 tun0             none               routable    unmanaged
	  5 wlan1            wlan               routable    configured
	  6 tun1             none               routable    unmanaged
	  7 docker0          ether              no-carrier  unmanaged

	7 links listed.

Then use `networkctl status` to see their assigned IP addresses:

	root@bloor:~# networkctl status
	●        State: routable
	       Address: 10.0.1.3 on wlan0
	                10.0.0.1 on wlan1
	                172.17.0.1 on docker0
	                169.254.227.187 on wlan0
	                fd00:338a:9ae7:1947:8a2b:7ea3:5c2d:f737 on tun0
	                fcb0:3f14:ebc8:1f7b:a1ce:bd44:a410:5049 on tun1
	                fe80::8e88:2bff:fe00:e2 on wlan0
	                fe80::ab48:ab55:de33:5d74 on tun0
	                fe80::ba27:ebff:fe95:382b on wlan1
	                fe80::2dfe:b629:409d:e802 on tun1

In this example, the mesh router:

* cjdns created `tun1` with `fcb0:3f14:ebc8:1f7b:a1ce:bd44:a410:5049` in its `fc00::/8` address space
* yggdrasil created `tun0` with `fd00:338a:9ae7:1947:8a2b:7ea3:5c2d:f737` in its `fd00::/8` address space


### Observe wireless interfaces with `iw`

You can use `iw dev` to see the on-board WiFi radio in `AP` mode on `channel 11` and the USB WiFi radio in `mesh point` mode on `channel 1` taking up `40 MHz`:

	root@bloor:~# iw dev
	phy#1
	        Interface wlan1
	                ifindex 5
	                wdev 0x100000001
	                addr b8:27:eb:95:38:2b
	                ssid bloor
	                type AP
	                channel 11 (2462 MHz), width: 20 MHz, center1: 2462 MHz
	                txpower 31.00 dBm
	phy#0
	        Interface wlan0
	                ifindex 3
	                wdev 0x1
	                addr 8c:88:2b:00:00:e2
	                type mesh point
	                channel 1 (2412 MHz), width: 40 MHz, center1: 2422 MHz
	                txpower 30.00 dBm

Then you can do a `iw <interface> station dump` to see devices connected to the interface:

	root@bloor:~# iw wlan1 station dump
	Station b8:e8:56:2b:30:c6 (on wlan1)
	        inactive time:  0 ms
	        rx bytes:       155498
	        rx packets:     1487
	        tx bytes:       104580
	        tx packets:     716
	        tx failed:      1
	        signal:         -27 [-27] dBm
	        tx bitrate:     72.2 MBit/s
	        rx bitrate:     65.0 MBit/s
	        authorized:     yes
	        authenticated:  yes
	        associated:     yes
	        WMM/WME:        yes
	        TDLS peer:      yes
	        DTIM period:    2
	        beacon interval:100
	        short slot time:yes
	        connected time: 301 seconds

In this example, it is showing the radio of my laptop that is connected to the Raspberry Pi's Access Point on `wlan0`.


### Dial a peer with `ping`

Ping another node that is peered over the mesh point interface. For example, to ping the host `college`, you can do:

	root@bloor:~# ping college.local

This will ping the local addresses advertised by mDNS. You can also ping the cjdns and yggdrasil addresses. For example:

	root@bloor:~# ping -6 cjdns.college.local
	root@bloor:~# ping -6 ygg.college.local

Or you can ping the IP addresses directly. For example, `college` can ping `bloor` like this:

	root@college:~# ping -6 fcb0:3f14:ebc8:1f7b:a1ce:bd44:a410:5049
	root@college:~# ping -6 fd00:338a:9ae7:1947:8a2b:7ea3:5c2d:f737

These pings go through the encrypted `tun1` and `tun0` virtual interfaces, associated with cjdns and yggdrasil, respectively in this example. Note that these addresses are regenerated on power cycle.

Sometimes cjdns does not know that a new peer came up, so if the ping fails you need to restart the process with:

	kill `ps aux | grep -e '^nobody.*cjdroute' | awk '{ print $2 }'`

### Send test traffic with `iperf3`

To measure network bandwidth, one host needs to run an iperf3 server:

	root@bloor:~# iperf3 -s

If `bloor` is running as server, `college` can send test traffic to it with:

	root@college:~# iperf3 -c bloor.local

You can also test the encrypted interfaces and observe that the bandwidth is lower:

	root@college:~# iperf3 -6 -c cjdns.bloor.local
	root@college:~# iperf3 -6 -c ygg.bloor.local

After the test, `bloor` can hit `Ctrl + C` to stop the iperf3 server.


### Make wired ethernet link and assign route with `ip`

Connect an ethernet cable between `bloor` and `college`, run `networkctl` on each node and observe that `eth0` now shows up as `degraded`:

	root@bloor:~# networkctl
	IDX LINK             TYPE               OPERATIONAL SETUP
	  1 lo               loopback           carrier     unmanaged
	  2 eth0             ether              degraded    configuring

That's because it has no IP address assigned to it, but we can manually assign `192.168.0.1` to the interface on `bloor`:

	root@bloor:~# ip addr add 192.168.0.1 dev eth0

You will now see `networkctl` show it as `routable`. Now assign `192.168.0.2` to the `eth0` interface on `college`:

	root@college:~# ip addr add 192.168.0.2 dev eth0

You are still unable to ping `192.168.0.2` from `192.168.0.1` until you add a route that tells your node to pass traffic destined for the `192.168.0.0/24` subnet to the `eth0` interface with IP address `192.168.0.1`:

	root@bloor:~# ip route add 192.168.0.0/24 via 192.168.0.1

Now you may list your routes with `ip route` and see the new static route:

	root@bloor:~# ip route
	default dev wlan0 proto static scope link metric 2048
	10.0.0.0/24 dev wlan1 proto kernel scope link src 10.0.0.1
	10.0.1.0/24 dev wlan0 proto kernel scope link src 10.0.1.3
	169.254.0.0/16 dev wlan0 proto kernel scope link src 169.254.227.187
	172.17.0.0/16 dev docker0 proto kernel scope link src 172.17.0.1 linkdown
	192.168.0.0/24 via 192.168.0.1 dev eth0

Similarly on `college`, add route and ping:

	root@college:~# ip route add 192.168.0.0/24 via 192.168.0.2
	root@college:~# ping 192.168.0.1

Now you can iperf3 across the new wired link and observe close to 100 Mbps bandwidth because the Raspberry Pi 3 supports a 10/100 Mbps ethernet interface.


### Mesh three nodes using cjdns and yggdrasil

Construct the following network topology:

    +--------------------+      +--------------------+                +------------------+
    | bloor              | WiFi | jane               |                | college          |
    | - wireless adapter +------+ - wireless adapter | ethernet cable |                  |
    |                    |      | - wired ethernet   +================+ - wired ethernet |
    +--------------------+      +--------------------+                +------------------+

You will find that `bloor` and `college` cannot ping each other over the link-local addresses, but they can find a path to each other via `jane` on the cjdns and yggdrasil addresses, because these are mesh routers that will relay traffic across multiple hops. For example:

	root@college:~# ping -6 fcb0:3f14:ebc8:1f7b:a1ce:bd44:a410:5049
	root@college:~# ping -6 fd00:338a:9ae7:1947:8a2b:7ea3:5c2d:f737

You can also iperf3 the two nodes and observe the bandwidth between the two nodes while routing via `jane`. Note that mDNS addresses will not resolve here, because the mDNS requests are not forwarded across network interfaces (i.e. WiFi and wired ethernet).


### Run applications with `docker`

The images have `docker` pre-installed, so you just need to get the `Dockerfile` you need and start the container. Unlike other sections, this part requires Internet access and more manual steps. Hopefully we can improve on this in the future.

It is not a concern that we will run out of ramdisk space, because 6 GB of the SD card is used to back the in-memory filesystem:

	root@bloor:~# df -t rootfs -h
	Filesystem      Size  Used Avail Use% Mounted on
	rootfs          5.8G  350M  5.4G   6% /

See? We have plenty of space. The backing partition is mounted as swap memory so state is not retained after power cycle.
