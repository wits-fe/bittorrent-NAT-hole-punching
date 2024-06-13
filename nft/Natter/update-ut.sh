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

# uTorrent

interface="ppp*"
host="192.168.0.74"
web_port="4444"
username="admin"
password="12345"
set_tracker_ip=1
forward_ipv6=1
dnat_accept=1
nft_snippet=1

# script begins

retry_interval=57
retry_times=2880

rsf="$script_dir/uts_running"
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
ut_token=nul

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

  ut_token=$(curl -m 3 -s -u $username:$password http://$host:$web_port/gui/token.html | grep -o '<div.*div>' | grep -o '>.*<' | sed -e 's/>\(.*\)</\1/')
  if [[ $(expr match "$ut_token" '.\+=') -gt 8 ]]; then
    echo "Update utorrent listen port to $public_port"
    if [ $set_tracker_ip -eq 1 ]; then
      curl -m 3 -s -u $username:$password "http://$host:$web_port/gui/?token=$ut_token&action=setsetting&s=bind_port&v=$port&s=tracker_ip&v=$public_addr" &>/dev/null
      if [ $? != '0' ]; then
        sleep 5
        echo "Retrying.."
        curl -m 3 -s -u $username:$password "http://$host:$web_port/gui/?token=$ut_token&action=setsetting&s=bind_port&v=$port&s=tracker_ip&v=$public_addr" &>/dev/null
      fi
    else
      curl -m 3 -s -u $username:$password "http://$host:$web_port/gui/?token=$ut_token&action=setsetting&s=bind_port&v=$port" &>/dev/null
      if [ $? != '0' ]; then
        sleep 5
        echo "Retrying.."
        curl -m 3 -s -u $username:$password "http://$host:$web_port/gui/?token=$ut_token&action=setsetting&s=bind_port&v=$port" &>/dev/null
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
nft add chain inet fw4 ut_dstnat
nft flush chain inet fw4 ut_dstnat
if ! nft list chain inet fw4 dstnat | grep -q 'jump ut_dstnat' > /dev/null; then
  nft add rule inet fw4 dstnat jump ut_dstnat
fi
nft add rule inet fw4 ut_dstnat iifname $interface $protocol dport $private_port counter dnat ip to $host:$port
n_rule1="add rule inet fw4 ut_dstnat iifname $interface $protocol dport $private_port counter dnat ip to $host:$port"

n_rule2=""
n_rule3=""
n_rule4=""
if [ $forward_ipv6 -eq 1 ]; then
  nft add chain inet fw4 ut_forward_wan
  nft flush chain inet fw4 ut_forward_wan
  if ! nft list chain inet fw4 forward_wan | grep -q 'jump ut_forward_wan' > /dev/null; then
    nft insert rule inet fw4 forward_wan jump ut_forward_wan
  fi
  nft add rule inet fw4 ut_forward_wan iifname $interface meta nfproto ipv6 tcp dport $port counter accept
  nft add rule inet fw4 ut_forward_wan iifname $interface meta nfproto ipv6 udp dport $port counter accept
  n_rule2="insert rule inet fw4 forward_wan jump ut_forward_wan"
  n_rule3="add rule inet fw4 ut_forward_wan iifname $interface meta nfproto ipv6 tcp dport $port counter accept"
  n_rule4="add rule inet fw4 ut_forward_wan iifname $interface meta nfproto ipv6 udp dport $port counter accept"
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
add chain inet fw4 ut_dstnat
flush chain inet fw4 ut_dstnat
add rule inet fw4 dstnat jump ut_dstnat
$n_rule1
add chain inet fw4 ut_forward_wan
flush chain inet fw4 ut_forward_wan
$n_rule2
$n_rule3
$n_rule4
$n_rule5
  " > /usr/share/nftables.d/ruleset-post/ut_forward_wan.nft
fi

rm -f "$rsf"
echo Fin
exit 0
