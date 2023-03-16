# bittorrent-NAT-hole-punching
 NAT hole punching, script for uTorrent/qBittorrent
 
 [中文](/README.zh.md)
 
# Description
 - Full Cone NAT (NAT1) allows the open port to receive data from any IP, keep a port open, then report it to the tracker, send/receive data with that port,
   which will make BT clients that are behind the NAT open to public.

   Because the port opened by the hole punching software is random, 
   the BT client needs to change the port to match it so that other users can connect to.

   That informing the BT client to set the random-opened port, adding route-forwarding rules is what this script does.

# Usage
1. Download [natmap](https://github.com/heiher/natmap)

2. Download `update-ut.sh` (for uTorrrent) / `update-qb.sh` (for qBittorrent)

3. Edit the following fields with your need:
   - update-ut.sh (uTrorrent)
   ```
   # utorrent

   interface="pppoe-wan"  # wan interface where port bind to, leave this field empty if doubt
   host="192.168.0.74"    # host where your bittorrent client is running on
   web_port="4444"        # WebUI port
   username="admin"       # WebUI user
   password="123456"      # WebUI password
   set_tracker_ip=1       # whether set external ip (report to tracker) or not, 1 for true, otherwise false
   ```
   
   - update-qb.sh (qBittorrent)
   ```
   # qBittorrent

   interface="pppoe-wan"  # wan interface where port bind to, leave this field empty if doubt
   host="192.168.0.74"    # host where your bittorrent client is running on
   web_port="5555"        # WebUI port
   username="admin"       # WebUI user
   password="123456"      # WebUI password
   ```
4. Save above files to your router device and give script excute permission: `chmod +x /root/app/ut/update-ut.sh`
5. Run command, for example, `/root/app/natmap -d -s stunserver.stunprotocol.org -h qq.com -b 3333 -e /root/app/ut/update-ut.sh`
   ```
   /root/app/natmap            path of natmap
   -d                          run as deamon
   -b 3333                     bind port, any port from 1024-65535 is ok
   /root/app/ut/update-ut.sh   path of script
   ```
   more details see [natmap](https://github.com/heiher/natmap)
## Startup 
- Edit `/etc/rc.local`, for example
  ```
  sleep 60
  /root/app/natmap -d -s stunserver.stunprotocol.org -h qq.com -b 3333 -e /root/app/ut/update-ut.sh
  exit 0
  ```
  That will make program always run on startup
# Reference
  - [qBittorrent-NAT-TCP-Hole-Punching](https://github.com/Mythologyli/qBittorrent-NAT-TCP-Hole-Punching)
  - [Natter](https://github.com/MikeWang000000/Natter)
  - [natmap](https://github.com/heiher/natmap)
