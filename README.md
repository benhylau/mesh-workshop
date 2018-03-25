Mesh Workshop
=============

[![Generic badge](https://img.shields.io/badge/Workshop_time-2_hours-1f73e0.svg)](https://github.com/benhylau/mesh-workshop)
[![Generic badge](https://img.shields.io/badge/Martix_chat-%23tomesh:tomesh.net-666666.svg)](https://chat.tomesh.net/#/room/#tomesh:tomesh.net)
[![Generic badge](https://img.shields.io/badge/IRC-freenode%2F%23tomesh-666666.svg)](https://webchat.freenode.net/?channels=tomesh)

This repository describes nodes used to facilitate workshops and demos for mesh networking. The nodes boot with multiple zero-configuration technologies such as mDNS and self-addressing auto-peering mesh protocols to eliminate initial set up time. An autonomous network is formed upon power-on and nodes can address each other over `<hostname>.local` addresses.

The scripts to generate unique configurations for each node is contained in this repository. Creation of the nodes is fast and trivial, and only needs to be done once, since the nodes do not persist any runtime state. User sessions are run off a ramdisk (and a swap memory-backed filesystem) such that all runtime states are lost across power cycles.

Once the nodes are prepared, no Internet connection is necessary to run this workshop (unless you want to run docker containers). All the software is pre-installed and the peer-to-peer network operates without the need for a central server or Internet connectivity.


Hardware
--------

Each node consists of one:

* Raspberry Pi 3
* [USB WiFi adapter](https://github.com/phillymesh/802.11s-adapters/blob/master/README.md) with `rt2800usb`, `ath9k_htc`, or `rtl8192cu` driver
* SD card with 8 GB or more space

Other accessories:

* Power supply for Raspberry Pi 3
* Ethernet cables
* A network switch may come in handy

_You may optionally use a Raspberry Pi 2 instead of a Raspberry Pi 3. In that case, you should have one `rt2800usb` adapter (for mesh point) and one `ath9k_htc` or `rtl8192cu` adapter (for access point). The configuration scripts will by default detect Raspberry Pi 2 hardware and configure these interfaces as described._


Software
--------

You need a recent release of [mesh-orange](https://github.com/tomeshnet/mesh-orange) built using [mesh-router-builder](https://github.com/benhylau/mesh-router-builder), where the [cjdns](https://github.com/cjdelisle/cjdns) and [yggdrasil](https://github.com/Arceliar/yggdrasil-go/) mesh routers are pre-installed along with other tools required for this workshop. You can download from [**mesh-router-builder/releases**](https://github.com/benhylau/mesh-router-builder/releases) a recent `raspberrypi3-<version>.img`.

Now you can clone this repository and run `./build` to generate 40 unique host configurations under `output/`, or download the ones I built from [**mesh-workshop/releases**](https://github.com/benhylau/mesh-workshop/releases). The 40 configurations are packaged as `confd-<version>.tar.gz` and `confd-<version>.zip`, so you just need to extract the archives to find all of them.

Once you have both the mesh-orange image and per-node host configurations, simply flash the downloaded image onto an SD card with a tool like [Etcher](https://etcher.io), mount its FAT partition to your computer, then copy from `output/conf.d/<hostname>/*` to the `conf.d/` on the SD card root. For example, on Mac OS:

	$ cp -r output/conf.d/bloor/* /Volumes/BOOT/conf.d/

Now you have configured the node with hostname `bloor`.


What does it do?
----------------

Power on the Raspberry Pi 3 and wait for a solid green LED with a flashing red LED. Now your node is ready.

### 1. Connect to Access Point

The Raspberry Pi's 3 on-board WiFi radio is configured as an Access Point with:

	SSID:       <hostname>
	Password:   password
	IP address: 10.0.0.1

In the example, you can connect to the SSID `bloor` with password `password`.


### 2. Log in to Raspberry Pi over SSH

Once connected to the Access Point from your computer, you can connect to it with SSH password `root`:

	$ ssh root@<hostname>.local

In the example, this would be `ssh root@bloor.local`. You can also connect to the IP address directly without using mDNS `ssh root@10.0.0.1`.


### 3. Investigate network interfaces with `networkctl`

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


### 4. Observe wireless interfaces with `iw`

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


### 5. Dial a peer with `ping`

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

### 6. Send test traffic with `iperf3`

To measure network bandwidth, one host needs to run an iperf3 server:

	root@bloor:~# iperf3 -s

If `bloor` is running as server, `college` can send test traffic to it with:

	root@college:~# iperf3 -c bloor.local

You can also test the encrypted interfaces and observe that the bandwidth is lower:

	root@college:~# iperf3 -6 -c cjdns.bloor.local
	root@college:~# iperf3 -6 -c ygg.bloor.local

After the test, `bloor` can hit `Ctrl + C` to stop the iperf3 server.


### 7. Send text messages with `nc`

Use `nc` to send plaintext messages to one another, one host can listen on port 80:

	root@bloor:~# nc -l -p 80

If `bloor` is listening, `college` can send a plaintext message with:

	root@college:~# nc bloor.local 80

You can also run a minimal webserver that can respond to HTTP messages. Look at the script `start-webserver.sh` and run it:

	root@bloor:~# cat ~/scripts/start-webserver.sh
	root@bloor:~# sh ~/scripts/start-webserver.sh

Then on `college`:

	root@college:~# curl bloor.local

Observe the response from the webserver. When you are ready to move on, hit `Ctrl + C` to stop the server.


### 8. Make wired ethernet link and assign route with `ip`

Connect an ethernet cable between `bloor` and `college`, run `networkctl` on each node and observe that `eth0` now shows up as `degraded`:

	root@bloor:~# networkctl
	IDX LINK             TYPE               OPERATIONAL SETUP
	  1 lo               loopback           carrier     unmanaged
	  2 eth0             ether              degraded    configuring

That's because it has no IP address assigned to it, so we need to manually assign `192.168.0.1` to the interface and tell `bloor` to route all `192.168.0.0/24` subnet traffic through it:

	root@bloor:~# ip addr add 192.168.0.1/24 dev eth0

Now you may list your routes with `ip route` and see the new static route:

	root@bloor:~# ip route
	default dev wlan0 proto static scope link metric 2048
	10.0.0.0/24 dev wlan1 proto kernel scope link src 10.0.0.1
	10.0.1.0/24 dev wlan0 proto kernel scope link src 10.0.1.3
	169.254.0.0/16 dev wlan0 proto kernel scope link src 169.254.227.187
	172.17.0.0/16 dev docker0 proto kernel scope link src 172.17.0.1 linkdown
	192.168.0.0/24 dev eth0 proto kernel scope link src 192.168.0.1

You will now see `networkctl` show it as `routable`. Now assign `192.168.0.2/24` to the `eth0` interface on `college` and ping `bloor`:

	root@college:~# ip addr add 192.168.0.2/24 dev eth0
	root@college:~# ping 192.168.0.1

Now you can iperf3 across the new wired link and observe close to 100 Mbps bandwidth because the Raspberry Pi 3 supports a 10/100 Mbps ethernet interface.


### 9. Mesh three nodes using cjdns and yggdrasil

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


### 10. Run applications with `docker`

The system image has `docker-ce` pre-installed, so you just need to prepare a tar archive of a docker image you need, then you can `load` and `run` the docker image without Internet access.

It is not a concern that we will run out of ramdisk space, because 6 GB of the SD card is used to back the in-memory filesystem:

	root@bloor:~# df -t rootfs -h
	Filesystem      Size  Used Avail Use% Mounted on
	rootfs          5.8G  350M  5.4G   6% /

See? We have plenty of space. The backing partition is mounted as swap memory so state is not retained after power cycle.


#### Prepare docker image archive

We first need to find a `Dockerfile` that supports our `arm32v7` architecture. Although loading and running the docker images do not require Internet, this one-time step of preparing a docker image archive requires your node to have Internet connectivity.

In this example, we will run [ipfs](https://github.com/ipfs/go-ipfs) using the [Dockerfile from vanmesh/p2p-apps-dockers](https://github.com/vanmesh/p2p-apps-dockers/blob/master/go-ipfs/Dockerfile):

	root@christie:~# docker build -t tomeshnet/ipfs:0.1 https://raw.githubusercontent.com/vanmesh/p2p-apps-dockers/master/go-ipfs/Dockerfile
	root@christie:~# docker save --output tomeshnet-ipfs-0.1.tar tomeshnet/ipfs:0.1

Now we have a tar archive of the docker image called `tomeshnet-ipfs-0.1.tar`. Copy the docker image archive to your computer, then put it in `conf.d/docker/` on the SD card root of each node you are preparing. For example, on Mac OS:

	$ mkdir /Volumes/BOOT/conf.d/home/docker
	$ cp tomeshnet-ipfs-0.1.tar /Volumes/BOOT/conf.d/home/docker/

This `docker` folder will be copied to the user home when the node starts.


#### Load and run docker image

If the node with hostname `bloor` is set up such that `conf.d/docker/` contains `tomeshnet-ipfs-0.1.tar`, you can do this upon boot to load and run the `tomeshnet/ipfs:0.1` docker image without the need for Internet access:

	root@bloor:~# docker load --input ~/docker/tomeshnet-ipfs-0.1.tar
	root@bloor:~# docker run --name ipfs --network host --detach tomeshnet/ipfs:0.1

This is only one example of an application you can run in a docker container. You can follow similar steps to prepare another appication and load them on all your nodes.


#### Share content with the ipfs docker container

After starting the `ipfs` docker container in detached mode, you can find information about it with `docker ps` and `docker inspect ipfs`. Now start a user session in the container:

	root@bloor:~# docker exec -it ipfs sh

From the session, you can interact with the ipfs node. For example, create a text file with the text _Hello World_ and add that to the ipfs node, then read it back by finding the content by its `<ipfs-content-hash>`:

	/ # echo Hello World | ipfs add
	/ # ipfs cat QmWATWQ7fVPP2EFGu71UkfnqhYXDYH566qy47CnJDgvs8u

The container runs an ipfs-to-http gateway that can be accessed from clients connected to the Access Point of the Raspberry Pi. You can use a URL formatted like this to access ipfs content from the client browser:

	http://<hostname>.local:8080/ipfs/<ipfs-content-hash>

For example, http://bloor.local:8080/ipfs/QmWATWQ7fVPP2EFGu71UkfnqhYXDYH566qy47CnJDgvs8u fetches the _Hello World_ text.

Now if you want to share content with other nodes, your ipfs node needs to be peered with other ipfs nodes to form an ipfs network. To do that, find out your ipfs node addresses on the mesh network:

	/ # ipfs id
	{
	        "ID": "QmXLWSa1AbLJfivfT9dQJdvs6AsdMkjZjjBMv5SVtimVBq",
	        "PublicKey": "CAASpgIwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQC6iZpl77PGvs2IImHtwmUxlJBKsDWcTFiNP1JfOep8l3MjnBkdhr/IPjjCv0xREodA11GHrL4xsq4SyPI0waR2V9/GVb8TQZQ9GkcujciSogAyJ23FcZrf06fo2pk2RvtSdJM0ox7ejLNBp2zTU3A1bgvLMipue0TKBwoZqfsyzXtA9se+9j+rXorDNGxHsQh+++XlQd082MBjXKtVH1qNoDZLrPzXIFLdB0jgBv1zkaUDvh+kFYnHORCKnkuBVhryo84zKzxBlA8WVSeILb4j71tvo2FBxIBEb0tr1cjE7DdrA/92lnwMgC4yfyXJMBwqTcXwPPybHMXwfViP27cvAgMBAAE=",
	        "Addresses": [
	                "/ip4/127.0.0.1/tcp/4001/ipfs/QmXLWSa1AbLJfivfT9dQJdvs6AsdMkjZjjBMv5SVtimVBq",
	                "/ip4/10.0.0.1/tcp/4001/ipfs/QmXLWSa1AbLJfivfT9dQJdvs6AsdMkjZjjBMv5SVtimVBq",
	                "/ip4/169.254.247.160/tcp/4001/ipfs/QmXLWSa1AbLJfivfT9dQJdvs6AsdMkjZjjBMv5SVtimVBq",
	                "/ip4/10.0.1.3/tcp/4001/ipfs/QmXLWSa1AbLJfivfT9dQJdvs6AsdMkjZjjBMv5SVtimVBq",
	                "/ip4/172.17.0.1/tcp/4001/ipfs/QmXLWSa1AbLJfivfT9dQJdvs6AsdMkjZjjBMv5SVtimVBq",
	                "/ip6/::1/tcp/4001/ipfs/QmXLWSa1AbLJfivfT9dQJdvs6AsdMkjZjjBMv5SVtimVBq",
	                "/ip6/fd00:338a:9ae7:1947:8a2b:7ea3:5c2d:f737/tcp/4001/ipfs/QmXLWSa1AbLJfivfT9dQJdvs6AsdMkjZjjBMv5SVtimVBq",
	                "/ip6/fcb0:3f14:ebc8:1f7b:a1ce:bd44:a410:5049/tcp/4001/ipfs/QmXLWSa1AbLJfivfT9dQJdvs6AsdMkjZjjBMv5SVtimVBq"
	        ],
	        "AgentVersion": "go-ipfs/0.4.13/cc01b7f18",
	        "ProtocolVersion": "ipfs/0.1.0"
	}

Note the cjdns `/ip6/fc00::/8` and yggdrasil `/ip6/fd00::/8` addresses and share them with another node (e.g. `college`) so it can add you as a bootstrap peer from its docker user session:

	/ # ipfs bootstrap add /ip6/fcb0:3f14:ebc8:1f7b:a1ce:bd44:a410:5049/tcp/4001/ipfs/QmXLWSa1AbLJfivfT9dQJdvs6AsdMkjZjjBMv5SVtimVBq

Notice that the ipfs node address is in the format `/ip6/<mesh-node-ip-address>/tcp/4001/ipfs/<ipfs-node-id>`. Now an ipfs network is formed between `bloor` and `college`. Try publishing content on one node and fetching it from another.

To recap in this example, we started an ipfs daemon and ipfs-to-http gateway in a docker container, then peered two nodes to create an ipfs content-addressing network. Each mesh node is now also an ipfs node that publishes and fetches content within our local mesh network. Through the http gateway, devices connected to the Raspberry Pi's Access Point can use a browser to fetch content published by any node that has at least one peer in this ipfs network.

