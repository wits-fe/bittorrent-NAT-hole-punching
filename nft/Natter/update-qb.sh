#!/bin/sh

script=$(readlink -f "$0")
script_dir=$(dirname "$script")

# Natter
protocol=$1
inner_ip=$2
private_port=$3
public_addr=$4
public_port=$5

port=$public_port

echo 
echo "External IP - $public_addr:$public_port, bind port $private_port, $protocol"
echo 

# qBittorrent

interface="ppp*"
host="192.168.0.74"
web_port="5555"
username="admin"
password="12345"
set_announce_ip=0
forward_ipv6=0
dnat_accept=1
nft_snippet=1

# script begins

retry_interval=57
retry_times=2880

rsf="$script_dir/qbs_running"
rs=0
rs_b=0
wait_to_exit=$(($retry_interval + 30))

if [ -f "$rsf" ]; then
  rs=$(cat "$rsf")
  if ! [ "$rs" -ge 0 ]; then
    if ! [[ $(wc -c <"$rsf") -le 4 ]]; then
      echo "$rsf : unexpected value"
      echo "An error occurred."
      echo "Place this script on other folder to suppress the error."
      exit 99
    fi
    rs=0
  fi

  rs=$(($rs + 1))
  echo "$rs" >"$rsf"
  sleep $wait_to_exit

  if ! [ -f "$rsf" ]; then
    exit 100
  fi

  rs_b=$(cat "$rsf")
  if ! [ "$rs" = "$rs_b" ]; then
    exit 200
  fi

  echo "0" >"$rsf"
else
  echo "0" >"$rsf"
fi

x=1
qb_cookie=nul

# If bittorrent client isn't online, try 57 seconds later.
# ( Loop last 48 hours unless this script is invoked again or app is online. )
while [ $x -le $retry_times ]; do
  if ! [ -f "$rsf" ]; then
    exit 101
  fi

  rs=$(cat "$rsf")
  if ! [ "$rs" = "0" ]; then
    echo "Another running script detected, exit."
    exit 102
  fi

  qb_cookie=$(curl -m 3 -s -i --data "username=$username&password=$password" http://$host:$web_port/api/v2/auth/login | grep -i set-cookie | cut -c13-48)
  if [[ $(expr match "$qb_cookie" '.\+=') -gt 3 ]]; then
    echo "Update qBittorrent listen port to $public_port"
    if [ $set_announce_ip -eq 1 ]; then
      curl -m 3 -s -X POST -b "$qb_cookie" -d 'json={"listen_port":"'$port'","announce_ip":"'$public_addr'"}' "http://$host:$web_port/api/v2/app/setPreferences" &>/dev/null
      if [ $? != '0' ]; then
        sleep 5
        echo "Retrying.."
        curl -m 3 -s -X POST -b "$qb_cookie" -d 'json={"listen_port":"'$port'","announce_ip":"'$public_addr'"}' "http://$host:$web_port/api/v2/app/setPreferences" &>/dev/null
      fi
    else
      curl -m 3 -s -X POST -b "$qb_cookie" -d 'json={"listen_port":"'$port'"}' "http://$host:$web_port/api/v2/app/setPreferences" &>/dev/null
      if [ $? != '0' ]; then
        sleep 5
        echo "Retrying.."
        curl -m 3 -s -X POST -b "$qb_cookie" -d 'json={"listen_port":"'$port'"}' "http://$host:$web_port/api/v2/app/setPreferences" &>/dev/null
      fi
    fi
    break
  fi

  x=$(($x + 1))
  sleep $retry_interval
done

if ! [ $x -le $retry_times ]; then
  exit 103
fi

# nft
nft add chain inet fw4 qb_dstnat
nft flush chain inet fw4 qb_dstnat
if ! nft list chain inet fw4 dstnat | grep -q 'jump qb_dstnat' > /dev/null; then
  nft add rule inet fw4 dstnat jump qb_dstnat
fi
nft add rule inet fw4 qb_dstnat iifname $interface $protocol dport $private_port counter dnat ip to $host:$port
n_rule1="add rule inet fw4 qb_dstnat iifname $interface $protocol dport $private_port counter dnat ip to $host:$port"

n_rule2=""
n_rule3=""
n_rule4=""
if [ $forward_ipv6 -eq 1 ]; then
  nft add chain inet fw4 qb_forward_wan
  nft flush chain inet fw4 qb_forward_wan
  if ! nft list chain inet fw4 forward_wan | grep -q 'jump qb_forward_wan' > /dev/null; then
    nft insert rule inet fw4 forward_wan jump qb_forward_wan
  fi
  nft add rule inet fw4 qb_forward_wan iifname $interface meta nfproto ipv6 tcp dport $port counter accept
  nft add rule inet fw4 qb_forward_wan iifname $interface meta nfproto ipv6 udp dport $port counter accept
  n_rule2="insert rule inet fw4 forward_wan jump qb_forward_wan"
  n_rule3="add rule inet fw4 qb_forward_wan iifname $interface meta nfproto ipv6 tcp dport $port counter accept"
  n_rule4="add rule inet fw4 qb_forward_wan iifname $interface meta nfproto ipv6 udp dport $port counter accept"
fi

n_rule5=""
if [ $dnat_accept -eq 1 ]; then
  n_rule5="insert rule inet fw4 forward_wan ct status dnat counter accept"
  if ! nft list chain inet fw4 forward_wan | grep 'ct status dnat' | grep -q 'accept' > /dev/null; then
    nft insert rule inet fw4 forward_wan ct status dnat counter accept
  fi
fi

if [ $nft_snippet -eq 1 ] && [ -d /usr/share/nftables.d/ruleset-post ]; then
  echo "
add chain inet fw4 qb_dstnat
flush chain inet fw4 qb_dstnat
add rule inet fw4 dstnat jump qb_dstnat
$n_rule1
add chain inet fw4 qb_forward_wan
flush chain inet fw4 qb_forward_wan
$n_rule2
$n_rule3
$n_rule4
$n_rule5
  " > /usr/share/nftables.d/ruleset-post/qb_forward_wan.nft
fi

rm -f "$rsf"
echo Fin
exit 0
