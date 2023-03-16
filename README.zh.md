# bittorrent-NAT-hole-punching
 NAT 自动打洞脚本用于 uTorrent/qBittorrent
# 原理
 - NAT Full Cone (NAT1) NAT全锥形网络允许打开的端口接收来自任意IP的访问数据，保持该端口开放，
   并通知 Tracker 从该端口访问，可使原本处于NAT内网环境下的 BT 软件获得接近公网环境的连接性

# 使用方法
1. 下载 [natmap](https://github.com/heiher/natmap)

2. 下载 `update-ut.sh` (用于 uTorrrent) 或 `update-qb.sh` (用于 qBittorrent)

3. 根据你的情况编辑以下项:
   - update-ut.sh (uTrorrent)
   ```
   # utorrent

   interface="pppoe-wan"  # 端口绑定的 interface，若不知道这是什么请留空
   host="192.168.0.74"    # 你的 uTrorrent 运行的主机地址
   web_port="4444"        # uTrorrent WebUI 端口
   username="admin"       # WebUI 用户名
   password="123456"      # WebUI 密码
   set_tracker_ip=1       # 是否设置 报告给tracker的公网IP，1表示 是，其他值 否
   ```
   
   - update-qb.sh (qBittorrent)
   ```
   # qBittorrent

   interface="pppoe-wan"  # 端口绑定的 interface，若不知道这是什么请留空
   host="192.168.0.74"    # 你的 qBittorrent 运行的主机地址
   web_port="5555"        # qBittorrent WebUI 端口
   username="admin"       # WebUI 用户名
   password="123456"      # WebUI 密码
   ```
4. 保存以上文件到路由器上，并添加脚本'执行'权限: `chmod +x /root/app/ut/update-ut.sh`
5. 运行命令，例如, `/root/app/natmap -d -s stunserver.stunprotocol.org -h qq.com -b 3333 -e /root/app/ut/update-ut.sh`
   ```
   /root/app/natmap            natmap 路径
   -d                          以 deamon 模式运行
   -b 3333                     绑定的端口，任意在 1024-65535 之间的端口都可以
   /root/app/ut/update-ut.sh   脚本路径
   ```
   细节请查看 [natmap](https://github.com/heiher/natmap)
## 让脚本自动运行
- 编辑 `/etc/rc.local`, 比如
  ```
  sleep 60
  /root/app/natmap -d -s stunserver.stunprotocol.org -h qq.com -b 3333 -e /root/app/ut/update-ut.sh
  exit 0
  ```
  以上命令会使路由器启动完毕后，自动运行 natmap


# 其他注意事项
- 确保路由器已安装命令 `iptables` `curl`

  在 OpenWrt 可按以下命令安装：
  ```
  opkg update
  opkg install iptables
  opkg install curl
  ```
- 本地编辑好的脚本文件怎么传到路由器上？

  可以先在本地建一个文件服务器，比如使用[caddy](https://caddyserver.com/download)，下载后，打开cmd，运行
  ```
  caddy.exe file-server --browse --root D:\Downloads
  ```
  其中 `D:\Downloads` 即允许在网页上访问的目录，在浏览器上打开 127.0.0.1 可访问（可改为局域网地址访问，比如192.168.0.74）
  
  将`update-qb.sh`放在`D:\Downloads`内，在路由器上，运行以下命令即可下载到路由器上
  ```
  curl http://192.268.0.74/update-qb.sh --output update-qb.sh
  ```
- uTorrent（2.2.1以前）的 WebUI 无法访问，因为默认没安装

  可在本仓库下载 [webui.zip](/webui.zip) 置于 uTorrent 根目录下以启用

# 参考
  - https://github.com/Mythologyli/qBittorrent-NAT-TCP-Hole-Punching
  - https://github.com/MikeWang000000/Natter
  - https://github.com/heiher/natmap
