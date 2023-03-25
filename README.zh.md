# bittorrent-NAT-hole-punching
 NAT 自动打洞脚本用于 uTorrent/qBittorrent
# 脚本说明
- NAT Full Cone (NAT1) NAT全锥形网络允许打开的端口接收来自任意IP的访问数据，保持该端口开放，
  并报告 Tracker 让其他用户从该端口访问，可使原本处于NAT内网环境下的 BT 客户端获得近似公网环境的连接性。
   
  打洞软件打通的端口是随机的，所以 BT 客户端要让其他用户能访问到就需要变更端口与该端口一致
   
  当端口打开后，通知 BT 客户端设置端口，添加路由转发规则就是这个脚本所做的事情
   
# 要求
- 确保路由器已安装命令 `iptables` `curl`

  在 OpenWrt 可按以下命令安装：
  ```
  opkg update
  opkg install iptables
  opkg install curl
  ```
- 在你的 BT 客户端上启用 Web UI
- 注意 uTorrent（2.2.1以前）默认未安装 WebUI

  可在本仓库下载 [webui.zip](/webui.zip) 置于 uTorrent 根目录下以启用（不用解压）
  
# 使用方法
1. 下载 [natmap](https://github.com/heiher/natmap) / [Natter](https://github.com/MikeWang000000/Natter) (0.9版以上)

2. 下载 `update-ut.sh` (用于 uTorrrent) 或 `update-qb.sh` (用于 qBittorrent)
   
   如果使用Natter，下载文件夹[Natter](/Natter)内的对应脚本

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
   set_announce_ip=0      # 是否设置 报告给tracker的公网IP，1表示 是，其他值 否
   ```
4. 保存以上文件到路由器上，并添加脚本'执行'权限: `chmod +x /root/app/ut/update-ut.sh`

5. 运行命令，例如, `/root/app/natmap -d -s stunserver.stunprotocol.org -h qq.com -b 3333 -e /root/app/ut/update-ut.sh`
   ```
   /root/app/natmap            natmap 路径
   -d                          以 daemon 模式运行
   -b 3333                     绑定的端口，任意在 1024-65535 之间的端口都可以
   /root/app/ut/update-ut.sh   脚本路径
   ```
   命令细节请查看 [natmap](https://github.com/heiher/natmap) / [Natter](https://github.com/MikeWang000000/Natter) (0.9版以上)

## 让脚本自动运行
- 编辑 `/etc/rc.local`, 比如
  ```
  sleep 60
  /root/app/natmap -d -s stunserver.stunprotocol.org -h qq.com -b 3333 -e /root/app/ut/update-ut.sh
  exit 0
  ```
  以上命令会使路由器启动完毕后，自动运行 natmap

## 可能遇到的问题
- 本地编辑好的脚本文件怎么传到路由器上？

  - 使用`scp`命令上传 （安装 [Putty](https://www.putty.org) 后，在Windows命令行使用）， 比如
    ```
    scp  d:\temp\natmap root@192.168.0.1:/root/app/qb/natmap
    ```
    其中`192.168.0.1` 为路由器IP。命令上传 `d:\temp\natmap` 到 `/root/app/qb/natmap`
  
  - 或在本地建一个文件服务器，比如使用 [caddy](https://caddyserver.com/download)，下载后，打开cmd，运行
    ```
    caddy.exe file-server --browse --root D:\Downloads
    ```
    其中 `D:\Downloads` 即允许在网页上访问的目录，在浏览器上打开 127.0.0.1 可访问（可改为局域网地址访问，比如192.168.0.74）
  
    将`update-qb.sh`放在`D:\Downloads`内，在路由器上，运行以下命令即可下载到路由器上
    ```
    curl http://192.268.0.74/update-qb.sh --output update-qb.sh
    ```
  
- 不定期运行 BT 客户端，脚本也能正常工作吗？

  可以。脚本每2分钟检查一次 BT 客户端是否在线，若在，设置端口并停止检查（下次变更端口会再次重复这个过程）
  
- 如何确认开放端口成功？
  - uTorrent 的话比较简单 ： 
    在浏览器上访问 公网IP:端口， 比如 111.222.2.2:13455， 网页显示 `invalid request` 即表示端口打开成功
  - 在 BT 客户端上，选择1个正在上传或下载的种子，查看用户列表，若`标志`(Flags) 列里有 `I` (Incoming) 标志的用户，这表明该用户主动发起连接并经过你的开放端口。 
    注意一些通过 DHT 交换或你发起的连接，没有 `I` 标志
    
# 参考
  - [Natter](https://github.com/MikeWang000000/Natter)
  - [natmap](https://github.com/heiher/natmap)
  - [qBittorrent-NAT-TCP-Hole-Punching](https://github.com/Mythologyli/qBittorrent-NAT-TCP-Hole-Punching)
  - [uTorrent Web UI API](https://github.com/bittorrent/webui/wiki/Web-UI-API)
  - [qBittorrent Web UI API](https://github.com/qbittorrent/qBittorrent/wiki/WebUI-API-(qBittorrent-4.1))
