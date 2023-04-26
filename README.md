# bittorrent-NAT-hole-punching
 NAT hole punching, script for uTorrent/qBittorrent
 
 [中文](/README.zh.md)
 
# Description
 - Full Cone NAT (NAT1) allows the open port to receive data from any IP, keep the port open, then report it to the tracker, send/receive data with that port,
   which makes BT clients that are behind the NAT open to public.

   Because the port opened by the hole punching software is random, 
   the BT client needs to change the listen port to match it so that other users can connect to.

   Once open port is established, this script will inform the BT client to set the listen port then add route-forwarding rules.

# Prerequisites
 - Make sure that `iptables` `curl` is installed on your system
 
   On OpenWrt you can use following command to install：
   ```
   opkg update
   opkg install iptables
   opkg install curl
   ```
 - Enable Web UI on your BT client

 - Note that WebUI isn't installed by default on uTorrent (before 2.2.1)
   
   To install:  Download [webui.zip](/webui.zip) from this repo, put it into the root path of uTorrent. (no need to unzip)
   
# Usage
1. Download [natmap](https://github.com/heiher/natmap) / [Natter](https://github.com/MikeWang000000/Natter)(ver 0.9 above)

2. Download `update-ut.sh` (for uTorrrent) / `update-qb.sh` (for qBittorrent)
   
   Or download the ones in the folder [Natter](/Natter) if you use Natter.
   
3. Edit the following fields with your need:
   - update-ut.sh (uTrorrent)
   ```
   # utorrent

   interface="pppoe-wan"  # wan interface where port bind to, leave this field untouch if doubt
   host="192.168.0.74"    # host where your bittorrent client is running on
   web_port="4444"        # WebUI port
   username="admin"       # WebUI user
   password="123456"      # WebUI password
   set_tracker_ip=1       # whether set external ip (report to tracker) or not, 1 for true, otherwise false
   forward_ipv6=1         # open port on IPv6, 1 : enable
   ```
   
   - update-qb.sh (qBittorrent)
   ```
   # qBittorrent

   interface="pppoe-wan"  # wan interface where port bind to, leave this field untouch if doubt
   host="192.168.0.74"    # host where your bittorrent client is running on
   web_port="5555"        # WebUI port
   username="admin"       # WebUI user
   password="123456"      # WebUI password
   set_announce_ip=0      # whether set external ip or not, 1 for true, otherwise false
   forward_ipv6=0         # open port on IPv6, 0 : disable
   ```
4. Save above files to your router device and give script excute permission: `chmod +x /root/app/ut/update-ut.sh`
5. Run command, for example, `/root/app/natmap -d -s stunserver.stunprotocol.org -h qq.com -b 3333 -e /root/app/ut/update-ut.sh`
   ```
   /root/app/natmap            path of natmap
   -d                          run as daemon
   -b 3333                     bind port, any port from 1024-65535 is ok
   /root/app/ut/update-ut.sh   path of script
   ```
   more details see [natmap](https://github.com/heiher/natmap) / [Natter](https://github.com/MikeWang000000/Natter)(ver 0.9 above)

## Startup 
- Edit `/etc/rc.local`, for example
  ```
  sleep 60
  /root/app/natmap -d -s stunserver.stunprotocol.org -h qq.com -b 3333 -e /root/app/ut/update-ut.sh
  exit 0
  ```
  That will make program always run on startup

# Reference
  - [Natter](https://github.com/MikeWang000000/Natter)
  - [natmap](https://github.com/heiher/natmap)
  - [qBittorrent-NAT-TCP-Hole-Punching](https://github.com/Mythologyli/qBittorrent-NAT-TCP-Hole-Punching)
  - [uTorrent Web UI API](https://github.com/bittorrent/webui/wiki/Web-UI-API)
  - [qBittorrent Web UI API](https://github.com/qbittorrent/qBittorrent/wiki/WebUI-API-(qBittorrent-4.1))
