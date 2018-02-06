Mesh Workshop
=============

This repository describes nodes used to facilitate workshops and demos for mesh networking. The nodes boot with multiple zero-configuration technologies such as mDNS and self-addressing auto-peering mesh protocols to eliminate initial set up time. An autonomous network is formed upon power-on and nodes can address each other over `<hostname>.local` addresses.

The scripts to generate unique configurations for each node is contained in this repository. Creation of the nodes is fast and trivial, and only needs to be done once, since the nodes do not persist any runtime state. User sessions are run off a ramdisk (and a swap memory-backed filesystem) such that all runtime states are lost across power cycles.


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

Now you can clone this repository and run `./build` to generate 40 unique host configurations under `output/`. Simply flash the downloaded image onto an SD card, mount its FAT partition to your computer, then copy from `output/<hostname>/conf.d/*` to the `conf.d/` on the SD card root. For example, on Mac OS:

	$ cp -r output/bloor/conf.d/* /Volumes/BOOT/conf.d/

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
	  4 wlan1            wlan               routable    configured
	  5 tun0             none               routable    unmanaged
	  6 tun1             none               routable    unmanaged

	6 links listed.

Then use `networkctl status` to see their assigned IP addresses:

	root@bloor:~# networkctl status
	●        State: routable
	       Address: 10.0.0.1 on wlan0
	                10.0.1.1 on wlan0
	                10.0.2.1 on wlan1
	                fd00:338a:9ae7:1947:8a2b:7ea3:5c2d:f737 on tun0
	                fcb0:3f14:ebc8:1f7b:a1ce:bd44:a410:5049 on tun1
	                fe80::ba27:ebff:fec0:6d7e on eth0
	                fe80::ba27:ebff:fe95:382b on wlan0
	                fe80::8616:f9ff:fe10:7656 on wlan1
	                fe80::8ff1:4b:c4df:dde7 on tun0
	                fe80::22b3:5c97:c621:6de9 on tun1

In this example, cjdns created `tun1` with `fcb0:3f14:ebc8:1f7b:a1ce:bd44:a410:5049` in its `fc00::/8` address space, and yggdrasil created `tun0` with `fd00:338a:9ae7:1947:8a2b:7ea3:5c2d:f737` in its `fd00::/8` address space.


### Observe wireless interfaces with `iw`

You can use `iw dev` to see the on-board WiFi radio in `AP` mode on `channel 11` and the USB WiFi radio in `mesh point` mode on `channel 1` taking up `40 MHz`:

	root@bloor:~# iw dev
	phy#0
	        Interface wlan1
	                ifindex 4
	                wdev 0x1
	                addr 84:16:f9:10:76:56
	                type mesh point
	                channel 1 (2412 MHz), width: 40 MHz, center1: 2422 MHz
	                txpower 20.00 dBm
	phy#1
	        Interface wlan0
	                ifindex 3
	                wdev 0x100000001
	                addr b8:27:eb:95:38:2b
	                ssid bloor
	                type AP
	                channel 11 (2462 MHz), width: 20 MHz, center1: 2462 MHz
	                txpower 31.00 dBm

Then you can do a `iw <interface> station dump` to see devices connected to the interface:

	root@bloor:~# iw wlan0 station dump
	Station b8:e8:56:2b:30:c6 (on wlan0)
	        inactive time:  0 ms
	        rx bytes:       249360
	        rx packets:     1741
	        tx bytes:       211093
	        tx packets:     955
	        tx failed:      10
	        signal:         -36 [-36] dBm
	        tx bitrate:     72.2 MBit/s
	        rx bitrate:     72.2 MBit/s
	        authorized:     yes
	        authenticated:  yes
	        associated:     yes
	        WMM/WME:        yes
	        TDLS peer:      yes
	        DTIM period:    2
	        beacon interval:100
	        short slot time:yes
	        connected time: 297 seconds

In this example, it is showing the radio of my laptop that is connected to the Raspberry Pi's Access Point on `wlan0`.


### Dial a peer with `ping`

Ping another node that is peered over the mesh point interface. For example, to ping the host `college`, you can do:

	root@bloor:~# ping college.local
	root@bloor:~# ping6 college.local

This will ping the link-local addresses because mDNS advertises those addresses. You can also ping the cjdns and yggdrasil addresses. For example, another node can ping `bloor` like this:

	root@college:~# ping6 fcb0:3f14:ebc8:1f7b:a1ce:bd44:a410:5049
	root@college:~# ping6 fd00:338a:9ae7:1947:8a2b:7ea3:5c2d:f737

Now these pings go through the encrypted `tun1` and `tun0` virtual interfaces, associated with cjdns and yggdrasil, respectively in this example. Note that these addresses are regenerated on power cycle.


### Send test traffic with `iperf3`

To measure network bandwidth, one host needs to run an iperf3 server:

	root@bloor:~# iperf3 -s

If `bloor` is running as server, another node can send test traffic to it with:

	root@college:~# iperf3 -c bloor.local

You can also test the encrypted interfaces and observe that the bandwidth is lower:

	root@college:~# iperf3 -c fcb0:3f14:ebc8:1f7b:a1ce:bd44:a410:5049
	root@college:~# iperf3 -c fd00:338a:9ae7:1947:8a2b:7ea3:5c2d:f737

After the test, `bloor` can hit `Ctrl+C` to stop the iperf3 server.


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
	10.0.0.0/24 dev wlan0 proto kernel scope link src 10.0.0.1
	10.0.1.0/24 dev wlan0 proto kernel scope link src 10.0.1.1
	10.0.2.0/24 dev wlan1 proto kernel scope link src 10.0.2.1
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

You will find that `bloor` and `college` cannot ping each other over the link-local addresses, but they can find a path to each other via `jane` on the cjdns and yggdrasil addresses, because they are mesh routers. For example:

	root@college:~# ping6 fcb0:3f14:ebc8:1f7b:a1ce:bd44:a410:5049
	root@college:~# ping6 fd00:338a:9ae7:1947:8a2b:7ea3:5c2d:f737

You can also iperf3 the two nodes and observe the bandwidth between the two nodes while routing via `jane`.


### Run applications with `docker`

The images have `docker` pre-installed, so you just need to get the `Dockerfile` you need and start the container. Unlike other sections, this part requires Internet access and more manual steps. Hopefully we can improve on this in the futre.

It is not a concern that we will run out of ramdisk space, because 6 GB of the SD card is used to back the in-memory filesystem:

	root@bloor:~# df -t rootfs -h
	Filesystem      Size  Used Avail Use% Mounted on
	rootfs          5.8G  243M  5.5G   5% /

See? We have plenty of space. The backing partition is mounted as swap memory so state is not retained after power cycle.